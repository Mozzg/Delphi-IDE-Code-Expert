unit uFeatureCollection;

interface

uses
  System.Contnrs, System.SysUtils, System.Rtti, Vcl.Forms, Xml.XMLIntf,
  uWizardConsts, uBaseFeature, uWizardSettings;

type
  TFeatureCollection = class(TObject)
  private
    class var FFeatureClassList: TClassList;
  private
    FFeatureList: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;

    class procedure RegisterFeature(AFeatureClass: TClass);

    procedure CreateAllFeatures(WizardSettings: TWizardSettings);
    procedure InitAllFeatures;
    procedure InitFeaturesControls(ASettingsForm: TForm);
    procedure SaveFeaturesSettings;
  end;

implementation

uses
  uWizardMain;

{ TFeatureCollection }

constructor TFeatureCollection.Create;
begin
  inherited Create;

  FFeatureList := TObjectList.Create(True);
end;

destructor TFeatureCollection.Destroy;
begin
  FreeAndNil(FFeatureList);

  inherited Destroy;
end;

class procedure TFeatureCollection.RegisterFeature(AFeatureClass: TClass);
begin
  FFeatureClassList.Add(AFeatureClass);
end;

procedure TFeatureCollection.CreateAllFeatures(WizardSettings: TWizardSettings);
var
  FeatureClass: TClass;
  FeatureObject: TObject;
  Context: TRttiContext;
  RttiType: TRttiType;
  RttiValue: TValue;
begin
  Context := TRttiContext.Create;

  for FeatureClass in FFeatureClassList do
  begin
    FeatureObject := nil;

    try
      RttiType := Context.GetType(FeatureClass);
      RttiValue := RttiType.GetMethod('CreateFeature').Invoke(RttiType.AsInstance.MetaclassType, [WizardSettings]);
      FeatureObject := RttiValue.AsObject;
      FFeatureList.Add(FeatureObject)
    except
      on E: Exception do
      begin
        FreeAndNil(FeatureObject);
        Application.MessageBox(PWideChar('Error creating feature of class ' + FeatureClass.ClassName), PWideChar(WIZARD_HELP_MENU_CAPTION));
      end;
    end;
  end;
end;

procedure TFeatureCollection.InitAllFeatures;
var
  Feature: TObject;
begin
  for Feature in FFeatureList do
  begin
    if Feature is TBaseFeature then
      (Feature as TBaseFeature).InitFeature;
  end;
end;

procedure TFeatureCollection.InitFeaturesControls(ASettingsForm: TForm);
var
  Feature: TObject;
begin
  for Feature in FFeatureList do
    (Feature as TBaseFeature).InitFeatureControls(ASettingsForm);
end;

procedure TFeatureCollection.SaveFeaturesSettings;
var
  Feature: TObject;
  GlobalSettings: TWizardSettings;
  FeatureSettings: IXMLNode;
begin
  GlobalSettings := TDICEMainApp.GetDICEMainApp.WizardSettings;

  for Feature in FFeatureList do
  begin
    try
      FeatureSettings := GlobalSettings.GetXMLSettingsForFeature(Feature.ClassName);
      (Feature as TBaseFeature).WriteFeatureSettings(FeatureSettings);
    finally
      FeatureSettings := nil;
    end;
  end;
end;

initialization
  TFeatureCollection.FFeatureClassList := TClassList.Create;

finalization
  FreeAndNil(TFeatureCollection.FFeatureClassList);

end.
