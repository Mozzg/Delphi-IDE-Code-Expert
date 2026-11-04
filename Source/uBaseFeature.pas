unit uBaseFeature;

interface

uses
  Vcl.Forms, Xml.XMLIntf, System.Variants,
  uWizardSettings;

type
  TBaseFeature = class(TObject)
  protected
    FFeatureEnabled: Boolean;
    FGlobalWizardSettings: TWizardSettings;

    function GetFeatureEnabled: Boolean; virtual;
    procedure SetFeatureEnabled(Value: Boolean); virtual; abstract;
  public
    constructor CreateFeature(WizardSettings: TWizardSettings); virtual;

    procedure InitFeature; virtual;
    procedure InitFeatureControls(ASettingsForm: TForm); virtual;
    // Rolls back all changes made to the IDE, called before plugin is unloaded
    procedure FinalizeFeature; virtual;

    procedure ReadFeatureSettings(AFeatureSettings: IXMLNode); virtual;
    procedure WriteFeatureSettings(AFeatureSettings: IXMLNode); virtual;

    property FeatureEnabled: Boolean read GetFeatureEnabled write SetFeatureEnabled;
  end;

implementation

uses
  uWizardMain;

{ TBaseFeature }

constructor TBaseFeature.CreateFeature(WizardSettings: TWizardSettings);
begin
  inherited Create;

  FFeatureEnabled := False;
  FGlobalWizardSettings := WizardSettings;
end;

function TBaseFeature.GetFeatureEnabled: Boolean;
begin
  Result := FFeatureEnabled;
end;

procedure TBaseFeature.InitFeature;
var
  FeatureSettings: IXMLNode;
begin
  try
    FeatureSettings := FGlobalWizardSettings.GetXMLSettingsForFeature(ClassName);
    ReadFeatureSettings(FeatureSettings);
  finally
    FeatureSettings := nil;
    TDICEMainApp.GetDICEMainApp.Logger.Log('Feature ' + Self.ClassName + ' initialized');
  end;
end;

procedure TBaseFeature.InitFeatureControls(ASettingsForm: TForm);
begin
  // Empty method, no controls to init
end;

procedure TBaseFeature.FinalizeFeature;
begin
  // Settings are not saved here, so feature will be enabled again on next IDE start
  FeatureEnabled := False;
end;

procedure TBaseFeature.ReadFeatureSettings(AFeatureSettings: IXMLNode);
var
  FeatureEnabledSetting: OleVariant;
begin
  FeatureEnabledSetting := AFeatureSettings.Attributes['Enabled'];
  if not VarIsNull(FeatureEnabledSetting) then
    FeatureEnabled := FeatureEnabledSetting;
end;

procedure TBaseFeature.WriteFeatureSettings(AFeatureSettings: IXMLNode);
begin
  AFeatureSettings.Attributes['Enabled'] := FeatureEnabled;
end;

end.
