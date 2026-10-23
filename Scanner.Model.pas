unit Scanner.Model;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Winapi.Windows;

type
  TVolumeSpace = record
    Path: string;
    Capacity, FreeSpace: UInt64;
  end;

  TDiskNode = class
  private
    FPathPart: string;
    FParent: TDiskNode;
    FIsFolder: Boolean;
    function GetPath: string;
    procedure SetParent(Value: TDiskNode);
    procedure SetIsFolder(Value: Boolean);
  public
    Name: string;
    Children: TObjectList<TDiskNode>;
    Size, LogicalSize, Files, Capacity, FreeSpace: UInt64;
    IsVolume, IsFree, IsUsed, Hidden, Unreadable: Boolean;
    UsedArea, FreeArea: TDiskNode;
    property Path: string read GetPath;
    property Parent: TDiskNode read FParent write SetParent;
    property IsFolder: Boolean read FIsFolder write SetIsFolder;
    function DisplayBytes: UInt64;
    constructor Create(const APath, AName: string; AParent: TDiskNode = nil; AIsFolder: Boolean = True);
    destructor Destroy; override;
    function ParentFolder: TDiskNode;
    procedure Recalculate;
    procedure ApplyVolumeSpace(Total, FreeBytes: UInt64);
  end;

  TNodeValues = record
    Size, LogicalSize, Files, Capacity, FreeSpace: UInt64;
    Unreadable: Boolean;
    procedure Apply(Node: TDiskNode);
    function Matches(Node: TDiskNode): Boolean;
  end;

  // A rescan borrows one scan root of the displayed tree read-only. Changes
  // become visible only when the UI thread calls TakeRoot; cancellation
  // discards this journal.
  TScanChange = class
    Node: TDiskNode;
    Name: string;
    Values: TNodeValues;
    Children: TObjectList<TDiskNode>;
    destructor Destroy; override;
  end;

  TScanThread = class(TThread)
  private
    FRoot, FSourceRoot: TDiskNode;
    FCreatedNodes: TObjectList<TDiskNode>;
    FChanges: TObjectList<TScanChange>;
    FPaths: TArray<string>;
    FRefreshVolumes: TArray<string>;
    FVolumeSpaces: TArray<TVolumeSpace>;
    FTotalFiles: UInt64;
    FProcessedBytes, FExpectedBytes: UInt64;
    FCounting: Boolean;
    FLock: TCriticalSection;
    FCurrent, FError: string;
    FVisited: UInt64;
    FSkipped: Integer;
    FDone: Integer;
    FStartRequested: Boolean;
    // Directories being read, from the scan root down; FSpine[Depth] is the
    // one at that depth. Only the worker touches it.
    FSpine: TList<TDiskNode>;
    FPreviewWanted: Integer;
    FPreview: TDiskNode;
    FPreviewTime: Int64;
    FPreviewFocus: string;
    function InSpine(Node: TDiskNode; Depth: Integer): Boolean;
    function SpineValues(Node: TDiskNode; Depth: Integer): TNodeValues;
    function CopyNode(Node: TDiskNode; Depth: Integer; Parent: TDiskNode): TDiskNode;
    procedure CopyChildren(Source, Target: TDiskNode; Depth, Level: Integer; Threshold: UInt64; All: Boolean);
    function PreviewOf(const FocusPath: string): TDiskNode;
    procedure PublishPreview;
    function NewNode(const Path, Name: string; Parent: TDiskNode; IsFolder: Boolean): TDiskNode;
    function FindSource(const Path: string): TDiskNode;
    procedure StageNode(Node: TDiskNode; const Name: string; const Values: TNodeValues; Children: TObjectList<TDiskNode>; Existing: Boolean);
    procedure CommitChanges;
    procedure DiscardResult;
    procedure PrepareProgress;
    function ScanDirectory(Node: TDiskNode; const DirectoryPath: string; Cluster: UInt64; Depth: Integer; Existing: Boolean): TNodeValues;
    function ScanVolume(Node: TDiskNode; Existing: Boolean): TNodeValues;
  protected
    procedure Execute; override;
  public
    constructor Create(const Paths: TArray<string>; const RefreshVolumes: TArray<string> = nil; SourceRoot: TDiskNode = nil);
    destructor Destroy; override;
    procedure Start; reintroduce;
    property StartRequested: Boolean read FStartRequested;
    function TakeRoot: TDiskNode;
    procedure RequestCancel;
    procedure Progress(out Current: string; out Visited: UInt64; out Skipped: Integer); overload;
    procedure Progress(out Current: string; out Visited: UInt64; out Skipped: Integer; out Total: UInt64; out Counting: Boolean); overload;
    property VolumeSpaces: TArray<TVolumeSpace> read FVolumeSpaces;
    procedure ProgressBytes(out Processed, Expected: UInt64);
    function ProgressPosition: Integer;
    function Done: Boolean;
    // Asks a fresh scan for a copy of what a view of FocusPath can show of
    // its tree so far ('' for the scan root); rescans ignore it.
    procedure RequestPreview(const FocusPath: string);
    // The latest copy, or nil, and the milliseconds it took to build. The
    // caller owns the copy.
    function TakePreview(out BuildTime: Int64): TDiskNode;
    property Error: string read FError;
    // The borrowed root of a rescan; nil for a fresh scan.
    property SourceRoot: TDiskNode read FSourceRoot;
  end;

  // A request to scan Path within the scan root RootPath. A started worker
  // borrows only that root's subtree, so finished jobs can be merged on the UI
  // thread while workers for other roots keep reading.
  TScanJob = class
  private
    FRootPath, FPath, FLane: string;
    FWorker: TScanThread;
  public
    // Used bytes of a queued drive, so progress has a weight before it starts.
    Expected: UInt64;
    // Tick count of the last preview request, and the milliseconds the last
    // preview took to build and show.
    PreviewTick: UInt64;
    PreviewCost: Int64;
    constructor Create(const RootPath, Path, Lane: string);
    destructor Destroy; override;
    property RootPath: string read FRootPath;
    property Path: string read FPath;
    // Jobs sharing a lane (a physical device) never read at the same time.
    // Only a queued job may move to another lane.
    property Lane: string read FLane write FLane;
    property Worker: TScanThread read FWorker;
  end;

  // Owns the scan jobs: at most one per scan root, started in request order
  // with one reader per lane. Used only from the UI thread.
  TScanScheduler = class
  private
    FJobs, FRetired: TObjectList<TScanJob>;
    function LaneBusy(const Lane: string): Boolean;
    function Retiring(const RootPath: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const RootPath, Path, Lane: string): TScanJob;
    function Find(const RootPath: string): TScanJob;
    // True while a queued, running or cancelled job may still read RootPath.
    function Borrows(const RootPath: string): Boolean;
    function LaneHolder(const Lane: string): TScanJob;
    function Jobs: TArray<TScanJob>;
    function Idle: Boolean;
    procedure Cancel(Job: TScanJob);
    procedure StartReady(const CreateWorker: TFunc<TScanJob, TScanThread>);
    // Removes and returns a completed job for the caller to merge and free.
    function TakeFinished: TScanJob;
    procedure Reap;
  end;

function SamePath(const A, B: string): Boolean;

function PathWithin(const Path, Root: string): Boolean;

function DisplaySize(Value: UInt64): string; overload;

function DisplaySize(Value, Reference: UInt64): string; overload;

function LongPath(const Path: string): string;

function AvailableDrives: TArray<string>;

// The physical disk number behind a volume such as 'C:\', or -1 when Windows
// cannot tell (network shares, SUBST drives). A spanned volume reports its
// lowest disk.
function VolumeDisk(const Drive: string): Integer;

// Whether a physical disk has a seek penalty, i.e. is a spinning disk. Disks
// that do not answer (some USB enclosures) count as spinning.
function DiskSeeks(Disk: Integer): Boolean;

implementation

uses
  System.Math, System.Generics.Defaults, System.Diagnostics;

constructor TDiskNode.Create(const APath, AName: string; AParent: TDiskNode; AIsFolder: Boolean);
begin
  inherited Create;
  Name := AName;
  FParent := AParent;
  if (APath <> '') and (AParent <> nil) and (AParent.FPathPart <> '') then
  begin
    // Share the name string's storage for ordinary entries, including files.
    FPathPart := ExtractFileName(ExcludeTrailingPathDelimiter(APath));
    if FPathPart = Name then
      FPathPart := Name;
  end
  else
    FPathPart := APath;
  IsFolder := AIsFolder;
end;

function TDiskNode.GetPath: string;
var
  Node: TDiskNode;
  Count, Offset, PartLength: Integer;
begin
  if FPathPart = '' then
    Exit('');
  if (FParent = nil) or (FParent.FPathPart = '') then
    Exit(FPathPart);
  // Allocate once, rather than constructing a temporary string per ancestor.
  Count := 0;
  Node := Self;
  while (Node <> nil) and (Node.FPathPart <> '') do
  begin
    Inc(Count, Length(Node.FPathPart));
    if (Node.FParent <> nil) and (Node.FParent.FPathPart <> '') and
      not IsPathDelimiter(Node.FParent.FPathPart, Length(Node.FParent.FPathPart)) then
      Inc(Count);
    Node := Node.FParent;
  end;
  SetLength(Result, Count);
  Offset := Count;
  Node := Self;
  while (Node <> nil) and (Node.FPathPart <> '') do
  begin
    PartLength := Length(Node.FPathPart);
    Dec(Offset, PartLength);
    Move(PChar(Node.FPathPart)^, (PChar(Result) + Offset)^, PartLength * SizeOf(Char));
    if (Node.FParent <> nil) and (Node.FParent.FPathPart <> '') and
      not IsPathDelimiter(Node.FParent.FPathPart, Length(Node.FParent.FPathPart)) then
    begin
      Dec(Offset);
      Result[Offset + 1] := PathDelim
    end;
    Node := Node.FParent;
  end;
end;

procedure TDiskNode.SetParent(Value: TDiskNode);
begin
  if FParent = Value then
    Exit;
  if FPathPart <> '' then
    if (Value = nil) or (Value.FPathPart = '') then
      FPathPart := Path
    else if (FParent = nil) or (FParent.FPathPart = '') then
    begin
      FPathPart := ExtractFileName(ExcludeTrailingPathDelimiter(FPathPart));
      if FPathPart = Name then
        FPathPart := Name;
    end;
  FParent := Value;
end;

procedure TDiskNode.SetIsFolder(Value: Boolean);
begin
  if FIsFolder = Value then
    Exit;
  FIsFolder := Value;
  if Value then
    Children := TObjectList<TDiskNode>.Create(True)
  else
    FreeAndNil(Children);
end;

destructor TDiskNode.Destroy;
begin
  UsedArea.Free;
  FreeArea.Free;
  Children.Free;
  inherited;
end;

function TDiskNode.ParentFolder: TDiskNode;
begin
  Result := nil;
  if IsVolume or (Parent = nil) then
    Exit;
  if Parent.Path <> '' then
    Result := Parent;
end;

procedure TDiskNode.Recalculate;
var
  C: TDiskNode;
begin
  Size := 0;
  LogicalSize := 0;
  Files := 0;
  if not IsVolume then
  begin
    Capacity := 0;
    FreeSpace := 0
  end;
  if Children = nil then
    Exit;
  for C in Children do
  begin
    Inc(Size, C.Size);
    Inc(LogicalSize, C.LogicalSize);
    Inc(Files, C.Files);
    if not IsVolume then
    begin
      Inc(Capacity, C.Capacity);
      Inc(FreeSpace, C.FreeSpace)
    end;
  end;
end;

function TDiskNode.DisplayBytes: UInt64;
begin
  // The summary reports Windows capacity; a zoomed disk reports enumerated files.
  if (Path = '') and (Parent = nil) and (Capacity > 0) then
    Result := Capacity
  else
    Result := Size;
end;

procedure TDiskNode.ApplyVolumeSpace(Total, FreeBytes: UInt64);
begin
  if not IsVolume then
    Exit;
  Capacity := Total;
  FreeSpace := Min(Total, FreeBytes);
  if UsedArea = nil then
  begin
    UsedArea := TDiskNode.Create('', 'Used on ' + Path, Self, False);
    UsedArea.IsFolder := False;
    UsedArea.IsUsed := True;
    FreeArea := TDiskNode.Create('', 'Free on ' + Path, Self, False);
    FreeArea.IsFolder := False;
    FreeArea.IsFree := True;
  end;
  // Space indicators belong to the summary center, never to the file tree.
  UsedArea.Size := Capacity - FreeSpace;
  FreeArea.Size := FreeSpace;
  Recalculate;
  UsedArea.Files := Files;
end;

function LongPath(const Path: string): string;
begin
  if Path.StartsWith('\\?\') then
    Exit(Path);
  if Path.StartsWith('\\') then
    Result := '\\?\UNC\' + Copy(Path, 3, MaxInt)
  else
    Result := '\\?\' + ExpandFileName(Path);
end;

function DisplaySize(Value: UInt64): string;
begin
  Result := DisplaySize(Value, Value);
end;

function DisplaySize(Value, Reference: UInt64): string;
const
  Units: array[0..4] of string = ('Bytes', 'KByte', 'MByte', 'GByte', 'TByte');
var
  N, Scale: Double;
  I: Integer;
begin
  Scale := 1;
  I := 0;
  while (Reference / Scale >= 10000) and (I < High(Units)) do
  begin
    Scale := Scale * 1024;
    Inc(I)
  end;
  N := Value / Scale;
  if I = 0 then
    Result := UIntToStr(Value)
  else if N >= 100 then
    Result := FormatFloat('0', N)
  else if N >= 10 then
    Result := FormatFloat('0.0', N)
  else if N >= 1 then
    Result := FormatFloat('0.00', N)
  else
    Result := FormatFloat('0.000', N);
  Result := Result + ' ' + Units[I];
end;

function AvailableDrives: TArray<string>;
var
  Mask: DWORD;
  I: Integer;
  L: TList<string>;
begin
  L := TList<string>.Create;
  try
    Mask := GetLogicalDrives;
    for I := 0 to 25 do
      if (Mask and (DWORD(1) shl I)) <> 0 then
        L.Add(Char(Ord('A') + I) + ':\');
    Result := L.ToArray;
  finally
    L.Free
  end;
end;

function VolumeDisk(const Drive: string): Integer;
type
  TDiskExtent = record
    DiskNumber: DWORD;
    StartingOffset, ExtentLength: Int64;
  end;
  TVolumeDiskExtents = record
    NumberOfDiskExtents: DWORD;
    Extents: array[0..31] of TDiskExtent;
  end;
var
  Volume: THandle;
  Disks: TVolumeDiskExtents;
  Returned: DWORD;
  Count, I: Integer;
begin
  Result := -1;
  if GetDriveType(PChar(IncludeTrailingPathDelimiter(Drive))) = DRIVE_REMOTE then
    Exit;
  // The query needs no access rights, so it works without elevation.
  Volume := CreateFile(PChar('\\.\' + ExtractFileDrive(Drive)), 0, FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil, OPEN_EXISTING, 0, 0);
  if Volume = INVALID_HANDLE_VALUE then
    Exit;
  try
    if not DeviceIoControl(Volume, IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS, nil, 0, @Disks, SizeOf(Disks), Returned, nil) then
      Exit;
    Count := Integer(Disks.NumberOfDiskExtents);
    if Count > Length(Disks.Extents) then
      Count := Length(Disks.Extents);
    for I := 0 to Count - 1 do
      if (Result < 0) or (Integer(Disks.Extents[I].DiskNumber) < Result) then
        Result := Integer(Disks.Extents[I].DiskNumber);
  finally
    CloseHandle(Volume);
  end;
end;

function DiskSeeks(Disk: Integer): Boolean;
type
  TStoragePropertyQuery = record
    PropertyId, QueryType: DWORD;
    AdditionalParameters: array[0..0] of Byte;
  end;
  TSeekPenaltyDescriptor = record
    Version, Size: DWORD;
    IncursSeekPenalty: ByteBool;
  end;
const
  StorageDeviceSeekPenaltyProperty = 7;
  PropertyStandardQuery = 0;
var
  Device: THandle;
  Query: TStoragePropertyQuery;
  Penalty: TSeekPenaltyDescriptor;
  Returned: DWORD;
begin
  Result := True;
  if Disk < 0 then
    Exit;
  Device := CreateFile(PChar('\\.\PhysicalDrive' + Disk.ToString), 0, FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil, OPEN_EXISTING, 0, 0);
  if Device = INVALID_HANDLE_VALUE then
    Exit;
  try
    Query := Default(TStoragePropertyQuery);
    Query.PropertyId := StorageDeviceSeekPenaltyProperty;
    Query.QueryType := PropertyStandardQuery;
    if DeviceIoControl(Device, IOCTL_STORAGE_QUERY_PROPERTY, @Query, SizeOf(Query), @Penalty, SizeOf(Penalty), Returned, nil) and
      (Returned >= SizeOf(Penalty)) then
      Result := Penalty.IncursSeekPenalty;
  finally
    CloseHandle(Device);
  end;
end;

constructor TScanThread.Create(const Paths: TArray<string>; const RefreshVolumes: TArray<string>; SourceRoot: TDiskNode);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSourceRoot := SourceRoot;
  FCreatedNodes := TObjectList<TDiskNode>.Create(True);
  FChanges := TObjectList<TScanChange>.Create(True);
  FPaths := Copy(Paths);
  FRefreshVolumes := Copy(RefreshVolumes);
  FCounting := False;
  FSpine := TList<TDiskNode>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TScanThread.Destroy;
begin
  RequestCancel;
  if not FStartRequested then
    Start;
  // CancelSynchronousIo is a no-op between I/O calls, so a cancel can land just
  // before the worker blocks on a slow share. Repeat it until the thread exits.
  while WaitForSingleObject(Handle, 50) = WAIT_TIMEOUT do
    RequestCancel;
  WaitFor;
  FChanges.Free;
  FCreatedNodes.Free;
  FRoot.Free;
  FPreview.Free;
  FSpine.Free;
  FLock.Free;
  inherited;
end;

function TScanThread.Done: Boolean;
begin
  Result := (TInterlocked.CompareExchange(FDone, 0, 0) <> 0) or Finished;
end;

procedure TScanThread.Start;
begin
  // TThread.Started becomes true inside ThreadProc, after Start returns. Keep
  // our own launch state so immediate cancellation cannot resume it twice.
  if FStartRequested then
    Exit;
  FStartRequested := True;
  inherited Start;
end;

function TScanThread.TakeRoot: TDiskNode;
begin
  Result := nil;
  if FRoot = nil then
    Exit;
  if (FSourceRoot <> nil) and (Terminated or (FError <> '')) then
    Exit;
  if FSourceRoot <> nil then
    CommitChanges;
  Result := FRoot;
  FRoot := nil;
end;

procedure TScanThread.RequestCancel;
begin
  Terminate;
  CancelSynchronousIo(Handle);
end;

procedure TScanThread.Progress(out Current: string; out Visited: UInt64; out Skipped: Integer);
var
  Total: UInt64;
  Counting: Boolean;
begin
  Progress(Current, Visited, Skipped, Total, Counting)
end;

procedure TScanThread.Progress(out Current: string; out Visited: UInt64; out Skipped: Integer; out Total: UInt64; out Counting: Boolean);
begin
  FLock.Enter;
  try
    Current := FCurrent;
    Visited := FVisited;
    Skipped := FSkipped;
    Total := FTotalFiles;
    Counting := FCounting;
  finally
    FLock.Leave
  end;
end;

procedure TScanThread.ProgressBytes(out Processed, Expected: UInt64);
begin
  FLock.Enter;
  try
    Processed := FProcessedBytes;
    Expected := FExpectedBytes;
  finally
    FLock.Leave
  end;
end;

function TScanThread.ProgressPosition: Integer;
begin
  if Done then
    Exit(128);
  FLock.Enter;
  try
    if FExpectedBytes = 0 then
      Result := 0
    else
      Result := Min(127, Trunc(128 * (FProcessedBytes / FExpectedBytes)));
  finally
    FLock.Leave
  end;
end;

procedure TScanThread.PrepareProgress;
var
  P: string;
  Available, Total, FreeBytes: Int64;
  Expected: UInt64;
begin
  Expected := 0;
  for P in FPaths do
  begin
    if Terminated then
      Exit;
    if SameText(IncludeTrailingPathDelimiter(P), ExtractFileDrive(P) + '\') and
      (GetDriveType(PChar(P)) <> DRIVE_REMOTE) then
      if GetDiskFreeSpaceEx(PChar(P), Available, Total, @FreeBytes) then
        Inc(Expected, UInt64(Max(Int64(0), Total - FreeBytes)));
  end;
  FLock.Enter;
  try
    FExpectedBytes := Expected;
  finally
    FLock.Leave
  end;
end;

procedure TNodeValues.Apply(Node: TDiskNode);
begin
  Node.Size := Size;
  Node.LogicalSize := LogicalSize;
  Node.Files := Files;
  Node.Capacity := Capacity;
  Node.FreeSpace := FreeSpace;
  Node.Unreadable := Unreadable;
  Node.Hidden := False;
  if Node.IsVolume then
    Node.ApplyVolumeSpace(Capacity, FreeSpace);
end;

function TNodeValues.Matches(Node: TDiskNode): Boolean;
begin
  Result := (Size = Node.Size) and (LogicalSize = Node.LogicalSize) and
    (Files = Node.Files) and (Capacity = Node.Capacity) and
    (FreeSpace = Node.FreeSpace) and (Unreadable = Node.Unreadable) and not Node.Hidden;
end;

destructor TScanChange.Destroy;
begin
  Children.Free; // Journal lists never own the borrowed or newly created nodes.
  inherited;
end;

function FindChild(Children: TObjectList<TDiskNode>; const Name: string): TDiskNode;
var
  L, R, M, Order, I: Integer;
begin
  Result := nil;
  if Children = nil then
    Exit;
  L := 0;
  R := Children.Count - 1;
  while L <= R do
  begin
    M := L + (R - L) div 2;
    Order := CompareText(Children[M].Name, Name);
    if Order = 0 then
    begin
      // Exact names also handle Windows directories with case sensitivity
      // enabled. A case-only rename is treated as removal plus addition.
      I := M;
      while (I >= 0) and (CompareText(Children[I].Name, Name) = 0) do
      begin
        if Children[I].Name = Name then
          Exit(Children[I]);
        Dec(I);
      end;
      I := M + 1;
      while (I < Children.Count) and (CompareText(Children[I].Name, Name) = 0) do
      begin
        if Children[I].Name = Name then
          Exit(Children[I]);
        Inc(I);
      end;
      Exit;
    end;
    if Order < 0 then
      L := M + 1
    else
      R := M - 1;
  end;
end;

function TScanThread.FindSource(const Path: string): TDiskNode;

  function Find(Node: TDiskNode): TDiskNode;
  var
    Child: TDiskNode;
    NodePath: string;
  begin
    Result := nil;
    if Node = nil then
      Exit;
    NodePath := Node.Path;
    if Node.IsFolder and SameText(ExcludeTrailingPathDelimiter(NodePath),
      ExcludeTrailingPathDelimiter(Path)) then
      Exit(Node);
    if not Node.IsFolder or ((NodePath <> '') and
      not Path.StartsWith(IncludeTrailingPathDelimiter(NodePath), True)) then
      Exit;
    for Child in Node.Children do
      if Child.IsFolder then
      begin
        Result := Find(Child);
        if Result <> nil then
          Exit
      end;
  end;

begin
  Result := Find(FSourceRoot);
end;

function TScanThread.NewNode(const Path, Name: string; Parent: TDiskNode; IsFolder: Boolean): TDiskNode;
begin
  Result := TDiskNode.Create(Path, Name, Parent, IsFolder);
  if FSourceRoot <> nil then
  begin
    if Result.Children <> nil then
      Result.Children.OwnsObjects := False;
    try
      FCreatedNodes.Add(Result);
    except
      Result.Free;
      raise
    end;
  end;
end;

procedure TScanThread.StageNode(Node: TDiskNode; const Name: string; const Values: TNodeValues; Children: TObjectList<TDiskNode>; Existing: Boolean);
var
  Change: TScanChange;
  I: Integer;
  SameChildren: Boolean;
begin
  if not Existing then
  begin
    Values.Apply(Node);
    Exit;
  end;
  if Children <> nil then
  begin
    SameChildren := Children.Count = Node.Children.Count;
    if SameChildren then
      for I := 0 to Children.Count - 1 do
        if Children[I] <> Node.Children[I] then
        begin
          SameChildren := False;
          Break
        end;
    if SameChildren then
      FreeAndNil(Children);
  end;
  if (Children = nil) and Values.Matches(Node) and (Name = Node.Name) then
    Exit;
  try
    Change := TScanChange.Create;
  except
    Children.Free;
    raise
  end;
  try
    Change.Children := Children;
    Change.Node := Node;
    Change.Name := Name;
    Change.Values := Values;
    FChanges.Add(Change);
  except
    Change.Free;
    raise
  end;
end;

procedure TScanThread.CommitChanges;
var
  Node, OldChild: TDiskNode;
  Change: TScanChange;
  OldChildren: TObjectList<TDiskNode>;
begin
  // Called on the UI thread after all readers have finished and UI references
  // have been converted to paths. Detach retained roots before retiring FSourceRoot.
  for Node in FRoot.Children do
    if Node.Parent <> FRoot then
    begin
      if Node.Parent <> nil then
        Node.Parent.Children.Extract(Node);
      Node.Parent := FRoot;
    end;
  for Change in FChanges do
  begin
    Node := Change.Node;
    if Change.Children <> nil then
    begin
      OldChildren := Node.Children;
      OldChildren.OwnsObjects := False;
      for OldChild in OldChildren do
        if FindChild(Change.Children, OldChild.Name) <> OldChild then
          OldChild.Free;
      Node.Children := Change.Children;
      Change.Children := nil;
      Node.Children.OwnsObjects := True;
      OldChildren.Free;
    end;
    if (Node.Name <> Change.Name) and (Node.Parent <> nil) and
      (Node.Parent.FPathPart <> '') then
      Node.FPathPart := Change.Name;
    Node.Name := Change.Name;
    Change.Values.Apply(Node);
  end;
  for Node in FCreatedNodes do
    if Node.Children <> nil then
      Node.Children.OwnsObjects := True;
  FCreatedNodes.OwnsObjects := False;
  FCreatedNodes.Clear;
  FRoot.Children.OwnsObjects := True;
  FChanges.Clear;
end;

procedure TScanThread.DiscardResult;
begin
  FChanges.Clear;
  FCreatedNodes.Clear;
  FreeAndNil(FRoot);
end;

const
  // A preview holds what a view can draw: levels below the viewed folder, and
  // below its own items only those at least this fraction of its size. That
  // bounds the copy by what is visible, not by the size of the drive.
  PreviewDepth = 6;
  PreviewDetail = 10000;

function TScanThread.InSpine(Node: TDiskNode; Depth: Integer): Boolean;
begin
  Result := (Depth < FSpine.Count) and (FSpine[Depth] = Node);
end;

function TScanThread.SpineValues(Node: TDiskNode; Depth: Integer): TNodeValues;
var
  Child: TDiskNode;
  Values: TNodeValues;
begin
  // A directory being read has no totals yet: add up its finished children
  // and, recursively, the one still being read.
  Result := Default(TNodeValues);
  for Child in Node.Children do
  begin
    if InSpine(Child, Depth + 1) then
      Values := SpineValues(Child, Depth + 1)
    else
    begin
      Values := Default(TNodeValues);
      Values.Size := Child.Size;
      Values.LogicalSize := Child.LogicalSize;
      Values.Files := Child.Files;
    end;
    Inc(Result.Size, Values.Size);
    Inc(Result.LogicalSize, Values.LogicalSize);
    Inc(Result.Files, Values.Files);
  end;
end;

function TScanThread.CopyNode(Node: TDiskNode; Depth: Integer; Parent: TDiskNode): TDiskNode;
var
  Values: TNodeValues;
begin
  // The copy has no children yet; it is added to Parent when one is given.
  Result := TDiskNode.Create('', Node.Name, nil, Node.IsFolder);
  try
    Result.FPathPart := Node.FPathPart;
    Result.IsVolume := Node.IsVolume;
    Result.Unreadable := Node.Unreadable;
    if InSpine(Node, Depth) then
    begin
      Values := SpineValues(Node, Depth);
      Result.Size := Values.Size;
      Result.LogicalSize := Values.LogicalSize;
      Result.Files := Values.Files;
    end
    else
    begin
      Result.Size := Node.Size;
      Result.LogicalSize := Node.LogicalSize;
      Result.Files := Node.Files;
    end;
    if Parent <> nil then
    begin
      Result.FParent := Parent;
      Parent.Children.Add(Result);
    end;
  except
    Result.Free;
    raise
  end;
end;

procedure TScanThread.CopyChildren(Source, Target: TDiskNode; Depth, Level: Integer; Threshold: UInt64; All: Boolean);
var
  Child, ChildCopy: TDiskNode;
begin
  if Level > PreviewDepth then
    Exit;
  // Directories being read count as big enough: their totals are still growing.
  for Child in Source.Children do
    if All or InSpine(Child, Depth + 1) or (Child.Size >= Threshold) then
    begin
      ChildCopy := CopyNode(Child, Depth + 1, Target);
      if Child.IsFolder then
        CopyChildren(Child, ChildCopy, Depth + 1, Level + 1, Threshold, False);
    end;
end;

function TScanThread.PreviewOf(const FocusPath: string): TDiskNode;
var
  Chain: TArray<TDiskNode>;
  Node, Child, Next, Target, NextTarget: TDiskNode;
  Name: string;
  Depth, Last: Integer;
begin
  // The folders from the scan root down to the viewed one, as far as read.
  Node := FSpine[0];
  Chain := [Node];
  if PathWithin(FocusPath, Node.Path) and not SamePath(FocusPath, Node.Path) then
    for Name in Copy(FocusPath, Length(IncludeTrailingPathDelimiter(Node.Path)) + 1, MaxInt).Split([PathDelim],
      TStringSplitOptions.ExcludeEmpty) do
    begin
      Next := nil;
      for Child in Node.Children do
        if Child.IsFolder and SameText(Child.Name, Name) then
        begin
          Next := Child;
          Break
        end;
      if Next = nil then
        Break;
      Node := Next;
      Chain := Chain + [Node];
    end;
  Last := Integer(High(Chain));
  Result := CopyNode(Chain[0], 0, nil);
  try
    // Folders above the viewed one keep their direct children, so going up
    // shows their lists until the next preview fills them in.
    Target := Result;
    for Depth := 0 to Last - 1 do
    begin
      NextTarget := nil;
      for Child in Chain[Depth].Children do
        if Child = Chain[Depth + 1] then
          NextTarget := CopyNode(Child, Depth + 1, Target)
        else
          CopyNode(Child, Depth + 1, Target);
      Target := NextTarget;
    end;
    CopyChildren(Chain[Last], Target, Last, 1, Target.Size div PreviewDetail, True);
  except
    Result.Free;
    raise
  end;
end;

procedure TScanThread.PublishPreview;
var
  Preview, Stale: TDiskNode;
  Clock: TStopwatch;
  Focus: string;
begin
  // A rescan journals its changes over the borrowed tree; only a fresh tree
  // can be copied as it stands.
  if (FSourceRoot <> nil) or (FSpine.Count = 0) then
    Exit;
  FLock.Enter;
  try
    Focus := FPreviewFocus;
  finally
    FLock.Leave
  end;
  Clock := TStopwatch.StartNew;
  Preview := PreviewOf(Focus);
  FLock.Enter;
  try
    Stale := FPreview;
    FPreview := Preview;
    FPreviewTime := Clock.ElapsedMilliseconds;
  finally
    FLock.Leave
  end;
  Stale.Free;
end;

procedure TScanThread.RequestPreview(const FocusPath: string);
begin
  FLock.Enter;
  try
    FPreviewFocus := FocusPath;
  finally
    FLock.Leave
  end;
  TInterlocked.Exchange(FPreviewWanted, 1);
end;

function TScanThread.TakePreview(out BuildTime: Int64): TDiskNode;
begin
  FLock.Enter;
  try
    Result := FPreview;
    BuildTime := FPreviewTime;
    FPreview := nil;
  finally
    FLock.Leave
  end;
end;

function TScanThread.ScanDirectory(Node: TDiskNode; const DirectoryPath: string; Cluster: UInt64; Depth: Integer; Existing: Boolean): TNodeValues;
var
  Data: TWin32FindData;
  Search: THandle;
  Child: TDiskNode;
  ItemPath, ItemName, Prefix: string;
  N, Physical: UInt64;
  Hi, Lo: DWORD;
  List, PendingList: TObjectList<TDiskNode>;
  ChildValues: TNodeValues;
  ChildExists, IsFolder: Boolean;
begin
  Result := Default(TNodeValues);
  if Node.IsVolume then
  begin
    Result.Capacity := Node.Capacity;
    Result.FreeSpace := Node.FreeSpace
  end;
  if Terminated then
    Exit;
  List := Node.Children;
  if Existing then
    List := TObjectList<TDiskNode>.Create(False);
  try
    FSpine.Add(Node);
    if Depth > 512 then
      Result.Unreadable := True
    else
    begin
      FLock.Enter;
      try
        FCurrent := DirectoryPath;
      finally
        FLock.Leave
      end;
      Prefix := IncludeTrailingPathDelimiter(DirectoryPath);
      Search := FindFirstFile(PChar(IncludeTrailingPathDelimiter(LongPath(DirectoryPath)) + '*'), Data);
      if Search = INVALID_HANDLE_VALUE then
      begin
        Result.Unreadable := True;
        FLock.Enter;
        try
          Inc(FSkipped);
        finally
          FLock.Leave
        end;
      end
      else
      try
        repeat
          if Terminated then
            Exit;
          // Between entries every finished child has its totals, so this is
          // a safe point to copy the tree for the UI.
          if TInterlocked.CompareExchange(FPreviewWanted, 0, 1) = 1 then
            PublishPreview;
          ItemName := Data.cFileName;
          if (ItemName = '.') or (ItemName = '..') then
            Continue;
          IsFolder := (Data.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0;
          Child := nil;
          if Existing then
            Child := FindChild(Node.Children, ItemName);
          if (Child <> nil) and (Child.IsFolder <> IsFolder) then
            Child := nil;
          ChildExists := Child <> nil;
          // Only a recursion frame or compressed-file query needs a full path.
          if IsFolder or
            ((Data.dwFileAttributes and (FILE_ATTRIBUTE_COMPRESSED or FILE_ATTRIBUTE_SPARSE_FILE)) <> 0) then
            ItemPath := Prefix + ItemName;
          if not ChildExists then
            Child := NewNode(ItemName, ItemName, Node, IsFolder);
          try
            List.Add(Child);
          except
            if FSourceRoot = nil then
              Child.Free;
            raise;
          end;
          ChildValues := Default(TNodeValues);
          if IsFolder then
          begin
            // Never follow junctions or symbolic directory links.
            if (Data.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) = 0 then
              ChildValues := ScanDirectory(Child, ItemPath, Cluster, Depth + 1, ChildExists)
            else
            begin
              PendingList := nil;
              if ChildExists then
                PendingList := TObjectList<TDiskNode>.Create(False);
              StageNode(Child, ItemName, ChildValues, PendingList, ChildExists);
            end;
            if ChildExists and (Child.Name <> ItemName) then
              StageNode(Child, ItemName, ChildValues, nil, True);
          end
          else
          begin
            N := (UInt64(Data.nFileSizeHigh) shl 32) or Data.nFileSizeLow;
            Physical := N;
            if (Data.dwFileAttributes and (FILE_ATTRIBUTE_COMPRESSED or FILE_ATTRIBUTE_SPARSE_FILE)) <> 0 then
            begin
              Hi := 0;
              SetLastError(NO_ERROR);
              Lo := GetCompressedFileSize(PChar(LongPath(ItemPath)), @Hi);
              if (Lo <> INVALID_FILE_SIZE) or (GetLastError = NO_ERROR) then
                Physical := (UInt64(Hi) shl 32) or Lo;
            end;
            if Physical > 0 then
              Physical := ((Physical + Cluster - 1) div Cluster) * Cluster;
            ChildValues.Size := Physical;
            ChildValues.LogicalSize := N;
            ChildValues.Files := 1;
            StageNode(Child, ItemName, ChildValues, nil, ChildExists);
            FLock.Enter;
            try
              Inc(FVisited);
              Inc(FTotalFiles);
              Inc(FProcessedBytes, Physical);
            finally
              FLock.Leave
            end;
          end;
          Inc(Result.Size, ChildValues.Size);
          Inc(Result.LogicalSize, ChildValues.LogicalSize);
          Inc(Result.Files, ChildValues.Files);
        until not FindNextFile(Search, Data);
      finally
        Winapi.Windows.FindClose(Search)
      end;
    end;
    List.Sort(TComparer<TDiskNode>.Construct(
      function(const L, R: TDiskNode): Integer
      begin
        Result := CompareText(L.Name, R.Name)
      end));
    if Existing then
    begin
      // Transfer the temporary list to the journal, or discard it if unchanged.
      PendingList := List;
      List := nil;
      StageNode(Node, Node.Name, Result, PendingList, True);
    end
    else
      StageNode(Node, Node.Name, Result, nil, False);
  finally
    if (FSpine.Count > 0) and (FSpine.Last = Node) then
      FSpine.Delete(FSpine.Count - 1);
    if Existing then
      List.Free;
  end;
end;

function TScanThread.ScanVolume(Node: TDiskNode; Existing: Boolean): TNodeValues;
var
  Sectors, Bytes, FreeClusters, Clusters: DWORD;
  Available, Total, FreeBytes: Int64;
  Cluster: UInt64;
  P, Name: string;
  VolName: array[0..MAX_PATH] of Char;
begin
  P := Node.Path;
  if Existing then
    Name := Node.Name
  else
    Name := P;
  Cluster := 4096;
  if GetDiskFreeSpace(PChar(ExtractFileDrive(P) + '\'), Sectors, Bytes, FreeClusters, Clusters) then
    Cluster := UInt64(Sectors) * Bytes;
  if Cluster = 0 then
    Cluster := 4096;
  if not Existing then
    Node.IsVolume := SameText(IncludeTrailingPathDelimiter(P), ExtractFileDrive(P) + '\');
  if Node.IsVolume then
    if GetVolumeInformation(PChar(P), VolName, Length(VolName), nil, Sectors, Bytes, nil, 0) then
      if VolName[0] <> #0 then
        Name := P + '  ' + string(VolName);
  Result := ScanDirectory(Node, P, Cluster, 0, Existing);
  if Terminated then
    Exit;
  if Node.IsVolume and (GetDriveType(PChar(P)) <> DRIVE_REMOTE) then
  begin
    Available := 0;
    Total := 0;
    FreeBytes := 0;
    if GetDiskFreeSpaceEx(PChar(P), Available, Total, @FreeBytes) then
    begin
      Result.Capacity := Total;
      Result.FreeSpace := FreeBytes
    end;
  end;
  StageNode(Node, Name, Result, nil, Existing);
  if not Existing then
    Node.Name := Name;
end;

procedure TScanThread.Execute;
var
  P: string;
  N: TDiskNode;
  Space: TVolumeSpace;
  Available, Total, FreeBytes: Int64;
  Values: TNodeValues;
  Existing: Boolean;
begin
  try
    try
      if Terminated then
        Exit;
      FRoot := TDiskNode.Create('', 'Summary');
      if FSourceRoot <> nil then
        FRoot.Children.OwnsObjects := False;
      PrepareProgress;
      if Terminated then
        Exit;
      for P in FPaths do
      begin
        if Terminated then
          Break;
        N := FindSource(P);
        Existing := N <> nil;
        if not Existing then
          N := NewNode(P, P, FRoot, True);
        try
          FRoot.Children.Add(N);
        except
          if (FSourceRoot = nil) and not Existing then
            N.Free;
          raise;
        end;
        Values := ScanVolume(N, Existing);
        Inc(FRoot.Size, Values.Size);
        Inc(FRoot.Files, Values.Files);
        Inc(FRoot.LogicalSize, Values.LogicalSize);
        Inc(FRoot.Capacity, Values.Capacity);
        Inc(FRoot.FreeSpace, Values.FreeSpace);
      end;
      if not Terminated then
        for P in FRefreshVolumes do
        begin
          Available := 0;
          Total := 0;
          FreeBytes := 0;
          if GetDiskFreeSpaceEx(PChar(P), Available, Total, @FreeBytes) then
          begin
            Space.Path := P;
            Space.Capacity := Total;
            Space.FreeSpace := FreeBytes;
            FVolumeSpaces := FVolumeSpaces + [Space];
          end;
        end;
    except
      on E: Exception do
        FError := E.Message
    end;
  finally
    // Clean cancelled partial trees on the worker, rather than blocking the UI
    // timer while its retired-worker list is being reaped.
    if Terminated or ((FSourceRoot <> nil) and (FError <> '')) then
      DiscardResult;
    TInterlocked.Exchange(FDone, 1);
  end;
end;

function SamePath(const A, B: string): Boolean;
begin
  Result := SameText(ExcludeTrailingPathDelimiter(A), ExcludeTrailingPathDelimiter(B));
end;

function PathWithin(const Path, Root: string): Boolean;
begin
  Result := SamePath(Path, Root) or Path.StartsWith(IncludeTrailingPathDelimiter(Root), True);
end;

constructor TScanJob.Create(const RootPath, Path, Lane: string);
begin
  inherited Create;
  FRootPath := RootPath;
  FPath := Path;
  FLane := Lane;
end;

destructor TScanJob.Destroy;
begin
  FWorker.Free;
  inherited;
end;

constructor TScanScheduler.Create;
begin
  inherited;
  FJobs := TObjectList<TScanJob>.Create(True);
  FRetired := TObjectList<TScanJob>.Create(True);
end;

destructor TScanScheduler.Destroy;
var
  Job: TScanJob;
begin
  // Cancel every reader first so they unwind together, then join them.
  for Job in FJobs do
    if Job.Worker <> nil then
      Job.Worker.RequestCancel;
  for Job in FRetired do
    Job.Worker.RequestCancel;
  FJobs.Free;
  FRetired.Free;
  inherited;
end;

function TScanScheduler.Add(const RootPath, Path, Lane: string): TScanJob;
var
  Existing: TScanJob;
begin
  // The newest request for a root wins; two jobs never borrow the same root.
  Existing := Find(RootPath);
  if Existing <> nil then
    Cancel(Existing);
  Result := TScanJob.Create(RootPath, Path, Lane);
  try
    FJobs.Add(Result);
  except
    Result.Free;
    raise
  end;
end;

function TScanScheduler.Find(const RootPath: string): TScanJob;
var
  Job: TScanJob;
begin
  for Job in FJobs do
    if SamePath(Job.RootPath, RootPath) then
      Exit(Job);
  Result := nil;
end;

function TScanScheduler.Retiring(const RootPath: string): Boolean;
var
  Job: TScanJob;
begin
  for Job in FRetired do
    if SamePath(Job.RootPath, RootPath) then
      Exit(True);
  Result := False;
end;

function TScanScheduler.Borrows(const RootPath: string): Boolean;
begin
  Result := (Find(RootPath) <> nil) or Retiring(RootPath);
end;

function TScanScheduler.LaneHolder(const Lane: string): TScanJob;
var
  Job: TScanJob;
begin
  for Job in FJobs do
    if (Job.Worker <> nil) and not Job.Worker.Done and SameText(Job.Lane, Lane) then
      Exit(Job);
  Result := nil;
end;

function TScanScheduler.LaneBusy(const Lane: string): Boolean;
var
  Job: TScanJob;
begin
  if LaneHolder(Lane) <> nil then
    Exit(True);
  // A cancelled reader still holds its device until it unwinds.
  for Job in FRetired do
    if not Job.Worker.Finished and SameText(Job.Lane, Lane) then
      Exit(True);
  Result := False;
end;

function TScanScheduler.Jobs: TArray<TScanJob>;
begin
  Result := FJobs.ToArray;
end;

function TScanScheduler.Idle: Boolean;
begin
  Result := (FJobs.Count = 0) and (FRetired.Count = 0);
end;

procedure TScanScheduler.Cancel(Job: TScanJob);
begin
  if Job.Worker = nil then
  begin
    FJobs.Remove(Job);
    Exit;
  end;
  Job.Worker.RequestCancel;
  FRetired.Add(Job);
  FJobs.Extract(Job);
end;

procedure TScanScheduler.StartReady(const CreateWorker: TFunc<TScanJob, TScanThread>);
var
  Job: TScanJob;
begin
  // Earlier requests claim their lane first. A root waits for its cancelled
  // readers, so a merge never mutates nodes another worker still reads.
  for Job in FJobs do
    if (Job.Worker = nil) and not LaneBusy(Job.Lane) and not Retiring(Job.RootPath) then
    begin
      Job.FWorker := CreateWorker(Job);
      Job.FWorker.Start;
    end;
end;

function TScanScheduler.TakeFinished: TScanJob;
var
  Job: TScanJob;
begin
  for Job in FJobs do
    if (Job.Worker <> nil) and Job.Worker.Done then
    begin
      FJobs.Extract(Job);
      Exit(Job);
    end;
  Result := nil;
end;

procedure TScanScheduler.Reap;
var
  I: NativeInt;
begin
  for I := FRetired.Count - 1 downto 0 do
    if FRetired[I].Worker.Finished then
      FRetired.Delete(I)
    else
      // A cancel can land between two I/O calls; repeat it until the worker stops.
      FRetired[I].Worker.RequestCancel;
end;

end.

