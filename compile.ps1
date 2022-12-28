$env="dev";
if($args.contains('-dev')) {$env="dev"}
if($args.contains('-prod')) {$env="prod"}


# Create and empty build and out folders
$path = ".\build"
if (-Not (Test-Path $path)) {
    New-Item -Path $path -ItemType Directory | Out-Null
}
Get-ChildItem -Path $path -Include * -Recurse | ForEach-Object { $_.Delete()}
$path = ".\out"
if (-Not (Test-Path $path)) {
    New-Item -Path $path -ItemType Directory | Out-Null
}
Get-ChildItem -Path $path -Include * -Recurse | ForEach-Object { $_.Delete()}

# copy app icon to build folder
Copy-Item .\src\icon.ico -Destination .\build\icon.ico -Force
# copy config.json to build folder
if ($env -eq "prod") {
    Copy-Item .\src\config_prod.json -Destination .\build\config.json -Force
}
else {
    Copy-Item .\src\config.json -Destination .\build\config.json -Force
}


# get compilation files
$config = Get-Content .\build\config.json -Raw | ConvertFrom-Json
$XAML = (Get-Content ".\src\index.xaml") -as [Collections.ArrayList]
$codeFile = (Get-Content ".\src\main.ps1") -as [Collections.ArrayList]

# merge files
$codeFile.Insert(4, '"@')
for ($i = $XAML.Count-1; $i -gt -1; $i--) {
    $codeFile.Insert(4, $XAML[$i])
}
$codeFile.Insert(4, '[xml]$XAML = @"')
$codeFile | Set-Content .\build\SyncRom_compiled.ps1

# Compile to exe
Import-Module ps2exe
ps2exe -inputFile .\build\SyncRom_compiled.ps1 -outputFile .\out\SyncRom.exe -noConsole -title SyncRom -iconFile .\build\icon.ico -version $config.version

# copy config.json
Copy-Item .\build\config.json -Destination .\out\config.json -Force

# compress zip
$compress = @{
    Path = ".\out\*"
    CompressionLevel = "Fastest"
    DestinationPath = ".\out\SyncRom.zip"
}
Compress-Archive @compress
