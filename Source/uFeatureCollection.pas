unit uFeatureCollection;

interface

uses
  System.Contnrs, System.SysUtils, System.Rtti, Xml.XMLIntf, Winapi.Windows,
  uWizardConsts, uBaseFeature, uWizardSettings, uWizardLog, ufmWizardSettings;

type
  TFeatureCollection = class(TObject)
  private
    class var FFeatureClassList: TClassList;
  private
    FFeatureList: TObjectList;
    FWizardSettings: TWizardSettings;
    FLogger: TWizardLogger;
  public
    constructor Create(AWizardSettings: TWizardSettings; ALogger: TWizardLogger);
    destructor Destroy; override;

    class procedure RegisterFeature(AFeatureClass: TClass);

    procedure CreateAllFeatures;
    procedure InitAllFeatures;
    procedure InitFeaturesControls(ASettingsForm: TfmWizardSettings);
    procedure SaveFeaturesSettings;
    procedure FinalizeAllFeatures;
  end;

implementation

{ TFeatureCollection }

constructor TFeatureCollection.Create(AWizardSettings: TWizardSettings; ALogger: TWizardLogger);
begin
  inherited Create;

  FFeatureList := TObjectList.Create(True);
  FWizardSettings := AWizardSettings;
  FLogger := ALogger;
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

procedure TFeatureCollection.CreateAllFeatures;
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
      RttiValue := RttiType.GetMethod('CreateFeature').Invoke(RttiType.AsInstance.MetaclassType, [FWizardSettings, FLogger]);
      FeatureObject := RttiValue.AsObject;
      FFeatureList.Add(FeatureObject)
    except
      on E: Exception do
      begin
        FreeAndNil(FeatureObject);
        FLogger.LogException('Error creating feature of class ' + FeatureClass.ClassName, E);
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
    // Error in one feature must not stop initialization of the others
    try
      if Feature is TBaseFeature then
        (Feature as TBaseFeature).InitFeature;
    except
      on E: Exception do
        FLogger.LogException('Error initializing feature ' + Feature.ClassName, E);
    end;
  end;
end;

procedure TFeatureCollection.InitFeaturesControls(ASettingsForm: TfmWizardSettings);
var
  Feature: TObject;
begin
  for Feature in FFeatureList do
    (Feature as TBaseFeature).InitFeatureControls(ASettingsForm);
end;

procedure TFeatureCollection.SaveFeaturesSettings;
var
  Feature: TObject;
  FeatureSettings: IXMLNode;
begin
  for Feature in FFeatureList do
  begin
    try
      FeatureSettings := FWizardSettings.GetXMLSettingsForFeature(Feature.ClassName);
      (Feature as TBaseFeature).WriteFeatureSettings(FeatureSettings);
    finally
      FeatureSettings := nil;
    end;
  end;
end;

procedure TFeatureCollection.FinalizeAllFeatures;
var
  i: Integer;
  Feature: TBaseFeature;
begin
  // Reverse order, so features are rolled back in the opposite order of their initialization.
  // IDE is shutting down, so errors are not shown, only reported to the debugger.
  for i := FFeatureList.Count - 1 downto 0 do
  begin
    Feature := FFeatureList.Items[i] as TBaseFeature;
    try
      Feature.FinalizeFeature;
    except
      on E: Exception do
        OutputDebugString(PWideChar(WIZARD_NAME + ': error finalizing feature ' + Feature.ClassName + ', message: ' + E.Message));
    end;
  end;
end;

initialization
  TFeatureCollection.FFeatureClassList := TClassList.Create;

finalization
  FreeAndNil(TFeatureCollection.FFeatureClassList);

end.
