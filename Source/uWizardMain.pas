unit uWizardMain;

interface

uses
  ToolsApi, System.SysUtils, Vcl.Forms, Vcl.Graphics, Winapi.Windows, System.Classes,
  Vcl.Menus,
  uWizardConsts, uWizardSettings, uFeatureCollection, uWizardUtils;

type
  TDICEMainApp = class(TObject)
  private
    class var FPluginTerminated: Boolean;
    class var FDICEMainAppInstance: TDICEMainApp;
    class var FSplashTimerHandle: UIntPtr;
  private
    FMenuItemImage: Vcl.Graphics.TBitmap;
    FDICEMenuItem: TMenuItem;  // Owned by IDE Tools menu, but freed by plugin on unload
    FAboutInfoIndex: Integer;
    FWizardSettings: TWizardSettings;
    FFeatures: TFeatureCollection;
    FWizardVersion: TDICEVersionInfo;

    procedure InitSplashScreenInfo;
    procedure InitAboutBoxInfo;
    procedure InitMenuItemImage;
    procedure InitAfterIDELoad;

    procedure OnClickWizardSettingsMenuItem(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    class destructor Destroy;

    class function GetDICEMainApp: TDICEMainApp;

    procedure InitApp;

    property WizardSettings: TWizardSettings read FWizardSettings;
    property Features: TFeatureCollection read FFeatures;
  end;

  TDICEWizard = class(TNotifierObject, IOTANotifier, IOTAWizard, IOTAMenuWizard)
  public
    // IOTAWizard
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    // IOTAMenuWizard
    function GetMenuText: string;
  end;

// TWizardInitProc
function InitWizard(const BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc;
    var Terminate: TWizardTerminateProc): Boolean stdcall;

// +++  http://www.delphikingdom.com/asp/viewitem.asp?catalogid=899
// +++ C:\GitHub Repos\OTAPI-Docs\The Delphi IDE Open Tools API - Version 1.2.docx

implementation

{ }

function LoadBitmapHandle(const AResName: string): HBITMAP;
begin
  Result := HBITMAP(LoadImage(HInstance, PChar(AResName), IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION));
end;

procedure DestroySplashTimer;
begin
  if TDICEMainApp.FSplashTimerHandle <> 0 then
    KillTimer(0, TDICEMainApp.FSplashTimerHandle);
  TDICEMainApp.FSplashTimerHandle := 0;
end;

procedure OnSplashTimer(Wnd: HWND; Msg: Cardinal; IDEvent: Cardinal; Time: DWORD); stdcall;
begin
  if TDICEMainApp.FPluginTerminated or not Assigned(Application) or Application.Terminated then
    DestroySplashTimer
  else if (Application.MainForm <> nil) and Application.MainForm.Visible then
  begin
    DestroySplashTimer;
    TDICEMainApp.GetDICEMainApp.InitAfterIDELoad;
  end;
end;

procedure InitSplashTimer;
begin
  DestroySplashTimer;
  TDICEMainApp.FSplashTimerHandle := SetTimer(0, 0, 100, @OnSplashTimer);
end;

procedure TerminateWizard;
begin
  // First of all, so timer is killed even if plugin is already marked as terminated
  DestroySplashTimer;
  if TDICEMainApp.FPluginTerminated then Exit;

  TDICEMainApp.FPluginTerminated := True;
  FreeAndNil(TDICEMainApp.FDICEMainAppInstance);
end;

function InitWizard(const BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc;
    var Terminate: TWizardTerminateProc): Boolean stdcall;
var
  MainApp: TDICEMainApp;
begin
  Result := Assigned(BorlandIDEServices);

  if Result then
  begin
    TDICEMainApp.FSplashTimerHandle := 0;
    TDICEMainApp.FPluginTerminated := False;
    Terminate := TerminateWizard;

    MainApp := TDICEMainApp.GetDICEMainApp;
    MainApp.InitApp;

    RegisterProc(TDICEWizard.Create);

    InitSplashTimer;
  end;
end;

{ TDICEMainApp }

constructor TDICEMainApp.Create;
var
  ModuleFileName: string;
begin
  inherited Create;

  FWizardSettings := TWizardSettings.Create;
  FFeatures := TFeatureCollection.Create;

  ModuleFileName := GetModuleFileNameCustom;
  if ModuleFileName <> EmptyStr then
    GetFileVersionCustom(ModuleFileName, FWizardVersion);

  FAboutInfoIndex := -1;
end;

destructor TDICEMainApp.Destroy;
var
  AboutBoxIntf: IOTAAboutBoxServices;
begin
  // GetDICEMainApp is not available here (instance is already nil), so nothing below should call it.

  // Menu first, so it can't be clicked while plugin is being destroyed
  FreeAndNil(FDICEMenuItem);

  // Features must be rolled back and freed before settings, because settings form owns features controls
  if Assigned(FFeatures) then
    FFeatures.FinalizeAllFeatures;
  FreeAndNil(FFeatures);
  FreeAndNil(FWizardSettings);

  try
    if (FAboutInfoIndex <> -1) and Supports(BorlandIDEServices, IOTAAboutBoxServices, AboutBoxIntf) then
      AboutBoxIntf.RemovePluginInfo(FAboutInfoIndex);
  finally
    AboutBoxIntf := nil;
  end;
  FreeAndNil(FMenuItemImage);

  TDICEMainApp.FPluginTerminated := True;
  inherited Destroy;
end;

class destructor TDICEMainApp.Destroy;
begin
  FreeAndNil(FDICEMainAppInstance);
  DestroySplashTimer;
end;

class function TDICEMainApp.GetDICEMainApp: TDICEMainApp;
var
  NewInstance: TDICEMainApp;
begin
  if FPluginTerminated then
    raise Exception.Create('Error getting an instance of TDICEWizard, plugin already terminated.');

  if not Assigned(FDICEMainAppInstance) then
  begin
    NewInstance := TDICEMainApp.Create;
    if InterlockedCompareExchangePointer(Pointer(FDICEMainAppInstance), NewInstance, nil) <> nil then
      NewInstance.Free;
  end;

  Result := FDICEMainAppInstance;
end;

procedure TDICEMainApp.InitApp;
begin
  InitSplashScreenInfo;
  InitAboutBoxInfo;
  InitMenuItemImage;
  FWizardSettings.InitXMLSettings;
end;

procedure TDICEMainApp.InitSplashScreenInfo;
var
  SplashHandle: HBITMAP;
begin
  if not Assigned(SplashScreenServices) then
    Exit;

  SplashHandle := LoadBitmapHandle('DICESPLASHBMP');

  SplashScreenServices.AddPluginBitmap(WIZARD_PRODUCT_NAME, SplashHandle, False,
      Format(WIZARD_SPLASH_TEXT, [FWizardVersion.FMajor, FWizardVersion.FMinor,
      GetVersionRevision(FWizardVersion.FBugFix){$IFDEF DEBUG}+ ' (debug)'{$ENDIF}]));
end;

procedure TDICEMainApp.InitAboutBoxInfo;
var
  AboutBoxIntf: IOTAAboutBoxServices;
  AboutHandle: HBITMAP;
begin
  try
    AboutHandle := LoadBitmapHandle('DICEABOUTHBMP');

    if Supports(BorlandIDEServices, IOTAAboutBoxServices, AboutBoxIntf) then
      FAboutInfoIndex := AboutBoxIntf.AddPluginInfo(Format(WIZARD_NAME + ' ' + WIZARD_SPLASH_TEXT,
          [FWizardVersion.FMajor, FWizardVersion.FMinor, GetVersionRevision(FWizardVersion.FBugFix){$IFDEF DEBUG}+ ' (debug)'{$ENDIF}]),
          Format(WIZARD_ABOUT_TEXT, [WIZARD_PRODUCT_NAME, WIZARD_COPYRIGHT_TEXT]),
          AboutHandle, False, WIZARD_LICENCE_TEXT);
  finally
    AboutBoxIntf := nil;
  end;
end;

procedure TDICEMainApp.InitMenuItemImage;
begin
  if not Assigned(FMenuItemImage) then
    FMenuItemImage := LoadMenuBitmap('DICEABOUTHBMP');
end;

procedure TDICEMainApp.InitAfterIDELoad;
var
  ToolsMenuItem, FirstDivider: TMenuItem;
  AppMainMenu: TMainMenu;
  ServicesIntf: INTAServices;
  i, DividerIndex: Integer;
begin
  if Supports(BorlandIDEServices, INTAServices, ServicesIntf) then
    AppMainMenu := ServicesIntf.GetMainMenu
  else
    AppMainMenu := nil;

  if Assigned(AppMainMenu) then
  begin
    ToolsMenuItem := nil;
    for i := 0 to AppMainMenu.Items.Count - 1 do
      if AppMainMenu.Items[i].Name = 'ToolsMenu' then
      begin
        ToolsMenuItem := AppMainMenu.Items[i];
        Break;
      end;

    if Assigned(ToolsMenuItem) then
    begin
      FDICEMenuItem := TMenuItem.Create(ToolsMenuItem);
      FDICEMenuItem.Name := WIZARD_SETTINGS_MENU_ITEM_NAME;
      FDICEMenuItem.Caption := WIZARD_SETTINGS_MENU_ITEM_CAPTION;
      FDICEMenuItem.OnClick := OnClickWizardSettingsMenuItem;

      if Assigned(FMenuItemImage) then
        FDICEMenuItem.ImageIndex := ServicesIntf.AddImage(WIZARD_ID_STRING + '.ICON', [FMenuItemImage]);

      FirstDivider := ToolsMenuItem.Find('-');
      if Assigned(FirstDivider) then
        DividerIndex := FirstDivider.MenuIndex
      else
        DividerIndex := 0;

      ToolsMenuItem.Insert(DividerIndex, FDICEMenuItem);
    end;
  end;

  FFeatures.CreateAllFeatures(FWizardSettings);
  FFeatures.InitAllFeatures;
  WizardSettings.CreateAndInitSettingsForm;
end;

procedure TDICEMainApp.OnClickWizardSettingsMenuItem(Sender: TObject);
begin
  WizardSettings.ShowModalSettingsForm;
end;

{ TDICEWizard }

function TDICEWizard.GetIDString: string;
begin
  Result := WIZARD_ID_STRING;
end;

function TDICEWizard.GetName: string;
begin
  Result := WIZARD_NAME;
end;

function TDICEWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TDICEWizard.Execute;
begin
  if Assigned(Application) then
    Application.MessageBox(PWideChar(Format(WIZARD_HELP_MENU_TEXT, [WIZARD_PRODUCT_NAME, WIZARD_COPYRIGHT_TEXT, WIZARD_LICENCE_TEXT])),
        PWideChar(WIZARD_NAME));
end;

function TDICEWizard.GetMenuText: string;
begin
  Result := WIZARD_HELP_MENU_CAPTION;
end;

end.
