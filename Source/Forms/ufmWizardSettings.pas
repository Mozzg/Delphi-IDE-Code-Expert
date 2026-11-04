unit ufmWizardSettings;

interface

uses
  Vcl.Forms, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Controls, System.Classes, Vcl.StdCtrls,
  System.SysUtils, System.Contnrs, Winapi.Windows, Vcl.Graphics,
  uWizardConsts, ufrBaseSettings, uWizardUtils;

type
  TfmWizardSettings = class(TForm)
    pnButtons: TPanel;
    btnOK: TButton;
    pnMain: TPanel;
    tvSections: TTreeView;
    pnFrameSettingsContainer: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tvSectionsChange(Sender: TObject; Node: TTreeNode);
    procedure FormShow(Sender: TObject);
  private
    FFrameList: TObjectList;
    FCurrentVisibleFrame: TfrBaseSettings;

    function CreateIconFromBitmapRes(const AResName: string): HICON;
    function CreateNewSection(const ANewSectionName: string): TTreeNode;
    procedure AddControlToSection(TreeNode: TTreeNode; AControl: TControl);
  public
    procedure InitSectionsTree;
    procedure AddSettingsControl(const ASectionName: string; AControl: TControl);
  end;

implementation

{$R *.dfm}

function TfmWizardSettings.CreateIconFromBitmapRes(const AResName: string): HICON;
var
  ColorBitmap: Vcl.Graphics.TBitmap;
  MaskBits: TBytes;
  MaskHandle: HBITMAP;
  IconInfo: TIconInfo;
begin
  ColorBitmap := LoadMenuBitmap(AResName);  // 32-bit with alpha
  try
    // Mask is ignored for 32-bit icons with alpha, but must exist and be zeroed
    SetLength(MaskBits, ((ColorBitmap.Width + 15) div 16) * 2 * ColorBitmap.Height);
    MaskHandle := CreateBitmap(ColorBitmap.Width, ColorBitmap.Height, 1, 1, MaskBits);
    try
      IconInfo.fIcon := True;
      IconInfo.xHotspot := 0;
      IconInfo.yHotspot := 0;
      IconInfo.hbmMask := MaskHandle;
      IconInfo.hbmColor := ColorBitmap.Handle;
      Result := CreateIconIndirect(IconInfo);  // copies both bitmaps
    finally
      DeleteObject(MaskHandle);
    end;
  finally
    ColorBitmap.Free;
  end;
end;

function TfmWizardSettings.CreateNewSection(const ANewSectionName: string): TTreeNode;
var
  FrameIndex: Integer;
  NewFrame: TfrBaseSettings;
begin
  try
    NewFrame := TfrBaseSettings.Create(pnFrameSettingsContainer);
    NewFrame.Visible := False;
    NewFrame.Name := 'Frame' + IntToStr(FFrameList.Count);
    NewFrame.FrameCaption := ANewSectionName;
    NewFrame.Parent := pnFrameSettingsContainer;
    NewFrame.Align := alClient;
    // Need to be here, because frame dimensions doesn't change until frame is visible
    NewFrame.Top := 0;
    NewFrame.Left := 0;
    NewFrame.Width := pnFrameSettingsContainer.Width;
    NewFrame.Height := pnFrameSettingsContainer.Height;
    FrameIndex := FFrameList.Add(NewFrame);
  except
    on E: Exception do
      raise Exception.Create('Error creating settings section frame, message: ' + E.Message);
  end;

  Result := tvSections.Items.AddNode(nil, nil, ANewSectionName, FFrameList.Items[FrameIndex], naAdd);
end;

procedure TfmWizardSettings.AddControlToSection(TreeNode: TTreeNode; AControl: TControl);
var
  SectionFrame: TfrBaseSettings;
  NewNode: TTreeNode;
begin
  SectionFrame := TfrBaseSettings(TreeNode.Data);

  if not SectionFrame.TryAddControl(AControl) then
  begin
    NewNode := CreateNewSection(TreeNode.Text + '_');
    AddControlToSection(NewNode, AControl);
  end;
end;

procedure TfmWizardSettings.InitSectionsTree;
begin
  if tvSections.Items.Count > 0 then
    tvSections.Select(tvSections.Items.GetFirstNode, [ssLeft]);
end;

procedure TfmWizardSettings.AddSettingsControl(const ASectionName: string; AControl: TControl);
var
  Node: TTreeNode;
  i: Integer;
begin
  Node := nil;
  for i := 0 to tvSections.Items.Count - 1 do
    if SameText(ASectionName, tvSections.Items[i].Text) then
    begin
      Node := tvSections.Items[i];
      Break;
    end;

  if not Assigned(Node) then
    Node := CreateNewSection(ASectionName);

  AddControlToSection(Node, AControl);
end;

procedure TfmWizardSettings.FormCreate(Sender: TObject);
begin
  FFrameList := TObjectList.Create(False);
  Caption := WIZARD_SETTINGS_MENU_ITEM_CAPTION;
  Self.Icon.Handle := CreateIconFromBitmapRes('DICEABOUTHBMP');
end;

procedure TfmWizardSettings.FormDestroy(Sender: TObject);
begin
  tvSections.Items.Clear;
end;

procedure TfmWizardSettings.FormShow(Sender: TObject);
begin
  FocusControl(tvSections);
end;

procedure TfmWizardSettings.tvSectionsChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(FCurrentVisibleFrame) then
  begin
    FCurrentVisibleFrame.Visible := False;
    FCurrentVisibleFrame := nil;
  end;

  FCurrentVisibleFrame := TfrBaseSettings(Node.Data);
  FCurrentVisibleFrame.Visible := True;
end;

end.
