#define MyAppName "Oráculo Diosa Fortuna"
#define MyAppVersion "0.4.0"
#define MyAppPublisher "Prime Innovation Thinking"
#define MyAppExeName "oraculo_diosa_fortuna.exe"

[Setup]
AppId={{8B7B69D6-DC20-4F86-9E7D-ORACULODIOSAFORTUNA}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\OraculoDiosaFortuna
DefaultGroupName={#MyAppName}
OutputDir=output
OutputBaseFilename=Oraculo_Diosa_Fortuna_Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir {#MyAppName}"; Flags: nowait postinstall skipifsilent
