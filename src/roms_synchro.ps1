# Retrieve config
$config = Get-Content .\config.json -Raw | ConvertFrom-Json

Write-Host $(Get-Date)
# Sync each game
For($romI=0;$romI -lt $config.ROMs.length;$romI++)
{
   Write-Host "Synchronizing $($config.ROMs[$romI].name)..."

   # Create game backup folder
   $backupGamePath = "$($config.backup)\$($config.ROMs[$romI].name)"
   if (-Not (Test-Path $backupGamePath)) {
      New-Item -Path $backupGamePath -ItemType Directory | Out-Null
   }

   # Find most recent save between all emulators
   $mostRecentDate = Get-Date -Date "1970-01-01"
   $mostRecentPath = ""
   For($pathI=0;$pathI -lt $config.ROMs[$romI].paths.length;$pathI++) {
      $currentFile = Get-Item $config.ROMs[$romI].paths[$pathI]
      if ($mostRecentDate -lt $currentFile.LastWriteTime) {
         $mostRecentDate = $currentFile.LastWriteTime
         $mostRecentPath = $currentFile.DirectoryName
      }
   }

   # Check last backup date
   $lastBackup = Get-ChildItem -Recurse -Path $backupGamePath -File | Sort-Object LastWriteTime -Descending| Select-Object -First 1

   if($lastBackup.LastWriteTime -lt $mostRecentDate) {
      # Create backup folder
      $backupGamePath = "$($backupGamePath)\$(Get-Date -Format "yyyy-MM-dd-HHmm")"
      New-Item -Path $backupGamePath -ItemType Directory -Force | Out-Null

      # Copy most recent to backup directory
      Copy-Item "$($mostRecentPath)\main" -Destination $backupGamePath
   }
   else {
      $backupGamePath = $lastBackup.DirectoryName
   }

   # Synchronise all folders
   For($pathI=0;$pathI -lt $config.ROMs[$romI].paths.length;$pathI++) {
      $syncPath = (Get-Item $config.ROMs[$romI].paths[$pathI]).DirectoryName
      Copy-Item "$($backupGamePath)\main" -Destination $syncPath -Force
   }
}
