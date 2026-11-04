# Delphi-IDE-Code-Expert

Delphi IDE Code Expert (DICE) is a DLL expert (plugin) for the RAD Studio / Delphi IDE.

## Features

Each feature can be switched on and off in **Tools > DICE Configuration**.

- **Remove Explicit properties.** When a form or frame is saved, the IDE no longer writes
  `ExplicitLeft`, `ExplicitTop`, `ExplicitWidth` and `ExplicitHeight` to the `.dfm` file,
  so form files have fewer meaningless changes in version control.
- **Remove Format source shortcut.** Removes the shortcut of the *Format Source* command
  (Ctrl+D by default), so the whole unit is not reformatted by an accidental key press.
  The command is still available from the editor context menu.

All changes made to the IDE are rolled back when a feature is switched off or the plugin is unloaded.

## Supported IDE versions

- Delphi 11 Alexandria (`BDS\22.0`) - tested.
- Newer versions compile with a warning that the plugin is not tested for them.
- Older versions are not supported (compilation stops with an error).

Only the 32-bit IDE (`bds.exe`) is supported, the project has the Win32 platform only.

## Building

1. Open `DICE.dproj` in the IDE.
2. Select the **Release** configuration, platform **Win32**, and build the project.

The DLL is written to `Bin\Win32`. In the Release configuration the file name gets the IDE
version suffix (`{$LIBSUFFIX AUTO}`), for example `DICE280.dll` for Delphi 11, so builds for
different IDE versions don't overwrite each other. DCU files are written to
`DCU\<IDE version>\Win32\<config>`.

## Installation

1. Close the IDE.
2. Add a string value to the registry key of your IDE version, for Delphi 11:

   ```
   HKEY_CURRENT_USER\Software\Embarcadero\BDS\22.0\Experts
   ```

   Value name: `DICE`, value data: full path to the DLL, for example
   `C:\Projects\Delphi-IDE-Code-Expert\Bin\Win32\DICE280.dll`.

   The same can be done from the command line:

   ```
   reg add "HKCU\Software\Embarcadero\BDS\22.0\Experts" /v DICE /t REG_SZ /d "C:\Projects\Delphi-IDE-Code-Expert\Bin\Win32\DICE280.dll"
   ```

3. Start the IDE. DICE is shown on the splash screen and in **Help > About**.

To uninstall, close the IDE and delete the `DICE` value from the `Experts` key.

## Settings and log

- Settings are stored in `%APPDATA%\DICE\DICE.xml`.
- Plugin messages are written to the **DICE** tab of the IDE Messages window.
  The Release build writes only errors, the Debug build also writes information messages.

## Debugging

The **Debug** configuration starts a second IDE instance as the host application:

```
$(BDS)\bin\bds.exe -pDelphi -rOpenToolsAPI
```

`-rOpenToolsAPI` makes this instance use its own registry branch
(`HKCU\Software\Embarcadero\OpenToolsAPI\22.0` for Delphi 11), so the debugged plugin doesn't affect
your working IDE. Start the debug instance once to create this branch, close it, then register the
Debug DLL (`Bin\Win32\DICE.dll`) in its `Experts` key the same way as described in *Installation*.

The pre-build event runs `movedll.cmd`, which renames the DLL loaded by the debug instance, so the
project can be rebuilt without closing it.

## License

zlib license, see [LICENSE](LICENSE).
