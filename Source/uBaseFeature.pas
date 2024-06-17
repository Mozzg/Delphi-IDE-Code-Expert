unit uBaseFeature;

interface

uses
  Vcl.Forms, Xml.XMLIntf,
  uWizardSettings;

type
  TBaseFeature = class(TObject)
  protected
    FGlobalWizardSettings: TWizardSettings;

    function GetFeatureEnabled: Boolean; virtual; abstract;
    procedure SetFeatureEnabled(Value: Boolean); virtual; abstract;
  public
    constructor CreateFeature(WizardSettings: TWizardSettings); virtual;

    procedure InitFeature; virtual;
    procedure InitFeatureControls(ASettingsForm: TForm); virtual; abstract;

    procedure ReadFeatureSettings(AFeatureSettings: IXMLNode); virtual; abstract;
    procedure WriteFeatureSettings(AFeatureSettings: IXMLNode); virtual; abstract;

    property FeatureEnabled: Boolean read GetFeatureEnabled write SetFeatureEnabled;
  end;

implementation

{ TBaseFeature }

constructor TBaseFeature.CreateFeature(WizardSettings: TWizardSettings);
begin
  inherited Create;

  FGlobalWizardSettings := WizardSettings;
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
  end;
end;

end.
