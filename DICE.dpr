library DICE;

{ Delphi IDE Code Expert by Evgeny "Mozzg" Pervov }

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$R *.res}

{$R 'DICERecources.res' 'Resources\DICERecources.rc'}

uses
  ToolsAPI,
  uWizardMain in 'Source\uWizardMain.pas',
  uWizardConsts in 'Source\uWizardConsts.pas',
  uHooking in 'Source\uHooking.pas',
  uFeatureCollection in 'Source\uFeatureCollection.pas',
  ufrBaseSettings in 'Source\Forms\ufrBaseSettings.pas' {frBaseSettings: TFrame},
  uBaseFeature in 'Source\uBaseFeature.pas',
  uWizardSettings in 'Source\uWizardSettings.pas',
  ufmWizardSettings in 'Source\Forms\ufmWizardSettings.pas' {fmWizardSettings},
  uRemoveExplicitFeature in 'Source\uRemoveExplicitFeature.pas';

exports
  InitWizard name WizardEntryPoint;

begin
end.
