#define GameName "风云：山河劫"
#define GameVersion "2.3.0"
#define ProjectUrl "https://github.com/peterwangze/fengyun"

#if GetVersionNumbersString(AddBackslash(SourcePath) + "Fengyun.exe") != GameVersion + ".0"
  #error Export Fengyun.exe with the version declared in this script before compiling Setup.
#endif

[Setup]
AppId=io.github.peterwangze.fengyun
AppName={#GameName}
AppVersion={#GameVersion}
AppPublisher={#GameName}项目
AppPublisherURL={#ProjectUrl}
AppSupportURL={#ProjectUrl}/issues
AppUpdatesURL={#ProjectUrl}/releases/latest
DefaultDirName={localappdata}\Programs\Fengyun
DisableDirPage=no
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\Fengyun.ico
SetupIconFile=Installer\Fengyun.ico
VersionInfoVersion={#GameVersion}.0
VersionInfoProductName={#GameName}
VersionInfoProductVersion={#GameVersion}
VersionInfoDescription={#GameName} Windows 安装程序
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
RestartApplications=no
OutputDir=.
OutputBaseFilename=Fengyun-{#GameVersion}-windows-x64-setup

[Languages]
Name: "zh_cn"; MessagesFile: "Installer\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; Flags: unchecked

[Files]
Source: "Fengyun.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "Installer\Fengyun.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "游玩说明.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "Licenses\*.txt"; DestDir: "{app}\Licenses"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#GameName}"; Filename: "{app}\Fengyun.exe"; WorkingDir: "{app}"; IconFilename: "{app}\Fengyun.ico"
Name: "{autodesktop}\{#GameName}"; Filename: "{app}\Fengyun.exe"; WorkingDir: "{app}"; IconFilename: "{app}\Fengyun.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\Fengyun.exe"; Description: "启动{#GameName}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent
