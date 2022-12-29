Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
Add-Type -Assembly System.Windows.forms

# Here Compile import Xaml

# Retrieve config
function getConfig {
    return Get-Content .\config.json | ConvertFrom-Json
}
function saveConfig {
    $config | ConvertTo-Json -Depth 3 | Set-Content .\config.json
}
function secureConfigNotConfigured {
    return (($romsList.SelectedIndex -eq -1) -or ($null -eq $config.backup) -or ($config.backup -eq ""))
}

function selectBackupPathDialog {
    $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
    $objForm.Rootfolder = "Desktop"
    $objForm.Description = "Select Backup Folder"
    $objForm.SelectedPath = $config.backup
    
    if ($objForm.ShowDialog() -eq "OK") {
        setBackupPath $objForm.SelectedPath
    }
}
function setBackupPath {
    param($path)
    $backupPath.Text = $path
    $config.backup = $path
    saveConfig
}

function actionAddRom {
    $romsList = $window.FindName("romsList")
    $selectedRomName = $window.FindName("selectedRomName")
    if ($selectedRomName.Text -eq "") {return}
    # Add Rom name to config file
    $newRom = [PSCustomObject]@{
        name=$selectedRomName.Text
        paths=@()
    }
    $config.ROMs += $newRom
    saveConfig
    # Add Rom name to list
    $romsList.AddChild($selectedRomName.Text)
    $romsList.SelectedIndex = ($romsList.Items.Count-1)
    # Create new Rom backup folder
    $backupGamePath = "$($config.backup)\$($selectedRomName.Text)"
    if (-Not (Test-Path $backupGamePath)) {
        New-Item -Path $backupGamePath -ItemType Directory | Out-Null
    }
    loadSelectedRom
    # Reset form
    $selectedRomName.Text = ""
}
function actionModifyRom {}
function actionDeleteRom {}
function initRomsList {
    $romsListSyncAllBtn = $window.FindName("romsListSyncAllBtn")
    $romsListAddBtn = $window.FindName("romsListAddBtn")
    $romsListModifyBtn = $window.FindName("romsListModifyBtn")
    $romsListRemoveBtn = $window.FindName("romsListRemoveBtn")

    $romsListSyncAllBtn.Add_Click({
        syncAll
        loadSelectedRom
    })

    $romsListAddBtn.Add_Click({actionAddRom})
    $romsListModifyBtn.Add_Click({actionModifyRom})
    $romsListRemoveBtn.Add_Click({actionDeleteRom})


    For($i=0 ; $i -lt $config.ROMs.length ; $i++) {
        $romsList.AddChild($config.ROMs[$i].name)
    }
    $romsList.SelectedIndex = 0
    loadSelectedRom
}

function checkMainPathValidity {
    $selectedRomPath = $window.FindName("selectedRomPath")
    if (-not($selectedRomPath.Text -like "*\main")) {
        if (-not($selectedRomPath.Text -like "*\")) {
            $selectedRomPath.Text += "\main"
        }
        else {
            $selectedRomPath.Text += "main"
        }
    }
}
function initRomPath {
    $addMainPathBtn = $window.FindName("addMainPathBtn")
    $modifyMainPathBtn = $window.FindName("modifyMainPathBtn")
    $deleteMainPathBtn = $window.FindName("deleteMainPathBtn")
    $cancelMainPathBtn = $window.FindName("cancelMainPathBtn")
    
    $addMainPathBtn.Add_Click({
        checkMainPathValidity
        $listBoxRomPaths = $window.FindName("listBoxRomPaths")
        $selectedRomPath = $window.FindName("selectedRomPath")
        if ($selectedRomPath.Text -ne "") {
            $config.ROMs[$romsList.SelectedIndex].paths += "$($selectedRomPath.Text)"
            $listBoxRomPaths.AddChild([PSCustomObject]@{romPath="$($selectedRomPath.Text)"})
            $selectedRomPath.Text = ""
            saveConfig
        }
    })
    $modifyMainPathBtn.Add_Click({
        checkMainPathValidity
        $listBoxRomPaths = $window.FindName("listBoxRomPaths")
        $selectedRomPath = $window.FindName("selectedRomPath")
        if ($listBoxRomPaths.SelectedIndex -ne -1) {
            $config.ROMs[$romsList.SelectedIndex].paths[$listBoxRomPaths.SelectedIndex] = "$($selectedRomPath.Text)"
            $listBoxRomPaths.Items[$listBoxRomPaths.SelectedIndex] = [PSCustomObject]@{romPath="$($selectedRomPath.Text)"}
            $selectedRomPath.Text = ""
            saveConfig
        }
    })
    $deleteMainPathBtn.Add_Click({
        $listBoxRomPaths = $window.FindName("listBoxRomPaths")
        $selectedRomPath = $window.FindName("selectedRomPath")
        if ($listBoxRomPaths.SelectedIndex -eq -1) {
            $listBoxRomPaths.SelectedIndex = $listBoxRomPaths.Items.Count-1
        }
        $listBoxRomPaths.Items.RemoveAt($listBoxRomPaths.SelectedIndex)
        $config.ROMs[$romsList.SelectedIndex].paths = @()
        foreach ($p in $listBoxRomPaths.Items) {
            $config.ROMs[$romsList.SelectedIndex].paths += "$($p.romPath)"
        }
        $selectedRomPath.Text = ""
        saveConfig
    })
    $cancelMainPathBtn.Add_Click({
        $selectedRomPath = $window.FindName("selectedRomPath")
        $selectedRomPath.Text = ""
    })
}
function initSaveList {
    # $savesList = $window.FindName("savesList")
    $syncSaveBtn = $window.FindName("syncSaveBtn")
    $loadSaveBtn = $window.FindName("loadSaveBtn")
    # $importSaveBtn = $window.FindName("importSaveBtn")

    $syncSaveBtn.Add_Click({
        syncMostRecentSave
        loadSelectedRom
    })

    $loadSaveBtn.Add_Click({
        $savesList = $window.FindName("savesList")
        syncLoadSelectedSave $savesList.SelectedItem.savedPath
        loadSelectedRom
    })
}

function loadSelectedRom {
    if (secureConfigNotConfigured) {return}
    # Get Rom info from config.json
    $activeRom = $config.ROMs[$romsList.SelectedIndex]
    
    # Set active rom name
    $activeRomName = $window.FindName("activeRomName")
    $activeRomName.Text = $activeRom.name
    
    # Load all saved roms
    $savesList = $window.FindName("savesList")
    $savesList.Items.Clear()
    $savedRomList = Get-ChildItem -Recurse -Path "$($config.backup)\\$($activeRom.name)" -File | Sort-Object LastWriteTime -Descending
    foreach ($savedRom in $savedRomList) {
        $srom = [PSCustomObject]@{
            savedName=$savedRom.Directory.Name
            savedPath=$savedRom.FullName
        }
        $savesList.AddChild($srom)
    }
    $savesList.SelectedIndex = 0
    
    # Load all rom paths
    $listBoxRomPaths = $window.FindName("listBoxRomPaths")
    $listBoxRomPaths.Items.Clear()
    For($i=0 ; $i -lt $activeRom.paths.length ; $i++) {
        $listBoxRomPaths.AddChild([PSCustomObject]@{romPath="$($activeRom.paths[$i])"})
    }
}
function loadSelectedRomPath {
    $listBoxRomPaths = $window.FindName("listBoxRomPaths")
    $selectedRomPath = $window.FindName("selectedRomPath")
    $selectedRomPath.Text = $listBoxRomPaths.SelectedItem.romPath
}

function syncAll {
    $romsList = $window.FindName("romsList")
    $savedActive = $romsList.SelectedIndex
    for ($i = 0; $i -lt $romsList.Items.Count; $i++) {
        $romsList.SelectedIndex = $i
        syncMostRecentSave
    }
    $romsList.SelectedIndex = $savedActive
}
function syncMostRecentSave {
    if (secureConfigNotConfigured) {return}
    $activeRom = $config.ROMs[$romsList.SelectedIndex]
    # Create game backup folder
    $backupGamePath = "$($config.backup)\$($activeRom.name)"
    if (-Not (Test-Path $backupGamePath)) {
        New-Item -Path $backupGamePath -ItemType Directory | Out-Null
    }
    
    # Find most recent save between all emulators
    $mostRecentDate = Get-Date -Date "1970-01-01"
    $mostRecentPath = ""
    For($pathI=0;$pathI -lt $activeRom.paths.length;$pathI++) {
        $currentFile = Get-Item $activeRom.paths[$pathI]
        if ($mostRecentDate -lt $currentFile.LastWriteTime) {
            $mostRecentDate = $currentFile.LastWriteTime
            $mostRecentPath = $currentFile.DirectoryName
        }
    }
    
    # Check last backup date
    $lastBackup = Get-ChildItem -Recurse -Path $backupGamePath -File | Sort-Object LastWriteTime -Descending| Select-Object -First 1
    
    if($lastBackup.LastWriteTime -lt $mostRecentDate) {
        # Create backup folder
        $backupGamePath = "$($backupGamePath)\$(Get-Date -Format "dd-MM-yyyy-HHmm")"
        New-Item -Path $backupGamePath -ItemType Directory -Force | Out-Null
        
        # Copy most recent to backup directory
        Copy-Item "$($mostRecentPath)\main" -Destination $backupGamePath
    }
    else {
        $backupGamePath = $lastBackup.DirectoryName
    }
    
    syncLoadSelectedSave "$($backupGamePath)\main"
}
function syncLoadSelectedSave {
    param($saveMainPath)
    # Synchronise all folders
    $activeRom = $config.ROMs[$romsList.SelectedIndex]
    For($pathI=0;$pathI -lt $activeRom.paths.length;$pathI++) {
        Copy-Item $saveMainPath -Destination $activeRom.paths[$pathI] -Force
    }
}

function BuildMainPage {
    # retrieve index.xaml
    if($null -eq $XAML) {
        [xml]$XAML = Get-Content .\index.xaml
    }
    $reader = New-Object System.Xml.XmlNodeReader $XAML
    
    # build main window
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $window.SizeToContent = [System.Windows.SizeToContent]::WidthAndHeight
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    
    # Configure backup input listener
    $backupPath = $window.FindName("backupPath")
    $backupPathBtn = $window.FindName("backupPathBtn")
    $backupPath.Text = $config.backup
    $backupPathBtn.Add_Click({selectBackupPathDialog})
    $backupPath.Add_TextChanged({setBackupPath $backupPath.Text})
    
    # Initialize Roms list and configure listener
    $listBoxRomPaths = $window.FindName("listBoxRomPaths")
    $romsList = $window.FindName("romsList")
    initRomPath
    initRomsList
    $listBoxRomPaths.add_SelectionChanged({loadSelectedRomPath})
    $romsList.add_SelectionChanged({loadSelectedRom})
    
    initSaveList
    
    $window.ShowDialog() | Out-Null
}


$config = getConfig
BuildMainPage
