[Setup]
AppName=SESI Downloader
AppVersion=1.0.0
DefaultDirName={autopf}\SESI Downloader
DefaultGroupName=SESI Downloader
OutputBaseFilename=SESI_Downloader_Setup
OutputDir=bin
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdir createallsubdirs

[Icons]
Name: "{group}\SESI Downloader"; Filename: "{app}\sesi_downloader.exe"
Name: "{autodesktop}\SESI Downloader"; Filename: "{app}\sesi_downloader.exe"