unit uFeatureCollection;

interface

uses
  System.Contnrs, System.SysUtils, System.Rtti, Vcl.Forms, Xml.XMLIntf,
  Winapi.Windows,
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
    procedure FinalizeAllFeatures;
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
        TDICEMainApp.GetDICEMainApp.Logger.LogException('Error creating feature of class ' + FeatureClass.ClassName, E);
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
        TDICEMainApp.GetDICEMainApp.Logger.LogException('Error initializing feature ' + Feature.ClassName, E);
    end;
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
