unit uRemoveFormatShortcutFeature;

interface

uses
  Vcl.Forms, Vcl.StdCtrls, Vcl.ActnList, Vcl.Menus, System.Classes, System.SysUtils,
  uBaseFeature, ufmWizardSettings, uFeatureCollection;

type
  TRemoveFormatShortcutFeature = class(TBaseFeature)
  private
    FOldShortcut: TShortCut;
    FSettingsCheckBox: TCheckBox;  // Parent will be frame, so no need to free

    procedure SettingsCheckBoxClick(Sender: TObject);
  protected
    procedure SetFeatureEnabled(Value: Boolean); override;
  public
    procedure InitFeature; override;
    procedure InitFeatureControls(ASettingsForm: TfmWizardSettings); override;
  end;

implementation

{ TRemoveFormatShortcutFeature }

procedure TRemoveFormatShortcutFeature.SettingsCheckBoxClick(Sender: TObject);
begin
  ApplyCheckBoxState(Sender as TCheckBox);
end;

procedure TRemoveFormatShortcutFeature.SetFeatureEnabled(Value: Boolean);
const
  COMMA_BOOL_ARRAY: array [False .. True] of string = (', ', '');
var
  FoundComponent: TComponent;
  FormatActionTogether: TAction;
  FormatActionPopup: TAction;
  FormatMenuItem: TMenuItem;
  ExceptionMessage: string;
  ShortCutTemp: TShortCut;
begin
  if FFeatureEnabled = Value then Exit;

  FormatActionTogether := nil;
  FormatActionPopup := nil;

  // Finding action from DataModule
  FoundComponent := Application.FindComponent('TogetherCommands');
  if Assigned(FoundComponent) then
  begin
    FoundComponent := FoundComponent.FindComponent('actnFormatSource');
    if Assigned(FoundComponent) and (FoundComponent is TAction) then
      FormatActionTogether := FoundComponent as TAction;
  end;

  //Finding action from PopupMenu
  if Assigned(Application.MainForm) then
    FoundComponent := Application.MainForm.FindComponent('mnuFormatSource')
  else
    FoundComponent := nil;
  if Assigned(FoundComponent) and (FoundComponent is TMenuItem) then
  begin
    FormatMenuItem := FoundComponent as TMenuItem;
    if Assigned(FormatMenuItem.Action) then
      FormatActionPopup := FormatMenuItem.Action as TAction;
  end;

  // Actions are searched each time instead of being stored, because IDE can destroy them
  // before plugin is unloaded. If they are already destroyed when disabling, there is nothing to restore.
  if Assigned(FormatActionTogether) and Assigned(FormatActionPopup) then
  begin
    // Changing shortcut
    ShortCutTemp := FormatActionTogether.ShortCut;
    FormatActionTogether.ShortCut := FOldShortcut;
    FormatActionPopup.ShortCut := FOldShortcut;
    FOldShortcut := ShortCutTemp;
  end
  else if Value then
  begin
    ExceptionMessage := EmptyStr;
    if not Assigned(FormatActionTogether) then
      ExceptionMessage := 'global format action';
    if not Assigned(FormatActionPopup) then
      ExceptionMessage := ExceptionMessage + COMMA_BOOL_ARRAY[ExceptionMessage = EmptyStr] + 'popup format action';
    ExceptionMessage := 'Did not found ' + ExceptionMessage;
    raise Exception.Create(ExceptionMessage);
  end
  else
    FOldShortcut := 0;

  FFeatureEnabled := Value;

  if Assigned(FSettingsCheckBox) then
    FSettingsCheckBox.Checked := FFeatureEnabled;
end;

procedure TRemoveFormatShortcutFeature.InitFeature;
begin
  FOldShortcut := 0;
  inherited InitFeature;
end;

procedure TRemoveFormatShortcutFeature.InitFeatureControls(ASettingsForm: TfmWizardSettings);
begin
  try
    FSettingsCheckBox := TCheckBox.Create(nil);
    FSettingsCheckBox.Name := 'cbRemoveFormatShortcut';
    FSettingsCheckBox.Caption := 'Remove Format source shortcut';
    FSettingsCheckBox.Left := 100;
    FSettingsCheckBox.Top := 100;
    FSettingsCheckBox.OnClick := SettingsCheckBoxClick;
    FSettingsCheckBox.Checked := FeatureEnabled;

    // Assigning parent to control
    ASettingsForm.AddSettingsControl('Global', FSettingsCheckBox);
  except
    on E: Exception do
    begin
      FreeAndNil(FSettingsCheckBox);
      FLogger.LogException('Error creating settings controls of feature ' + ClassName, E);
    end;
  end;
end;

initialization
  TFeatureCollection.RegisterFeature(TRemoveFormatShortcutFeature);

end.
