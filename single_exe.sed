[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=__TARGET_NAME__
FriendlyName=__FRIENDLY_NAME__
AppLaunched=launcher.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=launcher.cmd
UserQuietInstCmd=launcher.cmd
SourceFiles=SourceFiles

[Strings]
FILE0=launcher.cmd
FILE1=payload.zip

[SourceFiles]
SourceFiles0=__SOURCE_FILES_DIR__

[SourceFiles0]
%FILE0%=
%FILE1%=
