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
; Usar .\ garante que ele busque a partir da raiz do repositório
Source: ".\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdir createallsubdirs