unit Scanner.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.Generics.Collections, System.IniFiles, System.Messaging, FMX.Types, FMX.Controls,
  FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Objects, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Menus, FMX.Ani, Scanner.Model,
  Scanner.ViewModel, Scanner.Chart, Scanner.DriveButton, Scanner.FolderItem,
  Scanner.Localization;

type
  // History is kept as paths: previews and merges replace the nodes.
  TViewPath = record
    Path: string;
    Overview: Boolean;
  end;

  // UI references kept as paths while a merge replaces part of the tree.
  TSavedView = record
    HasFocus: Boolean;
    Focus, Selected, Context: string;
  end;

  TScanStatus = record
    Current, Waiting: string;
    Visited: UInt64;
    Position: Integer;
  end;

  TFormMain = class(TForm)
    RectangleFooterBackground: TRectangle;
    RectangleFooterSeparator: TRectangle;
    CircleStatusDot: TCircle;
    LayoutStatusDotSlot: TLayout;
    LabelStatus: TLabel;
    LabelFilesSummary: TLabel;
    LayoutFooter: TLayout;
    RectangleSidebarBackground: TRectangle;
    RectangleSidebarSeparator: TRectangle;
    LabelLocations: TLabel;
    PathSummaryIcon: TPath;
    LayoutSummaryGlyph: TLayout;
    LabelSummaryText: TLabel;
    SpeedButtonSummary: TSpeedButton;
    VertScrollBoxDrives: TVertScrollBox;
    LayoutDriveListSlot: TLayout;
    RectangleSidebarActionSeparator: TRectangle;
    PathChooseIcon: TPath;
    LayoutChooseGlyph: TLayout;
    LabelChooseText: TLabel;
    SpeedButtonChoose: TSpeedButton;
    PathThemeIcon: TPath;
    LayoutThemeGlyph: TLayout;
    LabelThemeText: TLabel;
    SpeedButtonTheme: TSpeedButton;
    PathSettingsIcon: TPath;
    LayoutSettingsGlyph: TLayout;
    LabelSettingsText: TLabel;
    SpeedButtonSettings: TSpeedButton;
    LayoutSidebarActions: TLayout;
    LayoutDriveSide: TLayout;
    RectangleToolbarSeparator: TRectangle;
    PathBackIcon: TPath;
    SpeedButtonBack: TSpeedButton;
    PathUpIcon: TPath;
    SpeedButtonUp: TSpeedButton;
    PathScanIcon: TPath;
    LayoutScanGlyph: TLayout;
    LabelScanText: TLabel;
    SpeedButtonScan: TSpeedButton;
    PathBrowseIcon: TPath;
    SpeedButtonBrowse: TSpeedButton;
    LabelPath: TLabel;
    RectangleBreadcrumbBorder: TRectangle;
    LayoutToolbar: TLayout;
    LabelPageTitle: TLabel;
    LabelPageSubtitle: TLabel;
    LabelUsedValueCaption: TLabel;
    LabelUsedValue: TLabel;
    LayoutUsedValueSlot: TLayout;
    LabelFreeValueCaption: TLabel;
    LabelFreeValue: TLabel;
    LayoutFreeValueSlot: TLayout;
    LabelTotalValueCaption: TLabel;
    LabelTotalValue: TLabel;
    LayoutTotalValueSlot: TLayout;
    RectangleUsageFill: TRectangle;
    RectangleUsageTrack: TRectangle;
    LabelUsagePercent: TLabel;
    LayoutUsageSlot: TLayout;
    LayoutStorageSummary: TLayout;
    LayoutHeader: TLayout;
    RectangleDetailSeparator: TRectangle;
    PathDetailIcon: TPath;
    LayoutDetailGlyph: TLayout;
    LabelDetailName: TLabel;
    LabelDetailSize: TLabel;
    LayoutDetailTitles: TLayout;
    LayoutDetailTop: TLayout;
    LabelDetailPercent: TLabel;
    LabelDetailPath: TLabel;
    PathOpenIcon: TPath;
    LayoutOpenGlyph: TLayout;
    LabelOpenText: TLabel;
    SpeedButtonOpen: TSpeedButton;
    LayoutDetailSection: TLayout;
    LabelPercentColumn: TLabel;
    LabelSizeColumn: TLabel;
    LabelNameColumn: TLabel;
    RectangleTableSeparator: TRectangle;
    LayoutTableHeader: TLayout;
    RectangleFolderPanelBackground: TRectangle;
    LabelFolderTitle: TLabel;
    RectangleFolderTitleSeparator: TRectangle;
    LayoutFolderPanelTitle: TLayout;
    VertScrollBoxFolders: TVertScrollBox;
    LabelEmpty: TLabel;
    LayoutFolderPanel: TLayout;
    LabelScan: TLabel;
    ProgressBarScan: TProgressBar;
    LayoutScanStatus: TLayout;
    LayoutChartViews: TLayout;
    PaintBoxChart: TPaintBox;
    LayoutChartColumn: TLayout;
    LayoutWorkspace: TLayout;
    LayoutMainContent: TLayout;
    LayoutBody: TLayout;
    MenuItemLanguage: TMenuItem;
    MenuItemLanguageRussian: TMenuItem;
    MenuItemLanguageEnglish: TMenuItem;
    MenuItemApps: TMenuItem;
    MenuItemTrash: TMenuItem;
    MenuItemAbout: TMenuItem;
    MenuItemFreeSpace: TMenuItem;
    MenuItemLiveScan: TMenuItem;
    PopupMenuSettings: TPopupMenu;
    PathScanIconTemplate: TPath;
    PathStopIconTemplate: TPath;
    PathFolderIconTemplate: TPath;
    PathFileIconTemplate: TPath;
    PathSunIconTemplate: TPath;
    PathMoonIconTemplate: TPath;
    LayoutIconTemplates: TLayout;
    StyleBookDark: TStyleBook;
    StyleBookLight: TStyleBook;
    LangLanguages: TLang;
    TimerPoll: TTimer;
    PopupMenuNode: TPopupMenu;
    MenuItemHide: TMenuItem;
    MenuItemZoom: TMenuItem;
    MenuItemRescan: TMenuItem;
    MenuItemOpen: TMenuItem;
    MenuItemSeparator: TMenuItem;
    MenuItemRecycle: TMenuItem;
    MenuItemRemove: TMenuItem;
    PopupMenuDrive: TPopupMenu;
    MenuItemInclude: TMenuItem;
    MenuItemPhysical: TMenuItem;
    Rectangle1: TRectangle;
    procedure FormMainCreate(Sender: TObject);
    procedure FormMainDestroy(Sender: TObject);
    procedure FormMainKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure PaintBoxChartPaint(Sender: TObject; Canvas: TCanvas);
    procedure PaintBoxChartMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxChartMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxChartMouseLeave(Sender: TObject);
    procedure TimerPollTimer(Sender: TObject);
    procedure MenuItemIncludeClick(Sender: TObject);
    procedure MenuItemPhysicalClick(Sender: TObject);
    procedure SpeedButtonThemeClick(Sender: TObject);
    procedure SpeedButtonChooseClick(Sender: TObject);
    procedure SpeedButtonScanClick(Sender: TObject);
    procedure SpeedButtonSettingsClick(Sender: TObject);
    procedure SpeedButtonChartViewClick(Sender: TObject);
    procedure SpeedButtonOpenClick(Sender: TObject);
    procedure FormMainResize(Sender: TObject);
    procedure SpeedButtonFolderItemClick(Sender: TObject);
    procedure SpeedButtonFolderItemDblClick(Sender: TObject);
    procedure SpeedButtonFolderItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure SpeedButtonSummaryClick(Sender: TObject);
    procedure SpeedButtonBackClick(Sender: TObject);
    procedure SpeedButtonUpClick(Sender: TObject);
    procedure SpeedButtonBrowseClick(Sender: TObject);
    procedure MenuItemLanguageRussianClick(Sender: TObject);
    procedure MenuItemLanguageEnglishClick(Sender: TObject);
    procedure MenuItemAppsClick(Sender: TObject);
    procedure MenuItemTrashClick(Sender: TObject);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure MenuItemFreeSpaceClick(Sender: TObject);
    procedure MenuItemLiveScanClick(Sender: TObject);
    procedure MenuItemHideClick(Sender: TObject);
    procedure MenuItemZoomClick(Sender: TObject);
    procedure MenuItemRescanClick(Sender: TObject);
    procedure MenuItemOpenClick(Sender: TObject);
    procedure MenuItemRecycleClick(Sender: TObject);
    procedure MenuItemRemoveClick(Sender: TObject);
  private
    // FRoot is the summary of included drives; FOther holds every other scan
    // root (excluded drives and chosen folders). Both live for the whole session.
    FRoot, FOther, FFocus, FHover, FContext: TDiskNode;
    FScans: TScanScheduler;
    FSkippedByRoot: TDictionary<string, Integer>;
    // Roots that are a running fresh scan's preview. They are never borrowed
    // by a scan, and are dropped if their scan stops before finishing.
    FProvisional: TDictionary<string, Boolean>;
    FHistory: TList<TViewPath>;
    FViewData: TDiskViewModel;
    FChartView: TDiskChartView;
    FChartViewID: string;
    FHoverKind: TChartHitKind;
    FDrives: TArray<string>;
    // The folder list shows FRowNodes through a few recycled rows, laid over a
    // spacer as tall as the whole list. FPressedPath is the item under the
    // mouse button, in case a preview re-binds its row before the click.
    FRows: TList<TFrameFolderItem>;
    FRowNodes: TArray<TDiskNode>;
    FRowSpacer: TLayout;
    FRowHeight: Single;
    FPressedPath: string;
    FIncluded: TDictionary<string, Boolean>;
    FDevices: TDictionary<string, Integer>;
    // Drives on a disk without a seek penalty (SSDs).
    FSolidState: TDictionary<string, Boolean>;
    FDriveContext: string;
    // A location shown before its results exist; FPendingRoot names its job.
    FStartFolder, FPendingPath, FPendingRoot: string;
    FHoverPoint: TPointF;
    FClosing: Boolean;
    FBeforeShownId: Int64;
    FPlacementRestored: Boolean;
    FVolumeOverview, FPendingOverview: Boolean;
    FIni: TMemIniFile;
    FDarkTheme: Boolean;
    FDesignReady: Boolean;
    FSelected: TDiskNode;
    FViewNodes: TArray<TDiskNode>;

    FBackground, FPanelColor, FTextColor, FMutedColor, FBorderColor: TAlphaColor;
    procedure ApplicationException(Sender: TObject; E: Exception);
    procedure FormBeforeShown(const Sender: TObject; const M: System.Messaging.TMessage);
    procedure FormMainClose(Sender: TObject; var Action: TCloseAction);
    procedure RestorePlacement;
    procedure SavePlacement;
    procedure ExecuteUICommand(Sender: TObject);
    procedure ExecuteNodeAction(Sender: TObject);
    procedure ExecuteSettingsAction(Sender: TObject);
    procedure SelectLanguage(const Language: string);
    function ThemeColor(const Role: string): TAlphaColor;
    function ChartContext: TChartContext;
    function ChartTheme: TChartTheme;
    function ViewFraction(Node: TDiskNode): Double;
    procedure ApplyTheme(Dark: Boolean);
    procedure ApplyThemeTo(ObjectRoot: TFmxObject);
    procedure UpdateDashboard;
    procedure ReleaseChildCapture(Container: TFmxObject);
    procedure ClearFolderRows;
    procedure BuildFolderRows;
    procedure EnsureRows(Count: Integer);
    procedure BindRows;
    procedure FolderRowsViewportChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF;
      const ContentSizeChanged: Boolean);
    procedure FolderRowsResize(Sender: TObject);
    procedure UpdateSelection(Node: TDiskNode);
    procedure PopupNode(Node: TDiskNode; const ScreenPoint: TPointF);
    function NodeColor(Node: TDiskNode; Depth: Integer = 1): TAlphaColor;
    function FormatBytes(Value: UInt64): string;
    function NodeTitle(Node: TDiskNode): string;
    function FolderCount(Node: TDiskNode): UInt64;
    function RootNeedsZoom(Node: TDiskNode): Boolean;
    function ContainerFor(const RootPath: string): TDiskNode;
    function FindRoot(const RootPath: string): TDiskNode;
    function FindScanned(const Path: string): TDiskNode;
    function RootOf(Node: TDiskNode): TDiskNode;
    procedure InsertRoot(Container, Node: TDiskNode);
    procedure DropRoot(Root: TDiskNode);
    procedure ArrangeRoots;
    function LaneFor(const RootPath: string): string;
    function EnqueueScan(const RootPath, Path: string): TScanJob;
    function CreateScanWorker(Job: TScanJob): TScanThread;
    procedure MergeJob(Job: TScanJob; Errors: TStrings);
    function IsProvisional(Root: TDiskNode): Boolean;
    procedure RequestPreviews;
    procedure InstallPreview(Job: TScanJob; Preview: TDiskNode);
    procedure ResolvePending(const RootPath: string; Final: Boolean);
    function SaveView: TSavedView;
    function FindNearest(const Path: string): TDiskNode;
    procedure RestoreView(const View: TSavedView);
    procedure ResetViewCaches;
    procedure RefreshView;
    function ViewJobs: TArray<TScanJob>;
    function ViewBusy: Boolean;
    function ViewBlank: Boolean;
    function ViewScanStatus: TScanStatus;
    function ViewSkipped: Integer;
    procedure StopViewScans;
    procedure SetPending(const Path, RootPath: string; Overview: Boolean);
    procedure OpenLocation(const Path: string);
    procedure ShowSummary;
    procedure ScanDrives(Refresh: Boolean);
    procedure RescanRecycleBins;
    procedure UpdateScanStatus;
    procedure ShowNode(Node: TDiskNode);
    procedure UpdateButtons;
    procedure BuildDriveButtons;
    procedure BuildChartViewButtons;
    procedure UpdateChartViewButtons;
    procedure SpeedButtonDriveClick(Sender: TObject);
    procedure SpeedButtonDriveMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Rescan(Node: TDiskNode);
    function FindPath(Node: TDiskNode; const Path: string): TDiskNode;
    procedure ChooseFolder;
    procedure SaveLog;
    procedure RemoveNode(Node: TDiskNode; Recycle: Boolean);
  public
    procedure SetChartView(const ID: string);
    procedure SetLanguage(const Language: string);
    property ChartViewID: string read FChartViewID;
  protected
    procedure FocusNode(Node: TDiskNode; Remember: Boolean = True; Overview: Boolean = False);
    procedure OpenTarget(const Target: string; const Parameters: string = '');
    procedure FileActionError(const Action, Target, Details: string); virtual;
  end;

var
  FormMain: TFormMain;

implementation

uses
  System.IOUtils, System.Generics.Defaults, System.Diagnostics, Winapi.Windows,
  Winapi.ShellAPI, Winapi.Dwmapi, FMX.Platform.Win, Scanner.Dialog;

{$R *.fmx}

function TFormMain.ViewFraction(Node: TDiskNode): Double;
begin
  Result := FViewData.Fraction(FFocus, Node);
end;

procedure TFormMain.FormMainCreate(Sender: TObject);
var
  P, DefaultLanguage: string;
  i, MaxDevice, Disk: Integer;
  Item: TMenuItem;
begin
  if (GetUserDefaultUILanguage and $3FF) = $19 then
    DefaultLanguage := 'ru'
  else
    DefaultLanguage := 'en';
  Application.OnException := ApplicationException;
  OnClose := FormMainClose;
  FBeforeShownId := TMessageManager.DefaultManager.SubscribeToMessage(TFormBeforeShownMessage, FormBeforeShown);
  FRoot := TDiskNode.Create('', 'Summary');
  FOther := TDiskNode.Create('', 'Other');
  FScans := TScanScheduler.Create;
  FSkippedByRoot := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  FProvisional := TDictionary<string, Boolean>.Create(TIStringComparer.Ordinal);
  FRows := TList<TFrameFolderItem>.Create;
  FRowSpacer := TLayout.Create(Self);
  FRowSpacer.HitTest := False;
  FRowSpacer.Parent := VertScrollBoxFolders;
  VertScrollBoxFolders.OnViewportPositionChange := FolderRowsViewportChange;
  VertScrollBoxFolders.OnResize := FolderRowsResize;
  FIni := TMemIniFile.Create(TPath.Combine(TPath.GetHomePath, 'ScannerFMX.ini'), TEncoding.UTF8);
  SetLanguage(FIni.ReadString('Appearance', 'Language', DefaultLanguage));
  FHistory := TList<TViewPath>.Create;
  FViewData := TDiskViewModel.Create;
  // Drive layouts leave out free space unless the user turns it back on.
  MenuItemFreeSpace.IsChecked := FIni.ReadBool('Appearance', 'HideFreeSpace', True);
  FViewData.ShowFreeSpace := not MenuItemFreeSpace.IsChecked;
  MenuItemLiveScan.IsChecked := FIni.ReadBool('Appearance', 'LiveScan', True);
  SetChartView('sunburst');
  FIncluded := TDictionary<string, Boolean>.Create;
  FDevices := TDictionary<string, Integer>.Create;
  FSolidState := TDictionary<string, Boolean>.Create;
  FDrives := AvailableDrives;
  MaxDevice := 7;
  for P in FDrives do
  begin
    FIncluded.Add(P, FIni.ReadBool('Summary', P, GetDriveType(PChar(P)) = DRIVE_FIXED));
    // The disk Windows reports, unless the user picked a device ID.
    Disk := VolumeDisk(P);
    FDevices.Add(P, FIni.ReadInteger('PhysicalDevice', P, Disk));
    FSolidState.Add(P, (Disk >= 0) and not DiskSeeks(Disk));
    MaxDevice := Max(MaxDevice, FDevices[P]);
  end;
  // Tag -1 is Automatic: forget the picked ID and use the detected disk again.
  for i := -1 to MaxDevice do
  begin
    Item := TMenuItem.Create(Self);
    Item.Text := i.ToString;
    Item.Tag := i;
    if (i >= 0) and (i <= 7) then
      Item.StyleLookup := 'menudevice' + i.ToString + 'style'
    else
      Item.StyleLookup := 'menuitemstyle';
    Item.RadioItem := True;
    Item.GroupIndex := 1;
    Item.OnClick := MenuItemPhysicalClick;
    MenuItemPhysical.AddObject(Item);
  end;
  FDesignReady := True;
  ApplyTheme(FIni.ReadBool('Appearance', 'DarkTheme', True));
  BuildDriveButtons;
  BuildChartViewButtons;
  ProgressBarScan.Max := 128;
  FStartFolder := '';
  if ParamCount > 0 then
    FStartFolder := ExpandFileName(ParamStr(1));
  if FStartFolder <> '' then
    OpenLocation(FStartFolder)
  else
    ShowSummary;
end;

// The monitor arrangement in physical pixels, e.g. '2560x1440@0,0
// 1920x1080@2560,180'. The primary monitor is at 0,0, so this also tells
// which one is primary.
function MonitorLayout: string;
var
  Monitors: TList<TRect>;
  R: TRect;
  i: Integer;
begin
  Screen.UpdateDisplayInformation;
  Monitors := TList<TRect>.Create;
  try
    for i := 0 to Screen.DisplayCount - 1 do
      Monitors.Add(Screen.Displays[i].PhysicalBounds);
    Monitors.Sort(TComparer<TRect>.Construct(
      function(const A, B: TRect): Integer
      begin
        Result := CompareValue(A.Left, B.Left);
        if Result = 0 then
          Result := CompareValue(A.Top, B.Top);
      end));
    Result := '';
    for R in Monitors do
      Result := Result + Format(' %dx%d@%d,%d', [R.Width, R.Height, R.Left, R.Top]);
    Result := Trim(Result);
  finally
    Monitors.Free;
  end;
end;

function OnSomeMonitor(const Bounds: TRect): Boolean;
var
  i: Integer;
begin
  for i := 0 to Screen.DisplayCount - 1 do
    if Screen.Displays[i].PhysicalWorkarea.IntersectsWith(Bounds) then
      Exit(True);
  Result := False;
end;

procedure TFormMain.FormBeforeShown(const Sender: TObject; const M: System.Messaging.TMessage);
begin
  // FMX has placed the form (centred) but not shown it yet.
  if (TFormBeforeShownMessage(M).Value = Self) and not FPlacementRestored then
  begin
    FPlacementRestored := True;
    RestorePlacement;
  end;
end;

procedure TFormMain.RestorePlacement;
var
  Placement: TWindowPlacement;
  Bounds: TRect;
  Section: string;
begin
  // Each monitor layout keeps its own placement; a layout not seen before
  // keeps the designed centring.
  Section := 'Window ' + MonitorLayout;
  if not FIni.SectionExists(Section) then
    Exit;
  Bounds := TRect.Create(FIni.ReadInteger(Section, 'Left', 0), FIni.ReadInteger(Section, 'Top', 0),
    FIni.ReadInteger(Section, 'Right', 0), FIni.ReadInteger(Section, 'Bottom', 0));
  if Bounds.IsEmpty or not OnSomeMonitor(Bounds) then
    Exit;
  // The window is still hidden; FMX shows it, maximized if WindowState says so.
  Placement := Default(TWindowPlacement);
  Placement.length := SizeOf(Placement);
  Placement.showCmd := SW_HIDE;
  Placement.rcNormalPosition := Bounds;
  if SetWindowPlacement(FormToHWND(Self), Placement) and FIni.ReadBool(Section, 'Maximized', False) then
    WindowState := TWindowState.wsMaximized;
end;

procedure TFormMain.SavePlacement;
var
  Placement: TWindowPlacement;
  Section: string;
begin
  Placement := Default(TWindowPlacement);
  Placement.length := SizeOf(Placement);
  if not GetWindowPlacement(FormToHWND(Self), Placement) then
    Exit;
  Section := 'Window ' + MonitorLayout;
  // The normal-state bounds, so a maximized window also restores to them.
  FIni.WriteInteger(Section, 'Left', Placement.rcNormalPosition.Left);
  FIni.WriteInteger(Section, 'Top', Placement.rcNormalPosition.Top);
  FIni.WriteInteger(Section, 'Right', Placement.rcNormalPosition.Right);
  FIni.WriteInteger(Section, 'Bottom', Placement.rcNormalPosition.Bottom);
  // A minimized window reopens in the state it was minimized from.
  FIni.WriteBool(Section, 'Maximized', (Placement.showCmd = SW_SHOWMAXIMIZED) or
    ((Placement.showCmd = SW_SHOWMINIMIZED) and (Placement.flags and WPF_RESTORETOMAXIMIZED <> 0)));
  FIni.UpdateFile;
end;

procedure TFormMain.FormMainClose(Sender: TObject; var Action: TCloseAction);
begin
  SavePlacement;
end;

procedure TFormMain.FormMainDestroy(Sender: TObject);
begin
  FClosing := True;
  TMessageManager.DefaultManager.Unsubscribe(TFormBeforeShownMessage, FBeforeShownId);
  Application.OnException := nil;
  FSelected := nil;
  TimerPoll.Enabled := False;
  // Join every worker before freeing the tree they borrow.
  FScans.Free;
  FChartView.Free;
  FViewData.Free;
  FRoot.Free;
  FOther.Free;
  FSkippedByRoot.Free;
  FProvisional.Free;
  FRows.Free;
  FHistory.Free;
  FIncluded.Free;
  FDevices.Free;
  FSolidState.Free;
  FIni.Free;
end;

function IsDriveRoot(const Path: string): Boolean;
begin
  Result := SameText(IncludeTrailingPathDelimiter(Path), ExtractFileDrive(Path) + '\');
end;

function PathOfNode(Node: TDiskNode): string;
begin
  // Synthetic entries belong to the view model and are rebuilt with it.
  if (Node = nil) or (Node is TSmallFileGroup) or (Node is TUnscannedSpace) or Node.IsFree or Node.IsUsed then
    Result := ''
  else
    Result := Node.Path;
end;

function RootKey(const Path: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(Path);
end;

function UsedBytes(const Drive: string): UInt64;
var
  Available, Total, FreeBytes: Int64;
begin
  Result := 0;
  // Like the drive list, never wake removable or remote devices from the UI.
  if GetDriveType(PChar(Drive)) = DRIVE_FIXED then
    if GetDiskFreeSpaceEx(PChar(Drive), Available, Total, @FreeBytes) then
      Result := UInt64(Max(Int64(0), Total - FreeBytes));
end;

function TFormMain.ContainerFor(const RootPath: string): TDiskNode;
var
  Included: Boolean;
begin
  Result := FOther;
  if IsDriveRoot(RootPath) and FIncluded.TryGetValue(IncludeTrailingPathDelimiter(RootPath), Included) and Included then
    Result := FRoot;
end;

function TFormMain.FindRoot(const RootPath: string): TDiskNode;
var
  Container, Node: TDiskNode;
begin
  for Container in TArray<TDiskNode>.Create(FRoot, FOther) do
    for Node in Container.Children do
      if SamePath(Node.Path, RootPath) then
        Exit(Node);
  Result := nil;
end;

function TFormMain.FindScanned(const Path: string): TDiskNode;
begin
  if Path = '' then
    Exit(FRoot);
  // Drives are searched before chosen folders, so a drive's own node wins.
  Result := FindPath(FRoot, Path);
  if Result = nil then
    Result := FindPath(FOther, Path);
end;

function TFormMain.RootOf(Node: TDiskNode): TDiskNode;
begin
  Result := nil;
  while (Node <> nil) and (Node <> FRoot) and (Node <> FOther) do
  begin
    Result := Node;
    Node := Node.Parent;
  end;
  if Node = nil then
    Result := nil;
end;

procedure TFormMain.InsertRoot(Container, Node: TDiskNode);
var
  Index: NativeInt;
begin
  // Drives keep letter order ahead of chosen folders.
  Index := Container.Children.Count;
  if IsDriveRoot(Node.Path) then
  begin
    Index := 0;
    while (Index < Container.Children.Count) and IsDriveRoot(Container.Children[Index].Path) and
      (CompareText(Container.Children[Index].Path, Node.Path) < 0) do
      Inc(Index);
  end;
  Node.Parent := Container;
  Container.Children.Insert(Index, Node);
end;

procedure TFormMain.DropRoot(Root: TDiskNode);
var
  View: TSavedView;
  Container: TDiskNode;
begin
  View := SaveView;
  ResetViewCaches;
  FSkippedByRoot.Remove(RootKey(Root.Path));
  Container := Root.Parent;
  Container.Children.Remove(Root);
  Container.Recalculate;
  RestoreView(View);
end;

procedure TFormMain.ArrangeRoots;
var
  Container, Target, Node, Drive: TDiskNode;
  i: NativeInt;
  Moved: Boolean;
  Key: string;
begin
  // A preview whose scan stopped before finishing is incomplete.
  for Key in FProvisional.Keys.ToArray do
    if FScans.Find(Key) = nil then
    begin
      FProvisional.Remove(Key);
      Node := FindRoot(Key);
      if Node <> nil then
      begin
        DropRoot(Node);
        RefreshView;
      end;
    end;
  // Roots move only while no scan borrows them, so this can lag a running scan.
  Moved := False;
  for Container in TArray<TDiskNode>.Create(FRoot, FOther) do
    for i := Container.Children.Count - 1 downto 0 do
    begin
      Node := Container.Children[i];
      Target := ContainerFor(Node.Path);
      if (Target <> Container) and (IsProvisional(Node) or not FScans.Borrows(Node.Path)) then
      begin
        Container.Children.Extract(Node);
        InsertRoot(Target, Node);
        Moved := True;
      end;
    end;
  if Moved then
  begin
    ResetViewCaches;
    FRoot.Recalculate;
    FOther.Recalculate;
    RefreshView;
  end;
  // A chosen folder is redundant once its drive has been scanned.
  for i := FOther.Children.Count - 1 downto 0 do
  begin
    Node := FOther.Children[i];
    if IsDriveRoot(Node.Path) or FScans.Borrows(Node.Path) then
      Continue;
    Drive := FindRoot(IncludeTrailingPathDelimiter(ExtractFileDrive(Node.Path)));
    if (Drive <> nil) and not IsProvisional(Drive) and not FScans.Borrows(Drive.Path) and
      (FindPath(Drive, Node.Path) <> nil) then
    begin
      DropRoot(Node);
      RefreshView;
    end;
  end;
end;

function TFormMain.LaneFor(const RootPath: string): string;
var
  Drive: string;
  Device: Integer;
  Solid: Boolean;
begin
  // Drives on one spinning disk read in turn. An SSD has no seek penalty, so
  // each scan on it gets its own lane, unless the user grouped the drive by
  // hand. Locations whose disk is unknown (network shares, SUBST drives) get a
  // lane per drive.
  Drive := IncludeTrailingPathDelimiter(ExtractFileDrive(RootPath));
  if not FIni.ValueExists('PhysicalDevice', Drive) and FSolidState.TryGetValue(Drive, Solid) and Solid then
    Result := 'root:' + RootKey(RootPath)
  else if FDevices.TryGetValue(Drive, Device) and (Device >= 0) then
    Result := 'device:' + Device.ToString
  else
    Result := 'path:' + Drive;
end;

function TFormMain.EnqueueScan(const RootPath, Path: string): TScanJob;
var
  Root: TDiskNode;
begin
  // A preview is incomplete, so only its whole root can be scanned again.
  Root := FindRoot(RootPath);
  if (Root <> nil) and IsProvisional(Root) then
    Result := FScans.Add(RootPath, RootPath, LaneFor(RootPath))
  else
    Result := FScans.Add(RootPath, Path, LaneFor(RootPath));
  if SamePath(RootPath, Result.Path) and IsDriveRoot(RootPath) then
    Result.Expected := UsedBytes(IncludeTrailingPathDelimiter(RootPath));
  TimerPoll.Enabled := True;
  FScans.StartReady(CreateScanWorker);
end;

function TFormMain.CreateScanWorker(Job: TScanJob): TScanThread;
var
  Root: TDiskNode;
  Volumes: TArray<string>;
begin
  // Resolve the root as the job starts, so a queued job holds no node. A
  // preview is never borrowed: the job scans afresh and replaces it.
  Root := FindRoot(Job.RootPath);
  if (Root <> nil) and IsProvisional(Root) then
    Root := nil;
  Volumes := nil;
  if (Root <> nil) and Root.IsVolume and (Root.Capacity > 0) and not SamePath(Job.Path, Root.Path) then
    Volumes := [Root.Path];
  Result := TScanThread.Create([Job.Path], Volumes, Root);
end;

procedure TFormMain.MergeJob(Job: TScanJob; Errors: TStrings);
var
  Worker: TScanThread;
  View: TSavedView;
  Root, Target, Parent, NewRoot, Replacement: TDiskNode;
  Index, Skipped: Integer;
  Space: TVolumeSpace;
  Current: string;
  Visited: UInt64;
begin
  Worker := Job.Worker;
  Worker.WaitFor;
  if Worker.Error <> '' then
    Errors.Add(Worker.Error);
  if SamePath(Job.Path, Job.RootPath) then
  begin
    Worker.Progress(Current, Visited, Skipped);
    FSkippedByRoot.AddOrSetValue(RootKey(Job.RootPath), Skipped);
  end;
  View := SaveView;
  ResetViewCaches;
  Root := FindRoot(Job.RootPath);
  Target := nil;
  if Root <> nil then
    Target := FindPath(Root, Job.Path);
  Parent := nil;
  Index := -1;
  if Target <> nil then
  begin
    Parent := Target.Parent;
    Index := Parent.Children.IndexOf(Target);
  end;
  // TakeRoot commits the journal and may detach a reused target from its old
  // parent. Capture the insertion position before that happens.
  NewRoot := Worker.TakeRoot;
  try
    if (NewRoot <> nil) and (NewRoot.Children.Count = 1) then
    begin
      Replacement := NewRoot.Children.Extract(NewRoot.Children[0]);
      if Parent <> nil then
      begin
        Replacement.Parent := Parent;
        if Replacement = Target then
          Parent.Children.Insert(Index, Replacement)
        else
          Parent.Children[Index] := Replacement;
      end
      else if SamePath(Job.Path, Job.RootPath) then
      begin
        Parent := ContainerFor(Job.RootPath);
        InsertRoot(Parent, Replacement);
      end
      else
        // A subtree whose root vanished while queued has nowhere to go.
        Replacement.Free;
      while Parent <> nil do
      begin
        Parent.Recalculate;
        Parent := Parent.Parent;
      end;
    end;
  finally
    NewRoot.Free;
  end;
  for Space in Worker.VolumeSpaces do
  begin
    Target := FindRoot(Space.Path);
    if Target <> nil then
    begin
      Target.ApplyVolumeSpace(Space.Capacity, Space.FreeSpace);
      Parent := Target.Parent;
      while Parent <> nil do
      begin
        Parent.Recalculate;
        Parent := Parent.Parent
      end;
    end;
  end;
  RestoreView(View);
  // The result replaced any preview of this root.
  FProvisional.Remove(RootKey(Job.RootPath));
  ResolvePending(Job.RootPath, True);
end;

function TFormMain.IsProvisional(Root: TDiskNode): Boolean;
begin
  Result := FProvisional.ContainsKey(RootKey(Root.Path));
end;

procedure TFormMain.ResolvePending(const RootPath: string; Final: Boolean);
var
  Pending: TDiskNode;
begin
  // A location opened while it was scanning now has something to show. A
  // preview may not reach it yet; the final result settles it either way.
  if (FPendingRoot = '') or not SamePath(FPendingRoot, RootPath) then
    Exit;
  Pending := FindScanned(FPendingPath);
  if ((Pending = nil) or not Pending.IsFolder) and not Final then
    Exit;
  FPendingRoot := '';
  FPendingPath := '';
  if (Pending <> nil) and Pending.IsFolder then
  begin
    FFocus := Pending;
    FVolumeOverview := FFocus.IsVolume and FPendingOverview and (FFocus.Capacity > 0);
    FSelected := nil;
  end;
end;

procedure TFormMain.RequestPreviews;
const
  Interval = 100;
var
  Job: TScanJob;
  Now: UInt64;
  Delay: Int64;
  Focus: string;
begin
  if not MenuItemLiveScan.IsChecked then
    Exit;
  Now := TThread.GetTickCount64;
  for Job in ViewJobs do
    if (Job.Worker <> nil) and (Job.Worker.SourceRoot = nil) and not Job.Worker.Done then
    begin
      // Every tenth of a second, unless the last preview took more than a
      // third of that to build and show: a big tree then refreshes less
      // often, so previews never take over the scan or the UI.
      Delay := Max(Int64(Interval), 3 * Job.PreviewCost);
      // Timer ticks and the tick count are both coarse: allow half an
      // interval, or a 100 ms delay would often wait for a second tick.
      if (Job.PreviewTick = 0) or (Int64(Now - Job.PreviewTick) + Interval div 2 >= Delay) then
      begin
        // The preview covers what this view shows of the scan: the location
        // being opened, or the focused folder inside it, else its root.
        Focus := '';
        if FPendingRoot <> '' then
          Focus := FPendingPath
        else if (FFocus <> nil) and PathWithin(FFocus.Path, Job.RootPath) then
          Focus := FFocus.Path;
        Job.Worker.RequestPreview(Focus);
        Job.PreviewTick := Now;
      end;
    end;
end;

procedure TFormMain.InstallPreview(Job: TScanJob; Preview: TDiskNode);
var
  View: TSavedView;
  Old, Container: TDiskNode;
begin
  Old := FindRoot(Job.RootPath);
  if (Old <> nil) and not IsProvisional(Old) then
  begin
    // Complete results never give way to a preview.
    Preview.Free;
    Exit;
  end;
  View := SaveView;
  ResetViewCaches;
  if Old <> nil then
  begin
    Container := Old.Parent;
    Container.Children.Remove(Old);
    Container.Recalculate;
  end;
  Container := ContainerFor(Job.RootPath);
  try
    InsertRoot(Container, Preview);
  except
    Preview.Free;
    raise
  end;
  Container.Recalculate;
  FProvisional.AddOrSetValue(RootKey(Job.RootPath), True);
  RestoreView(View);
  ResolvePending(Job.RootPath, False);
end;

function TFormMain.SaveView: TSavedView;
begin
  Result.HasFocus := FFocus <> nil;
  Result.Focus := '';
  if FFocus <> nil then
    Result.Focus := FFocus.Path;
  Result.Selected := PathOfNode(FSelected);
  Result.Context := PathOfNode(FContext);
end;

function TFormMain.FindNearest(const Path: string): TDiskNode;
var
  P: string;
begin
  // A folder that disappeared, or is not in a preview, falls back to its
  // nearest scanned ancestor.
  P := Path;
  Result := FindScanned(P);
  while (Result = nil) and (ExtractFileDir(P) <> P) do
  begin
    P := ExtractFileDir(P);
    Result := FindScanned(P);
  end;
  if (Result = nil) or not Result.IsFolder then
    Result := FRoot;
end;

procedure TFormMain.RestoreView(const View: TSavedView);
begin
  FFocus := nil;
  if View.HasFocus then
    FFocus := FindNearest(View.Focus);
  FVolumeOverview := FVolumeOverview and (FFocus <> nil) and FFocus.IsVolume and (FFocus.Capacity > 0);
  FSelected := nil;
  if View.Selected <> '' then
    FSelected := FindScanned(View.Selected);
  FContext := nil;
  if View.Context <> '' then
    FContext := FindScanned(View.Context);
end;

procedure TFormMain.ResetViewCaches;
begin
  // Release every borrower before the tree changes (see TDiskViewModel).
  FChartView.Reset;
  FHover := nil;
  FHoverKind := chkNone;
  FViewNodes := nil;
  ClearFolderRows;
  if (FSelected is TSmallFileGroup) or (FSelected is TUnscannedSpace) then
    FSelected := nil;
  FViewData.Clear;
end;

procedure TFormMain.RefreshView;
begin
  ShowNode(nil);
  UpdateButtons;
  PaintBoxChart.Repaint;
end;

function TFormMain.ViewJobs: TArray<TScanJob>;
var
  Job: TScanJob;
  Root: TDiskNode;
begin
  Result := nil;
  if FPendingRoot <> '' then
  begin
    Job := FScans.Find(FPendingRoot);
    if Job <> nil then
      Result := [Job];
  end
  else if FFocus = FRoot then
  begin
    // The summary waits for every included drive.
    for Job in FScans.Jobs do
      if ContainerFor(Job.RootPath) = FRoot then
        Result := Result + [Job];
  end
  else
  begin
    Root := RootOf(FFocus);
    if Root <> nil then
    begin
      Job := FScans.Find(Root.Path);
      if Job <> nil then
        Result := [Job];
    end;
  end;
end;

function TFormMain.ViewBusy: Boolean;
begin
  Result := Length(ViewJobs) > 0;
end;

function TFormMain.ViewBlank: Boolean;
begin
  // While scanning, the view shows what is known so far (a preview, or the
  // results being refreshed) unless the user turned that off or nothing has
  // arrived yet.
  Result := ViewBusy and (not MenuItemLiveScan.IsChecked or (FPendingRoot <> '') or (FFocus = nil) or
    (FFocus.Children = nil) or (FFocus.Children.Count = 0));
end;

function TFormMain.ViewScanStatus: TScanStatus;
var
  Job, Holder: TScanJob;
  Node: TDiskNode;
  Current: string;
  Visited, Processed, Expected, Done, Total: UInt64;
  Skipped: Integer;
begin
  Result := Default(TScanStatus);
  Done := 0;
  Total := 0;
  // The summary's bar also counts the drives that have already finished.
  if (FPendingRoot = '') and (FFocus = FRoot) then
    for Node in FRoot.Children do
      if FScans.Find(Node.Path) = nil then
      begin
        Expected := Node.Size;
        if Node.Capacity > 0 then
          Expected := Node.Capacity - Node.FreeSpace;
        Inc(Done, Expected);
        Inc(Total, Expected);
        Inc(Result.Visited, Node.Files);
      end;
  for Job in ViewJobs do
    if Job.Worker <> nil then
    begin
      Job.Worker.Progress(Current, Visited, Skipped);
      Job.Worker.ProgressBytes(Processed, Expected);
      if Expected = 0 then
        Expected := Job.Expected;
      if Processed > Expected then
        Processed := Expected;
      Inc(Done, Processed);
      Inc(Total, Expected);
      Inc(Result.Visited, Visited);
      if Current = '' then
        Current := Job.Path;
      if Result.Current = '' then
        Result.Current := Current;
    end
    else
    begin
      Inc(Total, Job.Expected);
      Holder := FScans.LaneHolder(Job.Lane);
      if (Result.Waiting = '') and (Holder <> nil) then
        Result.Waiting := Holder.Path;
    end;
  if Total > 0 then
    Result.Position := Min(127, Integer(Trunc(128 * (Done / Total))));
end;

function TFormMain.ViewSkipped: Integer;
var
  Root: TDiskNode;
  Count: Integer;
begin
  Result := 0;
  if FFocus = FRoot then
  begin
    for Root in FRoot.Children do
      if FSkippedByRoot.TryGetValue(RootKey(Root.Path), Count) then
        Inc(Result, Count);
  end
  else
  begin
    Root := RootOf(FFocus);
    if (Root <> nil) and FSkippedByRoot.TryGetValue(RootKey(Root.Path), Count) then
      Result := Count;
  end;
end;

procedure TFormMain.StopViewScans;
var
  Job: TScanJob;
begin
  // Only the scans behind this view stop; other locations keep scanning.
  for Job in ViewJobs do
    FScans.Cancel(Job);
  FPendingRoot := '';
  FPendingPath := '';
  TimerPoll.Enabled := True;
  RefreshView;
end;

procedure TFormMain.SetPending(const Path, RootPath: string; Overview: Boolean);
var
  View: TViewPath;
begin
  if (FPendingRoot = '') and (FFocus <> nil) then
  begin
    View.Path := FFocus.Path;
    View.Overview := FVolumeOverview;
    FHistory.Add(View);
  end;
  FPendingPath := Path;
  FPendingRoot := RootPath;
  VertScrollBoxFolders.ViewportPosition := PointF(0, 0);
  FPendingOverview := Overview;
  FSelected := nil;
  FHover := nil;
  FHoverKind := chkNone;
  RefreshView;
end;

procedure TFormMain.OpenLocation(const Path: string);
var
  Node: TDiskNode;
  Job: TScanJob;
  Overview: Boolean;
begin
  Overview := IsDriveRoot(Path);
  Node := FindScanned(Path);
  if (Node <> nil) and Node.IsFolder then
  begin
    // Cached results show at once; during a rescan the view shows its
    // progress and falls back to these results if it is stopped.
    FocusNode(Node, True, Overview);
    Exit;
  end;
  for Job in FScans.Jobs do
    if PathWithin(Path, Job.RootPath) then
    begin
      SetPending(Path, Job.RootPath, Overview);
      Exit;
    end;
  Job := EnqueueScan(Path, Path);
  SetPending(Path, Job.RootPath, Overview);
end;

procedure TFormMain.ShowSummary;
begin
  ScanDrives(False);
  FocusNode(FRoot);
end;

procedure TFormMain.ScanDrives(Refresh: Boolean);
var
  P: string;
begin
  // Queue included drives without results, or every idle one on refresh.
  for P in FDrives do
    if FIncluded[P] and (FScans.Find(P) = nil) and (Refresh or (FindRoot(P) = nil)) then
      EnqueueScan(P, P);
end;

procedure TFormMain.RescanRecycleBins;
var
  Container, Root, Bin: TDiskNode;
begin
  // Emptying the bin changes only each drive's $Recycle.Bin and free space.
  for Container in TArray<TDiskNode>.Create(FRoot, FOther) do
    for Root in Container.Children do
      if Root.IsVolume and (FScans.Find(Root.Path) = nil) then
      begin
        Bin := FindPath(Root, IncludeTrailingPathDelimiter(Root.Path) + '$Recycle.Bin');
        if Bin <> nil then
          EnqueueScan(Root.Path, Bin.Path);
      end;
  RefreshView;
end;

function TFormMain.FindPath(Node: TDiskNode; const Path: string): TDiskNode;
var
  C: TDiskNode;
begin
  Result := nil;
  if Node = nil then
    Exit;
  if SameText(ExcludeTrailingPathDelimiter(Node.Path), ExcludeTrailingPathDelimiter(Path)) then
    Exit(Node);
  if Node.Children = nil then
    Exit;
  for C in Node.Children do
    if C.IsFolder and ((C.Path = '') or Path.StartsWith(IncludeTrailingPathDelimiter(C.Path), True) or
      SameText(ExcludeTrailingPathDelimiter(C.Path), ExcludeTrailingPathDelimiter(Path))) then
    begin
      Result := FindPath(C, Path);
      if Result <> nil then
        Exit
    end;
end;

procedure TFormMain.TimerPollTimer(Sender: TObject);
var
  Job: TScanJob;
  Errors: TStringList;
  Error: string;
  Changed: Boolean;
  Preview: TDiskNode;
  BuildTime: Int64;
  Shown: TArray<TScanJob>;
  Clock: TStopwatch;
begin
  Errors := TStringList.Create;
  try
    FScans.Reap;
    Changed := False;
    repeat
      Job := FScans.TakeFinished;
      if Job <> nil then
      try
        MergeJob(Job, Errors);
        Changed := True;
      finally
        Job.Free;
      end;
    until Job = nil;
    if (FPendingRoot <> '') and (FScans.Find(FPendingRoot) = nil) then
    begin
      FPendingRoot := '';
      FPendingPath := '';
      Changed := True;
    end;
    Shown := nil;
    Clock := TStopwatch.StartNew;
    for Job in FScans.Jobs do
      if Job.Worker <> nil then
      begin
        Preview := Job.Worker.TakePreview(BuildTime);
        if Preview <> nil then
        begin
          InstallPreview(Job, Preview);
          Job.PreviewCost := BuildTime;
          Shown := Shown + [Job];
          Changed := True;
        end;
      end;
    ArrangeRoots;
    FScans.StartReady(CreateScanWorker);
    if FScans.Idle then
      TimerPoll.Enabled := False;
    if Changed then
      RefreshView
    else
      UpdateScanStatus;
    // Showing a preview is part of its cost, so measure through the redraw.
    for Job in Shown do
      Inc(Job.PreviewCost, Clock.ElapsedMilliseconds);
    RequestPreviews;
    // Shown last: the modal loop lets this timer run again meanwhile.
    for Error in Errors do
      ShowScannerDialog(Self, Translate('Scan error'), Error, sdkError);
  finally
    Errors.Free;
  end;
end;

procedure TFormMain.ShowNode(Node: TDiskNode);
begin
  if Node = nil then
    Node := FSelected;
  if Node = nil then
    Node := FFocus;
  // A location still waiting for its first results has no details yet.
  if FPendingRoot <> '' then
    Node := nil;
  UpdateSelection(Node);
end;

function TFormMain.RootNeedsZoom(Node: TDiskNode): Boolean;
var
  Sectors, Bytes, FreeClusters, Clusters: DWORD;
  Cluster: UInt64;
begin
  Result := False;
  if (Node = nil) or not Node.IsVolume or (Node.UsedArea = nil) then
    Exit;
  Cluster := 4096;
  if GetDiskFreeSpace(PChar(Node.Path), Sectors, Bytes, FreeClusters, Clusters) then
    Cluster := UInt64(Sectors) * Bytes;
  // Original Scanner only expands the disk root when less than about 2/3
  // of Windows usage could be enumerated (with an eight-cluster tolerance).
  Result := Node.Size + 8.0 * Cluster < Node.UsedArea.Size * (2.0 / 3.0);
end;

procedure TFormMain.FocusNode(Node: TDiskNode; Remember, Overview: Boolean);
var
  View: TViewPath;
begin
  if (Node <> nil) and Node.IsUsed then
  begin
    if FFocus = FRoot then
      Exit;
    Node := Node.Parent;
    Overview := not RootNeedsZoom(Node);
  end;
  if (Node = nil) or not Node.IsFolder then
    Exit;
  Overview := Overview and Node.IsVolume and (Node.Capacity > 0);
  // SetPending already remembered the view that was left.
  if Remember and (FPendingRoot = '') and (FFocus <> nil) and
    ((FFocus <> Node) or (FVolumeOverview <> Overview)) then
  begin
    View.Path := FFocus.Path;
    View.Overview := FVolumeOverview;
    FHistory.Add(View)
  end;
  // Navigation never cancels scans; they continue in the background.
  FPendingRoot := '';
  FPendingPath := '';
  // A newly opened folder's list starts at the top; refreshes keep the offset.
  if Node <> FFocus then
    VertScrollBoxFolders.ViewportPosition := PointF(0, 0);
  FFocus := Node;
  FSelected := nil;
  FVolumeOverview := Overview;
  FHover := nil;
  FHoverKind := chkNone;
  FChartView.Reset;
  ShowNode(nil);
  UpdateButtons;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.UpdateScanStatus;
var
  Status: TScanStatus;
begin
  LayoutScanStatus.Visible := ViewBusy;
  if not LayoutScanStatus.Visible then
    Exit;
  Status := ViewScanStatus;
  ProgressBarScan.Value := Status.Position;
  if Status.Current <> '' then
  begin
    LabelScan.Text := Status.Current;
    LabelStatus.Text := Translate('Scanning…  Esc — stop');
  end
  else
  begin
    // Nothing behind this view is reading yet: its device is busy elsewhere.
    LabelScan.Text := Translate('Queued…');
    if Status.Waiting <> '' then
      LabelScan.Text := Format(Translate('Queued after %s'), [Status.Waiting]);
    LabelStatus.Text := Translate('Queued…  Esc — stop');
  end;
  LabelFilesSummary.Text := FileCountText(Status.Visited);
end;

procedure TFormMain.UpdateButtons;
var
  ActivePath, Drive: string;
  Item: TFmxObject;
begin
  SpeedButtonBack.Enabled := (FHistory <> nil) and (FHistory.Count > 0);
  SpeedButtonUp.Enabled := (FPendingRoot = '') and (FFocus <> nil) and (FFocus.ParentFolder <> nil);
  ActivePath := '';
  if FPendingRoot <> '' then
    ActivePath := FPendingPath
  else if FFocus <> nil then
    ActivePath := FFocus.Path;
  Drive := ExtractFileDrive(ActivePath);
  if Drive <> '' then
    Drive := IncludeTrailingPathDelimiter(Drive);
  for Item in VertScrollBoxDrives.Content.Children do
    if Item is TFrameDriveButton then
      TFrameDriveButton(Item).SpeedButtonDrive.IsPressed := (Drive <> '') and
        SameText(TFrameDriveButton(Item).SpeedButtonDrive.TagString, Drive);
  SpeedButtonSummary.IsPressed := ActivePath = '';
  if ViewBusy then
  begin
    SpeedButtonScan.Hint := Translate('Stop scanning (Esc)');
    PathScanIcon.Data.Assign(PathStopIconTemplate.Data);
    LabelScanText.Text := Translate('Stop')
  end
  else
  begin
    SpeedButtonScan.Hint := Translate('Rescan folder (F5)');
    PathScanIcon.Data.Assign(PathScanIconTemplate.Data);
    LabelScanText.Text := Translate('Scan');
  end;
  UpdateDashboard;
end;

procedure TFormMain.BuildDriveButtons;
var
  DriveButton: TFrameDriveButton;
  Item: TFmxObject;
  i: Integer;
begin
  ReleaseChildCapture(VertScrollBoxDrives.Content);
  while VertScrollBoxDrives.Content.ChildrenCount > 0 do
  begin
    Item := VertScrollBoxDrives.Content.Children[0];
    if Item is TFrameDriveButton then
    begin
      DriveButton := TFrameDriveButton(Item);
      DriveButton.SpeedButtonDrive.OnClick := nil;
      DriveButton.SpeedButtonDrive.OnMouseDown := nil;
      DriveButton.SpeedButtonDrive.OnDblClick := nil;
      DriveButton.SpeedButtonDrive.TagString := '';
    end;
    Item.Release;
  end;
  for i := 0 to High(FDrives) do
  begin
    DriveButton := TFrameDriveButton.Create(Self);
    DriveButton.Name := '';
    DriveButton.Parent := VertScrollBoxDrives;
    DriveButton.Position.Y := i * DriveButton.Height;
    DriveButton.LoadDrive(FDrives[i]);
    DriveButton.SpeedButtonDrive.OnClick := SpeedButtonDriveClick;
    DriveButton.SpeedButtonDrive.OnMouseDown := SpeedButtonDriveMouseDown;
  end;
  ApplyThemeTo(VertScrollBoxDrives.Content);
  FormMainResize(nil);
end;

procedure TFormMain.SpeedButtonDriveClick(Sender: TObject);
begin
  // Cached results show at once; Scan (F5) refreshes them on request.
  OpenLocation(TControl(Sender).TagString);
end;

procedure TFormMain.SpeedButtonDriveMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  i, Detected: Integer;
  Automatic: Boolean;
  Item: TMenuItem;
  Point: TPointF;
begin
  if Button <> TMouseButton.mbRight then
    Exit;
  FDriveContext := TControl(Sender).TagString;
  MenuItemInclude.IsChecked := FIncluded[FDriveContext];
  Automatic := not FIni.ValueExists('PhysicalDevice', FDriveContext);
  Detected := VolumeDisk(FDriveContext);
  for i := 0 to MenuItemPhysical.ItemsCount - 1 do
  begin
    Item := MenuItemPhysical.Items[i];
    if Item.Tag < 0 then
    begin
      Item.Text := Translate('Automatic');
      if FSolidState[FDriveContext] then
        Item.Text := Format('%s (%d, SSD)', [Item.Text, Detected])
      else if Detected >= 0 then
        Item.Text := Format('%s (%d)', [Item.Text, Detected]);
      Item.IsChecked := Automatic;
    end
    else
      Item.IsChecked := not Automatic and (Item.Tag = FDevices[FDriveContext]);
  end;
  Point := TControl(Sender).LocalToScreen(PointF(X, Y));
  PopupMenuDrive.Popup(Point.X, Point.Y);
end;

procedure TFormMain.MenuItemIncludeClick(Sender: TObject);
begin
  if FDriveContext = '' then
    Exit;
  FIncluded[FDriveContext] := not FIncluded[FDriveContext];
  FIni.WriteBool('Summary', FDriveContext, FIncluded[FDriveContext]);
  FIni.UpdateFile;
  // Results are kept; the drive only moves in or out of the summary.
  ScanDrives(False);
  ArrangeRoots;
  RefreshView;
end;

procedure TFormMain.MenuItemPhysicalClick(Sender: TObject);
begin
  if FDriveContext = '' then
    Exit;
  if TMenuItem(Sender).Tag < 0 then
  begin
    FIni.DeleteKey('PhysicalDevice', FDriveContext);
    FDevices[FDriveContext] := VolumeDisk(FDriveContext);
  end
  else
  begin
    FDevices[FDriveContext] := TMenuItem(Sender).Tag;
    FIni.WriteInteger('PhysicalDevice', FDriveContext, TMenuItem(Sender).Tag);
  end;
  FIni.UpdateFile;
  // A queued scan of this drive joins its new device's queue; a running one
  // keeps its device until it finishes.
  for var Job in FScans.Jobs do
    if (Job.Worker = nil) and SameText(IncludeTrailingPathDelimiter(ExtractFileDrive(Job.RootPath)), FDriveContext) then
      Job.Lane := LaneFor(Job.RootPath);
  FScans.StartReady(CreateScanWorker);
  UpdateScanStatus;
end;

procedure TFormMain.PaintBoxChartPaint(Sender: TObject; Canvas: TCanvas);
begin
  if FChartView <> nil then
    FChartView.Paint(Canvas, PaintBoxChart.LocalRect, ChartContext);
end;

procedure TFormMain.PaintBoxChartMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  N: TDiskNode;
  Hit: TChartHit;
begin
  FHoverPoint := PointF(X, Y);
  Hit := FChartView.HitTest(PaintBoxChart.LocalRect, ChartContext, X, Y);
  N := Hit.Node;
  if (N = FHover) and (Hit.Kind = FHoverKind) then
  begin
    if N <> nil then
      PaintBoxChart.Repaint;
    Exit;
  end;
  FHover := N;
  FHoverKind := Hit.Kind;
  if N <> nil then
    ShowNode(N)
  else
    ShowNode(nil);
  if (N <> nil) and (((N.IsFolder or N.IsUsed) and (N <> FFocus)) or
    (Hit.Kind = chkParent)) then
    PaintBoxChart.Cursor := crHandPoint
  else
    PaintBoxChart.Cursor := crDefault;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.PaintBoxChartMouseLeave(Sender: TObject);
begin
  FHover := nil;
  FHoverKind := chkNone;
  if not ViewBlank then
    ShowNode(nil);
  PaintBoxChart.Repaint
end;

procedure TFormMain.PaintBoxChartMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  N: TDiskNode;
  Hit: TChartHit;
  Item: TFmxObject;
begin
  if ViewBlank or (FFocus = nil) then
    Exit;
  Hit := FChartView.HitTest(PaintBoxChart.LocalRect, ChartContext, X, Y);
  if (Button = TMouseButton.mbLeft) and (Hit.Kind = chkParent) then
  begin
    SpeedButtonUpClick(SpeedButtonUp);
    Exit;
  end;
  N := Hit.Node;
  if N = nil then
    Exit;
  if Button = TMouseButton.mbLeft then
  begin
    if N.IsFolder then
    begin
      if N <> FFocus then
        FocusNode(N);
    end
    else
    begin
      FSelected := N;
      UpdateSelection(N);
      if VertScrollBoxFolders.Content.ChildrenCount > 0 then
        for Item in VertScrollBoxFolders.Content.Children do
          if Item is TFrameFolderItem then
            TFrameFolderItem(Item).SpeedButtonFolderItem.IsPressed := TFrameFolderItem(Item).Node = N;
      PaintBoxChart.Repaint;
    end;
  end
  else if Button = TMouseButton.mbRight then
    PopupNode(N, PaintBoxChart.LocalToScreen(PointF(X, Y)));
end;

procedure TFormMain.Rescan(Node: TDiskNode);
var
  Root: TDiskNode;
begin
  if (Node = nil) or (Node.Path = '') then
  begin
    ScanDrives(True);
    if FFocus = nil then
      FocusNode(FRoot)
    else
      RefreshView;
    Exit
  end;
  Root := RootOf(Node);
  if Root = nil then
    Exit;
  EnqueueScan(Root.Path, Node.Path);
  RefreshView;
end;

procedure TFormMain.ApplicationException(Sender: TObject; E: Exception);
begin
  ShowScannerException(Self, E);
end;

procedure TFormMain.ExecuteUICommand(Sender: TObject);
var
  View: TViewPath;
  Op: Integer;
  Status: HRESULT;
begin
  Op := TFmxObject(Sender).Tag;
  case Op of
    1:
      OpenTarget('control.exe', 'appwiz.cpl');
    2:
      if ShowScannerDialog(Self, Translate('Empty Recycle Bin'), Translate('Permanently empty the Recycle Bin?'), sdkConfirmation) = mrYes then
      begin
        Status := SHEmptyRecycleBin(FormToHWND(Self), nil, SHERB_NOCONFIRMATION or SHERB_NOPROGRESSUI);
        if Succeeded(Status) then
          RescanRecycleBins
        else if (Status <> HRESULT($800704C7)) and (Status <> E_ABORT) then
          FileActionError(Translate('Empty Recycle Bin'), '', SysErrorMessage(Status and $FFFF) + ' (0x' + IntToHex(Cardinal(Status), 8) + ')');
      end;
    3:
      if (FPendingRoot = '') and (FFocus <> nil) and (FFocus.ParentFolder <> nil) then
        FocusNode(FFocus.ParentFolder, True, FFocus.ParentFolder.IsVolume and not RootNeedsZoom(FFocus.ParentFolder));
    4:
      if FHistory.Count > 0 then
      begin
        View := FHistory.Last;
        FHistory.Delete(FHistory.Count - 1);
        FocusNode(FindNearest(View.Path), False, View.Overview)
      end;
    5:
      Rescan(FFocus);
    8:
      ShowSummary;
  end;
end;

procedure TFormMain.ExecuteNodeAction(Sender: TObject);
begin
  if FContext = nil then
    Exit;
  case TMenuItem(Sender).Tag of
    1:
      begin
        FContext.Hidden := not FContext.Hidden;
        FChartView.Reset;
        BuildFolderRows;
        PaintBoxChart.Repaint
      end;
    2:
      FocusNode(FContext);
    3:
      Rescan(FContext);
    4:
      if FContext.Path <> '' then
        OpenTarget(FContext.Path);
    5:
      RemoveNode(FContext, True);
    6:
      RemoveNode(FContext, False);
  end;
end;

procedure TFormMain.RemoveNode(Node: TDiskNode; Recycle: Boolean);
var
  Operation: TSHFileOpStruct;
  NodePath, FromPath, Question, ParentPath, Details: string;
  Status: Integer;
  Root: TDiskNode;
begin
  if (Node = nil) or (Node.Path = '') or Node.IsVolume then
    Exit;
  // Background merges may replace nodes while the dialog is open; keep the path.
  NodePath := Node.Path;
  if Recycle then
    Question := Translate('Move to the Recycle Bin?')
  else
    Question := Translate('Permanently remove?');
  if ShowScannerDialog(Self, Translate('Confirm action'), Question + sLineBreak + NodePath, sdkConfirmation) <> mrYes then
    Exit;
  ParentPath := ExtractFileDir(NodePath);
  FromPath := NodePath + #0 + #0;
  FillChar(Operation, SizeOf(Operation), 0);
  Operation.Wnd := FormToHWND(Self);
  Operation.wFunc := FO_DELETE;
  Operation.pFrom := PChar(FromPath);
  Operation.fFlags := FOF_NOCONFIRMATION or FOF_NOERRORUI;
  if Recycle then
    Operation.fFlags := Operation.fFlags or FOF_ALLOWUNDO;
  Status := SHFileOperation(Operation);
  if Operation.fAnyOperationsAborted or (Status = ERROR_CANCELLED) or (Status = $75) then
    Exit;
  if Status = 0 then
  begin
    // A removed chosen folder leaves nothing to rescan; drop its results.
    Root := FindRoot(NodePath);
    if Root = nil then
      Rescan(FindScanned(ParentPath))
    else if not FScans.Borrows(Root.Path) then
    begin
      DropRoot(Root);
      RefreshView;
    end;
  end
  else
  begin
    case Status of
      $71:
        Details := Translate('Source and destination are the same.');
      $74:
        Details := Translate('A root directory cannot be removed.');
      $78:
        Details := Translate('Access denied.');
      $79:
        Details := Translate('The path is too long for this operation.');
    else
      Details := SysErrorMessage(Status);
    end;
    FileActionError(Question, NodePath, Details + ' (' + IntToStr(Status) + ')');
  end;
end;

procedure TFormMain.FileActionError(const Action, Target, Details: string);
begin
  ShowScannerDialog(Self, Action, Trim(Target + sLineBreak + Details), sdkError);
end;

procedure TFormMain.OpenTarget(const Target, Parameters: string);
var
  Info: TShellExecuteInfo;
  ErrorCode: DWORD;
begin
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := SEE_MASK_FLAG_NO_UI;
  Info.Wnd := FormToHWND(Self);
  Info.lpVerb := 'open';
  Info.lpFile := PChar(Target);
  if Parameters <> '' then
    Info.lpParameters := PChar(Parameters);
  Info.nShow := SW_SHOWNORMAL;
  if not ShellExecuteEx(@Info) then
  begin
    ErrorCode := GetLastError;
    if ErrorCode <> ERROR_CANCELLED then
      FileActionError(Translate('Could not open'), Target, SysErrorMessage(ErrorCode));
  end;
end;

procedure TFormMain.ChooseFolder;
var
  Folder: string;
begin
  Folder := FStartFolder;
  if SelectDirectory(Translate('Select folder'), '', Folder) then
  begin
    FStartFolder := Folder;
    OpenLocation(Folder)
  end;
end;

procedure TFormMain.SaveLog;
var
  Log: TStringList;
  Current: string;
  Count: UInt64;
  Skipped: Integer;
  Job: TScanJob;
  Container, Root: TDiskNode;
begin
  Log := TStringList.Create;
  try
    Log.Add('Scanner FMX - ' + DateTimeToStr(Now));
    for Job in ViewJobs do
      if Job.Worker <> nil then
      begin
        Job.Worker.Progress(Current, Count, Skipped);
        Log.Add(Current);
        Log.Add(Format(Translate('Files: %s'), [UIntToStr(Count)]));
        Log.Add(Format(Translate('Skipped: %s'), [Skipped.ToString]))
      end;
    for Container in TArray<TDiskNode>.Create(FRoot, FOther) do
      for Root in Container.Children do
        Log.Add(Format(Translate('Scan: %s'), [Root.Path]));
    if FFocus <> nil then
    begin
      Log.Add(Format(Translate('Focus: %s'), [FFocus.Path]));
      Log.Add(Format(Translate('Allocated: %s'), [UIntToStr(FFocus.Size)]));
      Log.Add(Format(Translate('Files: %s'), [UIntToStr(FFocus.Files)]))
    end;
    Log.SaveToFile(TPath.Combine(TPath.GetDocumentsPath, 'Scanner.log'), TEncoding.UTF8);
    ShowScannerDialog(Self, Translate('Log saved'), TPath.Combine(TPath.GetDocumentsPath, 'Scanner.log'));
  finally
    Log.Free
  end;
end;

procedure TFormMain.FormMainKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('O')) then
  begin
    ChooseFolder;
    Key := 0
  end
  else if Key = vkF5 then
  begin
    if not ViewBusy then
      Rescan(FFocus);
    Key := 0
  end
  else if (Key = vkBack) or ((ssAlt in Shift) and (Key = vkLeft)) then
  begin
    SpeedButtonBackClick(SpeedButtonBack);
    Key := 0
  end
  else if (ssAlt in Shift) and (Key = vkUp) then
  begin
    SpeedButtonUpClick(SpeedButtonUp);
    Key := 0
  end
  else if (Key = vkEscape) and ViewBusy then
  begin
    StopViewScans;
    LabelStatus.Text := Translate('Scan stopped')
  end
  else if UpCase(KeyChar) = 'L' then
    SaveLog;
end;

function TFormMain.ThemeColor(const Role: string): TAlphaColor;
var
  Resource: TFmxObject;
  Book: TStyleBook;
begin
  Book := StyleBookLight;
  if FDarkTheme then
    Book := StyleBookDark;
  Resource := Book.Style.FindStyleResource('color.' + Role);
  if not (Resource is TColorObject) then
    raise EInvalidOperation.Create('Missing theme color: ' + Role);
  Result := TColorObject(Resource).Color;
end;

procedure TFormMain.ApplyThemeTo(ObjectRoot: TFmxObject);
var
  Child: TFmxObject;
  Role: string;
  Color: TAlphaColor;
begin
  if (ObjectRoot is TFrameFolderItem) and (TFrameFolderItem(ObjectRoot).Node <> nil) then
    TFrameFolderItem(ObjectRoot).SetCategoryColor(NodeColor(TFrameFolderItem(ObjectRoot).Node));
  Role := ObjectRoot.TagString;
  if (Role = '') and ObjectRoot.StyleName.StartsWith('theme.') then
    Role := Copy(ObjectRoot.StyleName, 7, MaxInt);
  if (Role = 'icon') or (Role = 'text') then
    Role := 'text';
  if (Role = 'surface') or (Role = 'sidebar') or (Role = 'panel') or
    (Role = 'elevated') or (Role = 'border') or (Role = 'text') or
    (Role = 'muted') or (Role = 'track') or (Role = 'selected') or
    (Role = 'accent') or (Role = 'teal') or (Role = 'green') then
  begin
    Color := ThemeColor(Role);
    if ObjectRoot is TShape then
      TShape(ObjectRoot).Fill.Color := Color
    else if ObjectRoot is TLabel then
      TLabel(ObjectRoot).TextSettings.FontColor := Color;
    if (ObjectRoot is TRectangle) and (TRectangle(ObjectRoot).Stroke.Kind <> TBrushKind.None) then
      TRectangle(ObjectRoot).Stroke.Color := FBorderColor;
  end;
  if ObjectRoot.ChildrenCount > 0 then
    for Child in ObjectRoot.Children do
      if not (Child is TStyleBook) then
        ApplyThemeTo(Child);
end;

procedure TFormMain.ApplyTheme(Dark: Boolean);
var
  DarkCaption: BOOL;
  CaptionColor, CaptionTextColor, BorderColor: COLORREF;
  Window: HWND;

  function NativeColor(Color: TAlphaColor): COLORREF;
  begin
    Result := RGB(TAlphaColorRec(Color).R, TAlphaColorRec(Color).G, TAlphaColorRec(Color).B);
  end;

begin
  FDarkTheme := Dark;
  if Dark then
    StyleBook := StyleBookDark
  else
    StyleBook := StyleBookLight;
  FBackground := ThemeColor('surface');
  FPanelColor := ThemeColor('panel');
  FTextColor := ThemeColor('text');
  FMutedColor := ThemeColor('muted');
  FBorderColor := ThemeColor('border');
  Fill.Color := FBackground;
  Fill.Kind := TBrushKind.Solid;
  DarkCaption := Dark;
  Window := FormToHWND(Self);
  // Windows 10 supports the immersive title bar; Windows 11 also accepts colors.
  // Older versions ignore unsupported DWM attributes and keep the native frame.
  DwmSetWindowAttribute(Window, DWMWA_USE_IMMERSIVE_DARK_MODE, @DarkCaption, SizeOf(DarkCaption));
  CaptionColor := NativeColor(ThemeColor('sidebar'));
  CaptionTextColor := NativeColor(FTextColor);
  BorderColor := NativeColor(FBorderColor);
  DwmSetWindowAttribute(Window, DWMWA_CAPTION_COLOR, @CaptionColor, SizeOf(CaptionColor));
  DwmSetWindowAttribute(Window, DWMWA_TEXT_COLOR, @CaptionTextColor, SizeOf(CaptionTextColor));
  DwmSetWindowAttribute(Window, DWMWA_BORDER_COLOR, @BorderColor, SizeOf(BorderColor));
  ApplyThemeTo(Self);
  LabelScanText.TextSettings.FontColor := TAlphaColors.White;
  PathScanIcon.Fill.Color := TAlphaColors.White;
  if Dark then
  begin
    LabelThemeText.Text := Translate('Light theme');
    PathThemeIcon.Data.Assign(PathSunIconTemplate.Data);
  end
  else
  begin
    LabelThemeText.Text := Translate('Dark theme');
    PathThemeIcon.Data.Assign(PathMoonIconTemplate.Data);
  end;
  SpeedButtonTheme.Hint := LabelThemeText.Text;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.SpeedButtonThemeClick(Sender: TObject);
begin
  ApplyTheme(not FDarkTheme);
  FIni.WriteBool('Appearance', 'DarkTheme', FDarkTheme);
  FIni.UpdateFile;
end;

function TFormMain.FormatBytes(Value: UInt64): string;
begin
  Result := FormatDiskBytes(Value);
end;

function TFormMain.NodeTitle(Node: TDiskNode): string;
begin
  Result := DiskNodeTitle(Node);
end;

function TFormMain.FolderCount(Node: TDiskNode): UInt64;
begin
  Result := DiskFolderCount(Node);
end;

function TFormMain.NodeColor(Node: TDiskNode; Depth: Integer): TAlphaColor;
begin
  Result := ChartNodeColor(FViewData, FFocus, Node, Depth, ChartTheme);
end;

function TFormMain.ChartContext: TChartContext;
begin
  Result := Default(TChartContext);
  Result.Data := FViewData;
  Result.Focus := FFocus;
  Result.Hover := FHover;
  Result.Selected := FSelected;
  Result.Nodes := FViewNodes;
  Result.HoverPoint := FHoverPoint;
  Result.HoverKind := FHoverKind;
  Result.Busy := ViewBlank;
  Result.Theme := ChartTheme;
end;

function TFormMain.ChartTheme: TChartTheme;
begin
  Result.Background := FBackground;
  Result.Text := FTextColor;
  Result.Muted := FMutedColor;
  Result.Border := FBorderColor;
  Result.Elevated := ThemeColor('elevated');
  if FDarkTheme then
  begin
    Result.FreeSpace := $22286D53;
    Result.SmallFiles := $FF65758B;
  end
  else
  begin
    Result.FreeSpace := $22BFE5CF;
    Result.SmallFiles := $FF94A4BA;
  end;
end;

procedure TFormMain.SetChartView(const ID: string);
var
  NewView: TDiskChartView;
begin
  if SameText(ID, FChartViewID) then
    Exit;
  NewView := TChartViewRegistry.CreateView(ID);
  FChartView.Free;
  FChartView := NewView;
  FChartViewID := ID;
  UpdateChartViewButtons;
  FHover := nil;
  FHoverKind := chkNone;
  PaintBoxChart.Cursor := crDefault;
  if FDesignReady then
    ShowNode(nil);
  PaintBoxChart.Repaint;
end;

procedure TFormMain.UpdateDashboard;
var
  N: TDiskNode;
  Capacity, FreeBytes: UInt64;
  AvailableBytes, TotalBytes, VolumeFreeBytes: Int64;
  VolumePath: string;
  Skipped: Integer;
begin
  if FClosing then
    Exit;
  if ViewBlank then
  begin
    FViewNodes := nil;
    BuildFolderRows;
    SpeedButtonOpen.Enabled := False;
    LabelPageSubtitle.Text := Translate('Scanning files and folders');
    if FPendingRoot <> '' then
    begin
      LabelPath.Text := Translate('This PC') + '  ›  ' + FPendingPath;
      LabelPageTitle.Text := FPendingPath;
      // Nothing is known about this location yet.
      LabelUsedValue.Text := '—';
      LabelFreeValue.Text := '—';
      LabelTotalValue.Text := '—';
      LabelUsagePercent.Text := '';
      RectangleUsageFill.TagFloat := 0;
      FormMainResize(nil);
    end
    else
    begin
      LabelPageTitle.Text := NodeTitle(FFocus);
      LabelPath.Text := Translate('This PC');
      if (FFocus <> nil) and (FFocus.Path <> '') then
        LabelPath.Text := LabelPath.Text + '  ›  ' + FFocus.Path;
    end;
    UpdateScanStatus;
    Exit;
  end;
  LabelPageTitle.Text := NodeTitle(FFocus);
  LabelPath.Text := Translate('This PC');
  if (FFocus <> nil) and (FFocus.Path <> '') then
    LabelPath.Text := LabelPath.Text + '  ›  ' + FFocus.Path;
  LabelPageSubtitle.Text := Translate('Scan results');
  Skipped := ViewSkipped;
  if ViewBusy then
    LabelPageSubtitle.Text := Translate('Scanning files and folders')
  else if Skipped > 0 then
    LabelPageSubtitle.Text := LabelPageSubtitle.Text + ' · ' + Format(Translate('Unavailable: %s'), [IntToStr(Skipped)]);
  Capacity := 0;
  FreeBytes := 0;
  N := FFocus;
  if N <> nil then
  begin
    LabelUsedValue.Text := FormatBytes(N.Size);
    LabelFilesSummary.Text := Format(Translate('%s · %s'), [FileCountText(N.Files), FolderCountText(FolderCount(N))]);
    // A chosen folder stops at its own root; the drive fallback below applies.
    while not N.IsVolume and (N.Parent <> nil) and (N.Parent <> FOther) do
      N := N.Parent;
    Capacity := N.Capacity;
    FreeBytes := N.FreeSpace;
  end
  else
  begin
    LabelUsedValue.Text := '—';
    LabelFilesSummary.Text := '';
  end;
  if (Capacity = 0) and (FFocus <> nil) then
  begin
    VolumePath := IncludeTrailingPathDelimiter(ExtractFileDrive(FFocus.Path));
    if (Length(VolumePath) = 3) and (GetDriveType(PChar(VolumePath)) = DRIVE_FIXED) then
      if GetDiskFreeSpaceEx(PChar(VolumePath), AvailableBytes, TotalBytes, @VolumeFreeBytes) then
      begin
        Capacity := TotalBytes;
        FreeBytes := VolumeFreeBytes;
      end;
  end;
  if Capacity > 0 then
  begin
    // Windows volume usage also includes filesystem metadata and inaccessible files.
    LabelUsedValue.Text := FormatBytes(Capacity - FreeBytes);
    LabelFreeValue.Text := FormatBytes(FreeBytes);
    LabelTotalValue.Text := FormatBytes(Capacity);
    RectangleUsageFill.TagFloat := (Capacity - FreeBytes) / Capacity;
    LabelUsagePercent.Text := Format(Translate('%s%% used'), [FormatFloat('0', RectangleUsageFill.TagFloat * 100)]);
  end
  else
  begin
    LabelFreeValue.Text := '—';
    LabelTotalValue.Text := '—';
    RectangleUsageFill.TagFloat := 0;
    LabelUsagePercent.Text := Translate('File size');
  end;
  LabelStatus.Text := Translate('Scan complete');
  if FFocus = nil then
    LabelStatus.Text := Translate('Select a drive or folder');
  FViewNodes := FViewData.GetChildren(FFocus, True);
  BuildFolderRows;
  ShowNode(nil);
  FormMainResize(nil);
  // Results shown during a scan keep its progress and status line visible.
  UpdateScanStatus;
end;

procedure TFormMain.ReleaseChildCapture(Container: TFmxObject);
begin
  // Clear both FMX's captured control and the native HWND capture before
  // detaching its subtree. FreeNotification only clears the FMX reference.
  if (Captured <> nil) and Container.IsChild(Captured.GetObject) then
    SetCaptured(nil);
end;

procedure TFormMain.ClearFolderRows;
var
  Row: TFrameFolderItem;
begin
  // Rows borrow nodes: unbind them before the tree changes. Rows stay visible
  // and the spacer keeps its height, because the refresh that follows binds
  // them again before anything is painted; hiding and showing ~15 rows cost
  // more than the rest of the refresh.
  FRowNodes := nil;
  for Row in FRows do
    Row.SpeedButtonFolderItem.TagObject := nil;
end;

procedure TFormMain.BuildFolderRows;
var
  N: TDiskNode;
  Nodes: TList<TDiskNode>;
begin
  Nodes := TList<TDiskNode>.Create;
  try
    if (FFocus <> nil) and not ViewBlank and (FFocus.Children <> nil) then
      for N in FViewNodes do
        if not N.Hidden then
          Nodes.Add(N);
    FRowNodes := Nodes.ToArray;
  finally
    Nodes.Free
  end;
  LabelEmpty.Visible := Length(FRowNodes) = 0;
  LabelEmpty.Text := Translate('Folder is empty');
  if ViewBlank then
    LabelEmpty.Text := Translate('Scanning…')
  else if FFocus = nil then
    LabelEmpty.Text := Translate('Select a drive or folder');
  BindRows;
end;

procedure TFormMain.EnsureRows(Count: Integer);
var
  Row: TFrameFolderItem;
begin
  while FRows.Count < Count do
  begin
    Row := TFrameFolderItem.Create(Self);
    try
      Row.Name := '';
      Row.Align := TAlignLayout.None;
      Row.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
      Row.Visible := False;
      Row.Parent := VertScrollBoxFolders;
      Row.SpeedButtonFolderItem.OnClick := SpeedButtonFolderItemClick;
      Row.SpeedButtonFolderItem.OnDblClick := SpeedButtonFolderItemDblClick;
      Row.SpeedButtonFolderItem.OnMouseDown := SpeedButtonFolderItemMouseDown;
      FRows.Add(Row);
    except
      Row.Free;
      raise
    end;
    ApplyThemeTo(Row);
    if FRowHeight <= 0 then
      FRowHeight := Row.Height;
  end;
end;

procedure TFormMain.BindRows;
var
  First, Shown: Integer;
  i, Index: NativeInt;
  Row: TFrameFolderItem;
  Node: TDiskNode;
  Width: Single;
begin
  if FClosing then
    Exit;
  EnsureRows(1);
  // Enough rows to fill the viewport, plus one cut by its edges.
  Shown := Ceil(VertScrollBoxFolders.Height / FRowHeight) + 1;
  EnsureRows(Shown);
  First := Max(0, Integer(Trunc(VertScrollBoxFolders.ViewportPosition.Y / FRowHeight)));
  Width := VertScrollBoxFolders.Content.Width;
  if Width <= 0 then
    Width := VertScrollBoxFolders.Width;
  VertScrollBoxFolders.BeginUpdate;
  try
    FRowSpacer.SetBounds(0, 0, 1, Length(FRowNodes) * FRowHeight);
    for i := 0 to FRows.Count - 1 do
    begin
      Row := FRows[i];
      Index := First + i;
      if (i < Shown) and (Index < Length(FRowNodes)) then
      begin
        Node := FRowNodes[Index];
        Row.SetBounds(0, Index * FRowHeight, Width, FRowHeight);
        Row.BindNode(Node, ViewFraction(Node), NodeColor(Node));
        Row.SpeedButtonFolderItem.IsPressed := Node = FSelected;
        Row.Visible := True;
      end
      else
      begin
        Row.SpeedButtonFolderItem.TagObject := nil;
        Row.Visible := False;
      end;
    end;
  finally
    VertScrollBoxFolders.EndUpdate;
  end;
end;

procedure TFormMain.FolderRowsViewportChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF;
  const ContentSizeChanged: Boolean);
begin
  BindRows;
end;

procedure TFormMain.FolderRowsResize(Sender: TObject);
begin
  // A taller list needs more rows, and every row follows the new width.
  if FDesignReady then
    BindRows;
end;

procedure TFormMain.UpdateSelection(Node: TDiskNode);
begin
  SpeedButtonOpen.Enabled := (Node <> nil) and ((Node.Path <> '') or (Node is TSmallFileGroup)) and not Node.IsFree;
  LabelDetailName.Text := NodeTitle(Node);
  LabelDetailPath.Text := '';
  LabelDetailSize.Text := '—';
  LabelDetailPercent.Text := '';
  if Node = nil then
    Exit;
  if Node.IsFolder then
    PathDetailIcon.Data.Assign(PathFolderIconTemplate.Data)
  else
    PathDetailIcon.Data.Assign(PathFileIconTemplate.Data);
  LabelDetailSize.Text := FormatBytes(Node.DisplayBytes);
  LabelDetailPath.Text := Node.Path;
  if Node is TSmallFileGroup then
  begin
    LabelDetailPath.Text := Node.Parent.Path;
    LabelDetailPercent.Text := FileCountText(Node.Files);
  end;
  LabelDetailPath.Hint := LabelDetailPath.Text;
  LabelDetailPath.ShowHint := True;
  if FFocus <> nil then
    if Node is TSmallFileGroup then
      LabelDetailPercent.Text := LabelDetailPercent.Text + ' · ' + FormatFloat('0.#', 100 * ViewFraction(Node)) + '%'
    else if FFocus.IsVolume and (FFocus.Capacity > 0) then
      LabelDetailPercent.Text := Format(Translate('%s%% of disk capacity'), [FormatFloat('0.#', 100 * ViewFraction(Node))])
    else
      LabelDetailPercent.Text := Format(Translate('%s%% of file size'), [FormatFloat('0.#', 100 * ViewFraction(Node))]);
end;

procedure TFormMain.SpeedButtonFolderItemClick(Sender: TObject);
var
  Item: TFmxObject;
  Pressed: TDiskNode;
begin
  FSelected := TDiskNode(TFmxObject(Sender).TagObject);
  // A preview may have re-bound this row since it was pressed.
  if FPressedPath <> '' then
  begin
    Pressed := FindScanned(FPressedPath);
    if Pressed <> nil then
      FSelected := Pressed;
    FPressedPath := '';
  end;
  for Item in VertScrollBoxFolders.Content.Children do
    if Item is TFrameFolderItem then
      TFrameFolderItem(Item).SpeedButtonFolderItem.IsPressed := TFrameFolderItem(Item).Node = FSelected;
  FHover := nil;
  FHoverKind := chkNone;
  UpdateSelection(FSelected);
  PaintBoxChart.Repaint;
end;

procedure TFormMain.SpeedButtonFolderItemDblClick(Sender: TObject);
var
  Node: TDiskNode;
  Path: string;
begin
  Node := TDiskNode(TFmxObject(Sender).TagObject);
  if (Node = nil) or ViewBlank then
    Exit;
  if (Node is TSmallFileGroup) or Node.IsFree or (Node is TUnscannedSpace) or not Node.IsFolder then
    Exit;
  Path := FPressedPath;
  if Path = '' then
    Path := Node.Path;
  // FMX still sends this row a Click after OnDblClick, and opening the folder
  // re-binds the rows; open it once that click has been handled.
  TThread.ForceQueue(nil,
    procedure
    var
      Target: TDiskNode;
    begin
      Target := FindScanned(Path);
      if (Target <> nil) and Target.IsFolder then
        FocusNode(Target);
    end);
end;

procedure TFormMain.PopupNode(Node: TDiskNode; const ScreenPoint: TPointF);
begin
  if (Node = nil) or (Node is TSmallFileGroup) or (Node is TUnscannedSpace) or Node.IsFree or ViewBlank then
    Exit;
  if Node.IsUsed then
    Node := Node.Parent;
  FContext := Node;
  MenuItemHide.Text := Translate('Hide');
  MenuItemHide.StyleLookup := 'menuhidestyle';
  if Node.Hidden then
  begin
    MenuItemHide.Text := Translate('Show');
    MenuItemHide.StyleLookup := 'menushowstyle';
  end;
  MenuItemHide.Enabled := Node.IsFolder;
  MenuItemZoom.Enabled := Node.IsFolder and (Node <> FFocus);
  MenuItemRescan.Enabled := Node.IsFolder;
  MenuItemOpen.Enabled := Node.Path <> '';
  MenuItemRecycle.Enabled := (Node.Path <> '') and not Node.IsVolume;
  MenuItemRemove.Enabled := MenuItemRecycle.Enabled;
  PopupMenuNode.Popup(ScreenPoint.X, ScreenPoint.Y);
end;

procedure TFormMain.SpeedButtonFolderItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FPressedPath := PathOfNode(TDiskNode(TFmxObject(Sender).TagObject));
  if Button = TMouseButton.mbRight then
  begin
    SpeedButtonFolderItemClick(Sender);
    PopupNode(FSelected, TControl(Sender).LocalToScreen(PointF(X, Y)));
  end;
end;

procedure TFormMain.FormMainResize(Sender: TObject);
begin
  if not FDesignReady or FClosing then
    Exit;
  RectangleUsageFill.Width := RectangleUsageTrack.Width * RectangleUsageFill.TagFloat;
  RectangleUsageFill.XRadius := RectangleUsageTrack.XRadius;
  RectangleUsageFill.YRadius := RectangleUsageTrack.YRadius;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.SpeedButtonChooseClick(Sender: TObject);
begin
  ChooseFolder;
end;

procedure TFormMain.SpeedButtonScanClick(Sender: TObject);
begin
  if ViewBusy then
  begin
    StopViewScans;
    LabelStatus.Text := Translate('Scan stopped');
  end
  else
    Rescan(FFocus);
end;

procedure TFormMain.SpeedButtonOpenClick(Sender: TObject);
var
  Node: TDiskNode;
begin
  Node := FSelected;
  if Node = nil then
    Node := FFocus;
  if Node is TSmallFileGroup then
    Node := Node.Parent;
  if (Node = nil) or (Node.Path = '') then
    Exit;
  if Node.IsFolder then
    OpenTarget(Node.Path)
  else
    OpenTarget('explorer.exe', '/select,"' + Node.Path + '"');
end;

procedure TFormMain.SpeedButtonSettingsClick(Sender: TObject);
begin
  var P := SpeedButtonSettings.LocalToScreen(PointF(0, 0));
  PopupMenuSettings.Popup(P.X, P.Y);
end;

procedure TFormMain.ExecuteSettingsAction(Sender: TObject);
begin
  case TFmxObject(Sender).Tag of
    21:
      ShowScannerDialog(Self, Translate('About Scanner'), 'Scanner FMX' + sLineBreak + Translate('Disk space analyzer') + sLineBreak +
        Translate('Based on Scanner 2.13 · Steffen Gerlach'));
  else
    ExecuteUICommand(Sender);
  end;
end;

procedure TFormMain.SpeedButtonSummaryClick(Sender: TObject);
begin
  ExecuteUICommand(Sender);
end;

procedure TFormMain.SpeedButtonBackClick(Sender: TObject);
begin
  ExecuteUICommand(Sender);
end;

procedure TFormMain.SpeedButtonUpClick(Sender: TObject);
begin
  ExecuteUICommand(Sender);
end;

procedure TFormMain.SpeedButtonBrowseClick(Sender: TObject);
begin
  ChooseFolder;
end;

procedure TFormMain.SelectLanguage(const Language: string);
begin
  SetLanguage(Language);
  FIni.WriteString('Appearance', 'Language', LangLanguages.Lang);
  FIni.UpdateFile;
end;

procedure TFormMain.MenuItemLanguageRussianClick(Sender: TObject);
begin
  SelectLanguage('ru');
end;

procedure TFormMain.MenuItemLanguageEnglishClick(Sender: TObject);
begin
  SelectLanguage('en');
end;

procedure TFormMain.MenuItemAppsClick(Sender: TObject);
begin
  ExecuteSettingsAction(Sender);
end;

procedure TFormMain.MenuItemTrashClick(Sender: TObject);
begin
  ExecuteSettingsAction(Sender);
end;

procedure TFormMain.MenuItemAboutClick(Sender: TObject);
begin
  ExecuteSettingsAction(Sender);
end;

procedure TFormMain.MenuItemFreeSpaceClick(Sender: TObject);
begin
  MenuItemFreeSpace.IsChecked := not MenuItemFreeSpace.IsChecked;
  FIni.WriteBool('Appearance', 'HideFreeSpace', MenuItemFreeSpace.IsChecked);
  FIni.UpdateFile;
  ResetViewCaches;
  if (FSelected <> nil) and FSelected.IsFree then
    FSelected := nil;
  FViewData.ShowFreeSpace := not MenuItemFreeSpace.IsChecked;
  RefreshView;
end;

procedure TFormMain.MenuItemLiveScanClick(Sender: TObject);
begin
  MenuItemLiveScan.IsChecked := not MenuItemLiveScan.IsChecked;
  FIni.WriteBool('Appearance', 'LiveScan', MenuItemLiveScan.IsChecked);
  FIni.UpdateFile;
  // Previews already shown stay until their scans finish; the next timer
  // tick asks for new ones if this was turned on.
  RefreshView;
end;

procedure TFormMain.MenuItemHideClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemZoomClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemRescanClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemOpenClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemRecycleClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemRemoveClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.SetLanguage(const Language: string);
var
  Code: string;
begin
  Code := 'en';
  if SameText(Language, 'ru') then
    Code := 'ru';
  PreserveUserText(LabelPageTitle);
  PreserveUserText(LabelPath);
  PreserveUserText(LabelDetailName);
  PreserveUserText(LabelDetailPath);
  PreserveUserText(LabelScan);
  SetUILanguage(Code);
  LangLanguages.Lang := Code;
  MenuItemLanguage.Text := Translate('Language');
  MenuItemLanguageRussian.Text := Translate('Russian');
  MenuItemLanguageEnglish.Text := Translate('English');
  MenuItemLanguageRussian.IsChecked := Code = 'ru';
  MenuItemLanguageEnglish.IsChecked := Code = 'en';
  MenuItemApps.Text := Translate('Programs and Features');
  MenuItemTrash.Text := Translate('Empty Recycle Bin…');
  MenuItemAbout.Text := Translate('About Scanner');
  MenuItemFreeSpace.Text := Translate('Don''t draw free space');
  MenuItemLiveScan.Text := Translate('Show results while scanning');
  SpeedButtonUp.Hint := Translate('Parent folder (Alt+Up)');
  SpeedButtonBack.Hint := Translate('Back (Alt+Left)');
  MenuItemInclude.Text := Translate('Include in summary');
  MenuItemPhysical.Text := Translate('Physical device ID');
  MenuItemZoom.Text := Translate('Zoom');
  MenuItemRescan.Text := Translate('Rescan');
  MenuItemOpen.Text := Translate('Open');
  MenuItemRecycle.Text := Translate('Recycle');
  MenuItemRemove.Text := Translate('Remove');
  if not FDesignReady then
  begin
    LabelDetailName.Text := Translate('Select a folder');
    Exit;
  end;
  FHover := nil;
  FHoverKind := chkNone;
  BuildDriveButtons;
  BuildChartViewButtons;
  ApplyTheme(FDarkTheme);
  UpdateButtons;
end;

procedure TFormMain.BuildChartViewButtons;
var
  Button: TSpeedButton;
  LabelTitle: TLabel;
  Index: Integer;
  Suffix: string;
  StartWord: Boolean;
  Item: TFmxObject;
begin
  ReleaseChildCapture(LayoutChartViews);
  while LayoutChartViews.ChildrenCount > 0 do
  begin
    Item := LayoutChartViews.Children[0];
    if Item is TSpeedButton then
    begin
      Button := TSpeedButton(Item);
      Button.OnClick := nil;
      Button.OnDblClick := nil;
      Button.OnMouseDown := nil;
      Button.TagString := '';
    end;
    // Released buttons still belong to LayoutChartViews until destruction.
    // Free their component names before creating the replacement buttons.
    Item.Name := '';
    Item.Release;
  end;
  Index := 0;
  for var Info in TChartViewRegistry.Views do
  begin
    Button := TSpeedButton.Create(LayoutChartViews);
    Suffix := '';
    StartWord := True;
    for var C in Info.ID do
      if CharInSet(C, ['a'..'z', 'A'..'Z', '0'..'9']) then
      begin
        if StartWord then
          Suffix := Suffix + UpCase(C)
        else
          Suffix := Suffix + C;
        StartWord := False;
      end
      else
        StartWord := True;
    if Suffix = '' then
      Suffix := 'Custom';
    while LayoutChartViews.FindComponent('SpeedButtonChartView' + Suffix) <> nil do
      Suffix := Suffix + Index.ToString;
    Button.Name := 'SpeedButtonChartView' + Suffix;
    Button.Text := '';
    Button.Parent := LayoutChartViews;
    Button.Align := TAlignLayout.Left;
    Button.Width := Min(180, Max(72, Length(Info.Title) * 7 + 24));
    Button.Position.X := Index * 180;
    Button.Margins.Right := 6;
    Button.StyleLookup := 'sidebutton';
    Button.StaysPressed := True;
    Button.TagString := Info.ID;
    Button.Hint := Info.Title;
    Button.ShowHint := True;
    Button.OnClick := SpeedButtonChartViewClick;
    LabelTitle := TLabel.Create(Button);
    LabelTitle.Name := 'LabelTitle';
    LabelTitle.Parent := Button;
    LabelTitle.Align := TAlignLayout.Client;
    LabelTitle.HitTest := False;
    LabelTitle.StyledSettings := [];
    LabelTitle.TagString := 'text';
    LabelTitle.TextSettings.Font.Size := 12;
    LabelTitle.TextSettings.HorzAlign := TTextAlign.Center;
    LabelTitle.TextSettings.WordWrap := False;
    LabelTitle.TextSettings.Trimming := TTextTrimming.Character;
    LabelTitle.Text := Info.Title;
    Inc(Index);
  end;
  ApplyThemeTo(LayoutChartViews);
  UpdateChartViewButtons;
end;

procedure TFormMain.UpdateChartViewButtons;
begin
  if LayoutChartViews.ChildrenCount = 0 then
    Exit;
  for var Item in LayoutChartViews.Children do
    if Item is TSpeedButton then
      TSpeedButton(Item).IsPressed := SameText(Item.TagString, FChartViewID);
end;

procedure TFormMain.SpeedButtonChartViewClick(Sender: TObject);
begin
  SetChartView(TControl(Sender).TagString);
end;

end.

