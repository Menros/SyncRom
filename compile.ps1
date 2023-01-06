$version="1.0.1"

$env="dev";
if($args.contains('-dev')) {$env="dev"}
if($args.contains('-prod')) {$env="prod"}


# Create and empty build and out folders
$path = ".\build"
Remove-Item -Recurse -Force $path
New-Item -Path $path -ItemType Directory | Out-Null

$path = ".\out"
Remove-Item -Recurse -Force $path
New-Item -Path $path -ItemType Directory | Out-Null

# copy app icon to build folder
Copy-Item .\src\icon.ico -Destination .\build\icon.ico -Force
# copy config.json to build folder
if ($env -eq "prod") {
    Copy-Item .\src\config_prod.json -Destination .\build\config.json -Force
}
else {
    Copy-Item .\src\config.json -Destination .\build\config.json -Force
}

# set version
$file = (Get-Content ".\build\config.json") -as [Collections.ArrayList]
$file[1] = '    "version":  "'+$version+'",'
$file | Set-Content .\build\config.json

$file = (Get-Content ".\syncRomInstaller.iss") -as [Collections.ArrayList]
$file[4] = '#define MyAppVersion "'+$version+'"'
$file | Set-Content .\syncRomInstaller.iss


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

# create compilation folder
$outPath = ".\out\SyncRom-"+$version
New-Item -Path $outPath -ItemType Directory | Out-Null

# Compile to exe
Import-Module ps2exe
ps2exe -inputFile .\build\SyncRom_compiled.ps1 -outputFile $outPath\SyncRom.exe -noConsole -title SyncRom -iconFile .\build\icon.ico -version $config.version

# copy config.json
Copy-Item .\build\config.json -Destination $outPath\config.json -Force

# compress zip
$compress = @{
    Path = $outPath
    CompressionLevel = "Fastest"
    DestinationPath = ".\out\SyncRom-"+$version+".zip"
}
Compress-Archive @compress

iscc /O"out" ".\syncRomInstaller.iss"
