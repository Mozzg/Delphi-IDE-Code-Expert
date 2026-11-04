unit uWizardConsts;

interface

const
  // Identifiers used by IDE and in component names, must not be translated
  WIZARD_ID_STRING = 'Mozzg.DICE';
  WIZARD_SETTINGS_MENU_ITEM_NAME = 'miDICEMenuItem';

resourcestring
  WIZARD_NAME = 'DICE';
  WIZARD_HELP_MENU_CAPTION = 'DICE Wizard';
  WIZARD_PRODUCT_NAME = 'Delphi IDE Code Expert (DICE)';
  WIZARD_COPYRIGHT_TEXT = 'Copyright © 2024-2026 Evgeny "Mozzg" Pervov';
  WIZARD_LICENCE_TEXT = 'zlib license';
  WIZARD_HELP_MENU_TEXT = '%s'{$IFDEF DEBUG}+ ' debug version'{$ENDIF} + sLineBreak
      + 'IDE plugin for RAD Studio' + sLineBreak + sLineBreak + '%s, %s';
  WIZARD_ABOUT_TEXT = '%s'{$IFDEF DEBUG}+ ' debug version'{$ENDIF} + sLineBreak
      + 'IDE plugin for RAD Studio' + sLineBreak + sLineBreak + '%s';
  WIZARD_SPLASH_TEXT = 'v%d.%d%s';
  WIZARD_SETTINGS_MENU_ITEM_CAPTION = 'DICE Configuration';

implementation

end.
