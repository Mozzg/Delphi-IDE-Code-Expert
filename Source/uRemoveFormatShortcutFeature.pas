unit uRemoveFormatShortcutFeature;

interface

uses
  Vcl.Forms, Vcl.StdCtrls, Vcl.ActnList, Vcl.Menus, System.Classes, System.SysUtils,
  uBaseFeature, ufmWizardSettings, Vcl.Dialogs, uFeatureCollection;

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
    procedure InitFeatureControls(ASettingsForm: TForm); override;
  end;

implementation

{ TRemoveFormatShortcutFeature }

procedure TRemoveFormatShortcutFeature.SettingsCheckBoxClick(Sender: TObject);
begin
  FeatureEnabled := (Sender as TCheckBox).Checked;
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
  FoundComponent := Application.MainForm.FindComponent('mnuFormatSource');
  if Assigned(FoundComponent) and (FoundComponent is TMenuItem) then
  begin
    FormatMenuItem := FoundComponent as TMenuItem;
    if Assigned(FormatMenuItem.Action) then
      FormatActionPopup := FormatMenuItem.Action as TAction;
  end;

  if not(Assigned(FormatActionTogether) and Assigned(FormatActionPopup)) then
  begin
    ExceptionMessage := EmptyStr;
    if not Assigned(FormatActionTogether) then
      ExceptionMessage := 'global format action';
    if not Assigned(FormatActionPopup) then
      ExceptionMessage := ExceptionMessage + COMMA_BOOL_ARRAY[ExceptionMessage = EmptyStr] + 'popup format action';
    ExceptionMessage := 'Did not found ' + ExceptionMessage;
    raise Exception.Create(ExceptionMessage);
  end;

  // Changind shortcut
  ShortCutTemp := FormatActionTogether.ShortCut;
  FormatActionTogether.ShortCut := FOldShortcut;
  FormatActionPopup.ShortCut := FOldShortcut;
  FOldShortcut := ShortCutTemp;

  FFeatureEnabled := Value;

  if Assigned(FSettingsCheckBox) then
    FSettingsCheckBox.Checked := FFeatureEnabled;
end;

procedure TRemoveFormatShortcutFeature.InitFeature;
begin
  inherited InitFeature;

  FOldShortcut := 0;
end;

procedure TRemoveFormatShortcutFeature.InitFeatureControls(ASettingsForm: TForm);
begin
  try
    FSettingsCheckBox := TCheckBox.Create(nil);
    FSettingsCheckBox.Name := 'cbRemoveFormatShortcut';
    FSettingsCheckBox.Caption := 'Remove Format source shortcut';
    FSettingsCheckBox.Left := 100;
    FSettingsCheckBox.Top := 100;
    FSettingsCheckBox.OnClick := SettingsCheckBoxClick;
    FSettingsCheckBox.Checked := FeatureEnabled;

    // Assinging parent to control
    TfmWizardSettings(ASettingsForm).AddSettingsControl('Global', FSettingsCheckBox);
  except
    FreeAndNil(FSettingsCheckBox);
  end;
end;

initialization
  TFeatureCollection.RegisterFeature(TRemoveFormatShortcutFeature);

end.
