{$I jedi.inc}

{$IFDEF UNKNOWN_COMPILER_VERSION}
  {$MESSAGE Error 'Unknown compiler version. Please adjust jedi.inc.'}
{$ENDIF}

{$IFDEF DELPHICOMPILER1_UP}
  {$IFNDEF DELPHI28_UP} // Delphi 11+
    {$MESSAGE Error 'Compilation is not supported for this Delphi version.'}
  {$ENDIF}

  {$IFDEF RELEASE}
    {$LIBSUFFIX AUTO}
  {$ENDIF}

  {$IFDEF DELPHI29_UP}
    {$MESSAGE Warn 'Plugin is not tested for this Delphi version.'}
  {$ENDIF}
{$ELSE}
  {$MESSAGE Error 'Compiler is not Delphi. Please adjust jedi.inc or LibSuffixes.inc.'}
{$ENDIF}
