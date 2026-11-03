; Build through Scripts/package-installer.ps1, which stages the runtime closure.
#ifndef AppVersion
  #error AppVersion must be supplied by the packaging script
#endif

[Setup]
AppId={{46D67F11-21CA-4472-9B0A-C93579143594}
AppName=Gecko
AppVersion={#AppVersion}
AppPublisher=Cole Roberts
AppPublisherURL=https://github.com/colealanroberts/Gecko
DefaultDirName={autopf}\Gecko
DefaultGroupName=Gecko
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\Gecko.exe
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
PrivilegesRequired=admin
OutputDir={#OutputDir}
OutputBaseFilename=GeckoSetup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
LicenseFile={#StageDir}\LICENSE
CloseApplications=yes
RestartApplications=no

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#RedistDir}\vc_redist.x64.exe"; Flags: dontcopy
Source: "{#RedistDir}\WindowsAppRuntimeInstall-x64.exe"; Flags: dontcopy

[Icons]
Name: "{group}\Gecko"; Filename: "{app}\Gecko.exe"

[Run]
Filename: "{app}\Gecko.exe"; Description: "Launch Gecko"; Flags: nowait postinstall skipifsilent runasoriginaluser

[Code]
var
  RestartRequired: Boolean;

function InstallPrerequisite(Name, Parameters: String; var Error: String): Boolean;
var
  ExitCode: Integer;
begin
  ExtractTemporaryFile(Name);
  Result := Exec(ExpandConstant('{tmp}\') + Name, Parameters, '',
    SW_HIDE, ewWaitUntilTerminated, ExitCode);
  if Result then begin
    Log(Name + ' returned ' + IntToStr(ExitCode));
    Result := (ExitCode = 0) or (ExitCode = 3010) or
      ((Name = 'vc_redist.x64.exe') and (ExitCode = 1638));
    if ExitCode = 3010 then RestartRequired := True;
  end;
  if not Result then
    Error := 'Could not install ' + Name + ' (code ' + IntToStr(ExitCode) + '). See the setup log for details.';
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  if not InstallPrerequisite('vc_redist.x64.exe', '/install /quiet /norestart', Result) then Exit;
  if not InstallPrerequisite('WindowsAppRuntimeInstall-x64.exe', '--quiet', Result) then Exit;
end;

function NeedRestart: Boolean;
begin
  Result := RestartRequired;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Command: String;
begin
  if CurUninstallStep = usUninstall then
    if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'Gecko', Command) then
      if CompareText(Command, ExpandConstant('"{app}\Gecko.exe"')) = 0 then
        RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'Gecko');
end;
