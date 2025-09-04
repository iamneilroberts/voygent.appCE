param(
  [switch]$Autostart
)

$ErrorActionPreference = 'Stop'

# Resolve repo root (script is in repo\scripts\windows)
$repo = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$bat = Join-Path $repo 'voygent.bat'

Write-Host "Creating Start Menu shortcut to: $bat"

$shortcutDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
New-Item -ItemType Directory -Path $shortcutDir -Force | Out-Null
$lnkPath = Join-Path $shortcutDir 'Voygent CE.lnk'

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($lnkPath)
$Shortcut.TargetPath = $env:ComSpec
$Shortcut.Arguments = "/c start """" ""$bat"" start"
$Shortcut.WorkingDirectory = $repo
$Shortcut.IconLocation = "$env:SystemRoot\\System32\\shell32.dll, 167"
$Shortcut.Save()

Write-Host "✅ Shortcut created: $lnkPath"

if ($Autostart) {
  try {
    Write-Host 'Registering autostart (Scheduled Task at logon)...'
    $action = New-ScheduledTaskAction -Execute $env:ComSpec -Argument "/c start """" ""$bat"" start"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName 'Voygent CE Autostart' -Action $action -Trigger $trigger -Settings $settings -Description 'Start Voygent CE at user logon' -User $env:UserName -RunLevel LeastPrivilege -Force | Out-Null
    Write-Host '✅ Autostart task registered.'
  } catch {
    Write-Warning "Could not register scheduled task automatically. Run PowerShell as your user and retry. Details: $($_.Exception.Message)"
  }
}

