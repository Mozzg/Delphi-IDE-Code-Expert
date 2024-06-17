unit uWizardSettings;

interface

uses
  System.SysUtils, Xml.XMLDoc, Xml.XMLIntf, System.IOUtils, Winapi.Windows,
  ufmWizardSettings, uWizardConsts;

type
  TWizardSettings = class(TObject)
  private
    FSettingsForm: TfmWizardSettings;
    FXMLDocSettings: IXMLDocument;
    FSettingsFilePath: string;

    function GetDLLPath: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure InitXMLSettings;
    procedure FlushXMLSettings;
    function GetXMLSettingsForFeature(const AFeatureName: string): IXMLNode;

    procedure ShowModalSettingsForm;
  end;

implementation

uses
  uWizardMain;

{ TWizardSettings }

constructor TWizardSettings.Create;
begin
  inherited Create;
end;

destructor TWizardSettings.Destroy;
begin
  FreeAndNil(FSettingsForm);
  FXMLDocSettings := nil;

  inherited Destroy;
end;

function TWizardSettings.GetDLLPath: string;
var
  ModuleName: array[0..255] of WideChar;
begin
  GetModuleFileName(HInstance, @ModuleName[0], SizeOf(ModuleName));
  Result := ModuleName;
end;

procedure TWizardSettings.InitXMLSettings;
begin
  FSettingsFilePath := IncludeTrailingPathDelimiter(TPath.GetHomePath) + WIZARD_NAME + '\' + WIZARD_NAME + '.xml';
  if not ForceDirectories(ExtractFilePath(FSettingsFilePath)) then
    FSettingsFilePath := IncludeTrailingPathDelimiter(GetDLLPath) + WIZARD_NAME + '.xml';

  try
    if not FileExists(FSettingsFilePath) then
    begin
      FXMLDocSettings := NewXMLDocument;
      FXMLDocSettings.AddChild('root');
      FXMLDocSettings.SaveToFile(FSettingsFilePath);
      FXMLDocSettings := nil;
    end;

    FXMLDocSettings := TXMLDocument.Create(FSettingsFilePath);
    FXMLDocSettings.Active := True;
    FXMLDocSettings.Options := [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doAutoSave];
    FXMLDocSettings.Encoding := 'UTF-8';
  except
    FXMLDocSettings := nil;
    FXMLDocSettings := NewXmlDocument;
    FXMLDocSettings.Options := [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doAutoSave];
  end;
end;

procedure TWizardSettings.FlushXMLSettings;
begin
  try
    if FXMLDocSettings.FileName <> FSettingsFilePath then
      FXMLDocSettings.FileName := FSettingsFilePath;
    FXMLDocSettings.SaveToFile(FSettingsFilePath);
  except
    on E: Exception do
      raise Exception.Create('Error saving ' + WIZARD_HELP_MENU_CAPTION + ' settings, message: ' + E.Message);
  end;
end;

function TWizardSettings.GetXMLSettingsForFeature(const AFeatureName: string): IXMLNode;
begin
  Result := FXMLDocSettings.DocumentElement.ChildNodes.Nodes[AFeatureName];
end;

procedure TWizardSettings.ShowModalSettingsForm;
begin
  if not Assigned(FSettingsForm) then
  begin
    FSettingsForm := TfmWizardSettings.Create(nil);
    TDICEMainApp.GetDICEMainApp.Features.InitFeaturesControls(FSettingsForm);
    FSettingsForm.InitSectionsTree;
  end;

  FSettingsForm.ShowModal;
  TDICEMainApp.GetDICEMainApp.Features.SaveFeaturesSettings;
  FlushXMLSettings;
end;

end.
