unit uBaseFeature;

interface

uses
  Xml.XMLIntf, System.Variants,
  uWizardSettings, uWizardLog, ufmWizardSettings;

type
  TBaseFeature = class(TObject)
  protected
    FFeatureEnabled: Boolean;
    FGlobalWizardSettings: TWizardSettings;
    FLogger: TWizardLogger;

    function GetFeatureEnabled: Boolean; virtual;
    procedure SetFeatureEnabled(Value: Boolean); virtual; abstract;
  public
    constructor CreateFeature(AWizardSettings: TWizardSettings; ALogger: TWizardLogger); virtual;

    procedure InitFeature; virtual;
    procedure InitFeatureControls(ASettingsForm: TfmWizardSettings); virtual;
    // Rolls back all changes made to the IDE, called before plugin is unloaded
    procedure FinalizeFeature; virtual;

    procedure ReadFeatureSettings(AFeatureSettings: IXMLNode); virtual;
    procedure WriteFeatureSettings(AFeatureSettings: IXMLNode); virtual;

    property FeatureEnabled: Boolean read GetFeatureEnabled write SetFeatureEnabled;
    property Logger: TWizardLogger read FLogger;
  end;

  TBaseFeatureClass = class of TBaseFeature;

implementation

{ TBaseFeature }

constructor TBaseFeature.CreateFeature(AWizardSettings: TWizardSettings; ALogger: TWizardLogger);
begin
  inherited Create;

  FFeatureEnabled := False;
  FGlobalWizardSettings := AWizardSettings;
  FLogger := ALogger;
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
    // Not in finally, so it is not logged when initialization failed
    FLogger.Log('Feature ' + Self.ClassName + ' initialized');
  finally
    FeatureSettings := nil;
  end;
end;

procedure TBaseFeature.InitFeatureControls(ASettingsForm: TfmWizardSettings);
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
