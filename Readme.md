# Installation
## Automatic installation
Download latest [release installer](https://github.com/Menros/SyncRom/releases/latest)  
Execute and follow the installation instructions  
## Manual installation
Dowload latest [release (zip)](https://github.com/Menros/SyncRom/releases/latest)  
Unzip files where you want  
Execute SyncRom.exe  

# Manual compilation
## Requirements
You must install:  
- [ps2exe](https://github.com/MScholtes/PS2EXE): allows to compile powershell script to exe file
- [inno setup](https://jrsoftware.org/isinfo.php): allows to generate installer
    - You must set the ino setup folder in your PATH

Clone project (or download source code from any release)  
Execute in powershell : .\compile.ps1 -prod  
Get the files in "out" folder, then follow Installation instructions