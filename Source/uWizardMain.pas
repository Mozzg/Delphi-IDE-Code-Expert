unit uWizardMain;

interface

uses
  ToolsApi, System.SysUtils, Vcl.Forms, Vcl.Graphics, Winapi.Windows, System.Classes,
  Vcl.Menus,
  uWizardConsts, uWizardSettings, uFeatureCollection;

type
  TDICEMainApp = class(TObject)
  private
    class var FPluginTerminated: Boolean;
    class var FDICEMainAppInstance: TDICEMainApp;
    class var FSplashTimerHandle: UIntPtr;
  private
    FDICEBitmap: Vcl.Graphics.TBitmap;
    FAboutBitmap: Vcl.Graphics.TBitmap;
    FAboutInfoIndex: Integer;
    FWizardSettings: TWizardSettings;
    FFeatures: TFeatureCollection;

    procedure InitSplashScreenInfo;
    procedure InitAboutBoxInfo;
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

  TDICEWizard = class(TInterfacedObject, IOTAWizard, IOTAMenuWizard)
  public
    // IOTAWizard
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    // IOTANotifier
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    // IOTAMenuWizard
    function GetMenuText: string;
  end;

// TWizardInitProc
function InitWizard(const BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc;
    var Terminate: TWizardTerminateProc): Boolean stdcall;

implementation

{ }

procedure DestroySplashTimer;
begin
  if TDICEMainApp.FSplashTimerHandle <> 0 then
    KillTimer(0, TDICEMainApp.FSplashTimerHandle);
  TDICEMainApp.FSplashTimerHandle := 0;
end;

procedure OnSplashTimer(Wnd: HWND; Msg: Cardinal; IDEvent: Cardinal; Time: DWORD); stdcall;
begin
  if not Assigned(Application) then
    DestroySplashTimer
  else if Application.Terminated then
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
  if TDICEMainApp.FPluginTerminated then Exit;

  TDICEMainApp.FPluginTerminated := True;
  FreeAndNil(TDICEMainApp.FDICEMainAppInstance);
end;

function InitWizard(const BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc;
    var Terminate: TWizardTerminateProc): Boolean stdcall;
var
  MainApp: TDICEMainApp;
begin
  TDICEMainApp.FSplashTimerHandle := 0;
  TDICEMainApp.FPluginTerminated := False;
  Terminate := TerminateWizard;
  MainApp := TDICEMainApp.GetDICEMainApp;
  MainApp.InitApp;
  RegisterProc(TDICEWizard.Create);
  InitSplashTimer;
  Result := True;
end;

{ TDICEMainApp }

constructor TDICEMainApp.Create;
begin
  inherited Create;

  FWizardSettings := TWizardSettings.Create;
  FFeatures := TFeatureCollection.Create;

  FAboutInfoIndex := -1;
  InitSplashScreenInfo;
  InitAboutBoxInfo;
end;

destructor TDICEMainApp.Destroy;
var
  AboutBoxIntf: IOTAAboutBoxServices;
begin
  try
    if (FAboutInfoIndex <> -1) and Assigned(BorlandIDEServices)
        and Supports(BorlandIDEServices, IOTAAboutBoxServices, AboutBoxIntf)
    then
      AboutBoxIntf.RemovePluginInfo(FAboutInfoIndex);
  finally
    AboutBoxIntf := nil;
  end;
  FreeAndNil(FAboutBitmap);
  FreeAndNil(FDICEBitmap);

  FreeAndNil(FWizardSettings);
  FreeAndNil(FFeatures);

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
  FWizardSettings.InitXMLSettings;
end;

procedure TDICEMainApp.InitSplashScreenInfo;
begin
  if not Assigned(FDICEBitmap) then
  begin
    FDICEBitmap := Vcl.Graphics.TBitmap.Create;
    FDICEBitmap.LoadFromResourceName(HInstance, 'DICESPLASHBMP');
  end;

  SplashScreenServices.AddPluginBitmap(WIZARD_NAME, FDICEBitmap.Handle);
end;

procedure TDICEMainApp.InitAboutBoxInfo;
var
  AboutBoxIntf: IOTAAboutBoxServices;
begin
  if not Assigned(FAboutBitmap) then
  begin
    FAboutBitmap := Vcl.Graphics.TBitmap.Create;
    FAboutBitmap.LoadFromResourceName(HInstance, 'DICEABOUTHBMP');
  end;

  try
    if Assigned(BorlandIDEServices) and Supports(BorlandIDEServices, IOTAAboutBoxServices, AboutBoxIntf) then
      FAboutInfoIndex := AboutBoxIntf.AddPluginInfo(WIZARD_NAME, WIZARD_HELP_MENU_TEXT,
          FAboutBitmap.Handle);
  finally
    AboutBoxIntf := nil;
  end;
end;

procedure TDICEMainApp.InitAfterIDELoad;
var
  ToolsComponent, ConfigureComponent: TComponent;
  ToolsMenuItem, DICEMenuItem: TMenuItem;
begin
  ToolsComponent := Application.MainForm.FindComponent('ToolsMenu');
  if (ToolsComponent is TMenuItem) then
    ToolsMenuItem := ToolsComponent as TMenuItem
  else
    ToolsMenuItem := nil;

  if Assigned(ToolsMenuItem) then
  begin
    DICEMenuItem := TMenuItem.Create(ToolsMenuItem);
    DICEMenuItem.Name := WIZARD_SETTINGS_MENU_ITEM_NAME;
    DICEMenuItem.Caption := WIZARD_SETTINGS_MENU_ITEM_CAPTION;
    DICEMenuItem.OnClick := OnClickWizardSettingsMenuItem;

    ConfigureComponent := Application.MainForm.FindComponent('ToolsToolsItem');
    if Assigned(ConfigureComponent) and (ConfigureComponent is TMenuItem) then
      ToolsMenuItem.Insert(ToolsMenuItem.IndexOf(ConfigureComponent as TMenuItem) + 1, DICEMenuItem)
    else
      ToolsMenuItem.Insert(0, DICEMenuItem);
  end;

  FFeatures.CreateAllFeatures(FWizardSettings);
  FFeatures.InitAllFeatures;
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
    Application.MessageBox(PWideChar(WIZARD_HELP_MENU_TEXT), PWideChar(WIZARD_NAME));
end;

procedure TDICEWizard.AfterSave;
begin
end;

procedure TDICEWizard.BeforeSave;
begin
end;

procedure TDICEWizard.Destroyed;
begin
end;

procedure TDICEWizard.Modified;
begin
end;

function TDICEWizard.GetMenuText: string;
begin
  Result := WIZARD_HELP_MENU_CAPTION;
end;

end.
