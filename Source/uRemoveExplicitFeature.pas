unit uRemoveExplicitFeature;

interface

uses
  Vcl.Dialogs, System.Classes, System.SysUtils, Vcl.Controls, Vcl.StdCtrls,
  Vcl.Forms, Xml.XMLIntf, System.Variants,
  uBaseFeature, uHooking, ufmWizardSettings, uWizardSettings;

type
  TRemoveExplicitPropertyFeature = class(TBaseFeature)
  private
    FHookEnabled: Boolean;
    FExplicitHook: TRedirectCode;
    FSettingsCheckBox: TCheckBox;

    procedure SettingsCheckBoxClick(Sender: TObject);
  protected
    function GetFeatureEnabled: Boolean; override;
    procedure SetFeatureEnabled(Value: Boolean); override;
  public
    constructor CreateFeature(WizardSettings: TWizardSettings); override;
    destructor Destroy; override;

    procedure InitFeature; override;
    procedure InitFeatureControls(ASettingsForm: TForm); override;

    procedure ReadFeatureSettings(AFeatureSettings: IXMLNode); override;
    procedure WriteFeatureSettings(AFeatureSettings: IXMLNode); override;

    property FeatureEnabled;
  end;

implementation

uses
  uFeatureCollection;

type
  TControlEx = class(TControl)
  protected
    procedure ReadIsControl(Reader: TReader);
    procedure WriteIsControl(Writer: TWriter);

    procedure WriteExplicitLeft(Writer: TWriter);
    procedure WriteExplicitTop(Writer: TWriter);
    procedure WriteExplicitWidth(Writer: TWriter);
    procedure WriteExplicitHeight(Writer: TWriter);

    procedure ReadExplicitLeft(Reader: TReader);
    procedure ReadExplicitTop(Reader: TReader);
    procedure ReadExplicitWidth(Reader: TReader);
    procedure ReadExplicitHeight(Reader: TReader);

    procedure IgnoreInteger(Reader: TReader);

    procedure DefineProperties(Filer: TFiler); override;
  end;

  TOpenControl = class(TControl);

{ TRemoveExplicitPropertyFeature }

constructor TRemoveExplicitPropertyFeature.CreateFeature(WizardSettings: TWizardSettings);
begin
  inherited CreateFeature(WizardSettings);

  FHookEnabled := False;
end;

destructor TRemoveExplicitPropertyFeature.Destroy;
begin
  inherited Destroy;
end;

procedure TRemoveExplicitPropertyFeature.SettingsCheckBoxClick(Sender: TObject);
begin
  FeatureEnabled := (Sender as TCheckBox).Checked;
end;

function TRemoveExplicitPropertyFeature.GetFeatureEnabled: Boolean;
begin
  Result := FHookEnabled;
end;

procedure TRemoveExplicitPropertyFeature.SetFeatureEnabled(Value: Boolean);
begin
  if FHookEnabled = Value then Exit;

  FHookEnabled := Value;
  if FHookEnabled then
    CodeRedirect(@TOpenControl.DefineProperties, @TControlEx.DefineProperties, FExplicitHook)
  else
    UnhookFunction(FExplicitHook);

  if Assigned(FSettingsCheckBox) then
    FSettingsCheckBox.Checked := FHookEnabled;
end;

procedure TRemoveExplicitPropertyFeature.InitFeature;
begin
  inherited InitFeature;
end;

{procedure TRemoveExplicitPropertyFeature.DisableFeature;
begin
  if not FHookEnabled then Exit;

  UnhookFunction(FExplicitHook);
  FHookEnabled := False;
end;    }

procedure TRemoveExplicitPropertyFeature.InitFeatureControls(ASettingsForm: TForm);
begin
  try
    FSettingsCheckBox := TCheckBox.Create(nil);
    FSettingsCheckBox.Name := 'cbRemoveExplicit';
    FSettingsCheckBox.Caption := 'Remove Explicit properties';
    FSettingsCheckBox.Left := 100;
    FSettingsCheckBox.Top := 100;
    FSettingsCheckBox.OnClick := SettingsCheckBoxClick;
    FSettingsCheckBox.Checked := FeatureEnabled;

    TfmWizardSettings(ASettingsForm).AddSettingsControl('Global', FSettingsCheckBox);
  except
    FreeAndNil(FSettingsCheckBox);
  end;
end;

procedure TRemoveExplicitPropertyFeature.ReadFeatureSettings(AFeatureSettings: IXMLNode);
var
  FeatureEnabledSetting: OleVariant;
begin
  FeatureEnabledSetting := AFeatureSettings.Attributes['Enabled'];
  if not VarIsNull(FeatureEnabledSetting) then
    FeatureEnabled := FeatureEnabledSetting;
end;

procedure TRemoveExplicitPropertyFeature.WriteFeatureSettings(AFeatureSettings: IXMLNode);
begin
  AFeatureSettings.Attributes['Enabled'] := FeatureEnabled;
end;

{ TControlEx }

procedure TControlEx.ReadIsControl(Reader: TReader);
begin
  IsControl := Reader.ReadBoolean;
end;

procedure TControlEx.WriteIsControl(Writer: TWriter);
begin
  Writer.WriteBoolean(IsControl);
end;

procedure TControlEx.WriteExplicitTop(Writer: TWriter);
begin
  Writer.WriteInteger(FExplicitTop);
end;

procedure TControlEx.WriteExplicitHeight(Writer: TWriter);
begin
  Writer.WriteInteger(FExplicitHeight);
end;

procedure TControlEx.WriteExplicitLeft(Writer: TWriter);
begin
  Writer.WriteInteger(FExplicitLeft);
end;

procedure TControlEx.ReadExplicitWidth(Reader: TReader);
begin
  FExplicitWidth := Reader.ReadInteger;
end;

procedure TControlEx.WriteExplicitWidth(Writer: TWriter);
begin
  Writer.WriteInteger(FExplicitWidth);
end;

procedure TControlEx.ReadExplicitTop(Reader: TReader);
begin
  FExplicitTop := Reader.ReadInteger;
end;

procedure TControlEx.ReadExplicitHeight(Reader: TReader);
begin
  FExplicitHeight := Reader.ReadInteger;
end;

procedure TControlEx.ReadExplicitLeft(Reader: TReader);
begin
  FExplicitLeft := Reader.ReadInteger;
end;

procedure TControlEx.IgnoreInteger(Reader: TReader);
begin
  Reader.ReadInteger;
end;

procedure TControlEx.DefineProperties(Filer: TFiler);
type
  TExplicitDimension = (edLeft, edTop, edWidth, edHeight);

  function DoWriteIsControl: Boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := TControlEx(Filer.Ancestor).IsControl <> IsControl else
      Result := IsControl;
  end;

  function DoWriteExplicit(Dim: TExplicitDimension): Boolean;
  begin
    case Dim of
      edLeft: Result := ((Filer.Ancestor <> nil) and (TControl(Filer.Ancestor).ExplicitLeft <> FExplicitLeft)) or
        ((Filer.Ancestor = nil) and ((Align <> alNone) or ((Anchors * [akLeft]) = [])) and (FExplicitLeft <> Left));
      edTop: Result := ((Filer.Ancestor <> nil) and (TControl(Filer.Ancestor).ExplicitTop <> FExplicitTop)) or
        ((Filer.Ancestor = nil) and ((Align <> alNone) or ((Anchors * [akTop]) = [])) and (FExplicitTop <> Top));
      edWidth: Result := ((Filer.Ancestor <> nil) and (TControl(Filer.Ancestor).ExplicitWidth <> FExplicitWidth)) or
        ((Filer.Ancestor = nil) and ((Align <> alNone) or ((Anchors * [akLeft, akRight]) = [akLeft, akRight])) and (FExplicitWidth <> Width));
      edHeight: Result := ((Filer.Ancestor <> nil) and (TControl(Filer.Ancestor).ExplicitHeight <> FExplicitHeight)) or
        ((Filer.Ancestor = nil) and ((Align <> alNone) or ((Anchors * [akTop, akBottom]) = [akTop, akBottom])) and (FExplicitHeight <> Height));
    else
      Result := False;
    end;
  end;

begin
  { The call to inherited DefinedProperties is omitted since the Left and
    Top special properties are redefined with real properties }
  Filer.DefineProperty('IsControl', ReadIsControl, WriteIsControl, DoWriteIsControl);

  if csDesigning in ComponentState then
  begin
    Filer.DefineProperty('ExplicitLeft', IgnoreInteger, nil, False);
    Filer.DefineProperty('ExplicitTop', IgnoreInteger, nil, False);
    Filer.DefineProperty('ExplicitWidth', IgnoreInteger, nil, False);
    Filer.DefineProperty('ExplicitHeight', IgnoreInteger, nil, False);
  end
  else
  begin
    Filer.DefineProperty('ExplicitLeft', ReadExplicitLeft, WriteExplicitLeft, not (csReading in ComponentState) and DoWriteExplicit(edLeft));
    Filer.DefineProperty('ExplicitTop', ReadExplicitTop, WriteExplicitTop, not (csReading in ComponentState) and DoWriteExplicit(edTop));
    Filer.DefineProperty('ExplicitWidth', ReadExplicitWidth, WriteExplicitWidth, not (csReading in ComponentState) and DoWriteExplicit(edWidth));
    Filer.DefineProperty('ExplicitHeight', ReadExplicitHeight, WriteExplicitHeight, not (csReading in ComponentState) and DoWriteExplicit(edHeight));
  end;
end;

initialization
  TFeatureCollection.RegisterFeature(TRemoveExplicitPropertyFeature);

end.
