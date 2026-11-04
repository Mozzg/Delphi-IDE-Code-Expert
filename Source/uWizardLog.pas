unit uWizardLog;

interface

uses
  ToolsAPI, System.SysUtils, System.Classes, Winapi.Windows,
  uWizardConsts;

type
  // Writes plugin messages into own tab of IDE Messages window.
  // Messages logged before IDE is loaded are kept and written when message view becomes ready.
  TWizardLogger = class(TObject)
  private
    FPendingMessages: TStringList;
    FMessageViewReady: Boolean;

    procedure WriteToMessageView(const AMessage: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Log(const AMessage: string);
    procedure LogException(const AContext: string; E: Exception);
    procedure SetMessageViewReady;
  end;

implementation

{ TWizardLogger }

constructor TWizardLogger.Create;
begin
  inherited Create;

  FPendingMessages := TStringList.Create;
  FMessageViewReady := False;
end;

destructor TWizardLogger.Destroy;
begin
  FreeAndNil(FPendingMessages);

  inherited Destroy;
end;

procedure TWizardLogger.Log(const AMessage: string);
begin
  if FMessageViewReady then
    WriteToMessageView(AMessage)
  else
    FPendingMessages.Add(AMessage);
end;

procedure TWizardLogger.LogException(const AContext: string; E: Exception);
begin
  Log(AContext + ', ' + E.ClassName + ': ' + E.Message);
end;

procedure TWizardLogger.SetMessageViewReady;
var
  PendingMessage: string;
begin
  FMessageViewReady := True;

  for PendingMessage in FPendingMessages do
    WriteToMessageView(PendingMessage);
  FPendingMessages.Clear;
end;

procedure TWizardLogger.WriteToMessageView(const AMessage: string);
var
  MessageServices: IOTAMessageServices;
  MessageGroup: IOTAMessageGroup;
begin
  {$IFDEF RELEASE}
  Exit;
  {$ENDIF}

  try
    if Supports(BorlandIDEServices, IOTAMessageServices, MessageServices) then
    begin
      // Group is not stored, because IDE deletes it when user closes the tab
      MessageGroup := MessageServices.GetGroup(WIZARD_NAME);
      if not Assigned(MessageGroup) then
        MessageGroup := MessageServices.AddMessageGroup(WIZARD_NAME);

      MessageServices.AddTitleMessage(AMessage, MessageGroup);
      MessageServices.ShowMessageView(MessageGroup);
    end;
  except
    on E: Exception do
      OutputDebugString(PWideChar('Error while writing to message log: ' + E.Message));
  end;
end;

end.
