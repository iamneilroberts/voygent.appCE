param(
  [switch]$StartMenu
)

$ErrorActionPreference = 'Stop'
$repo = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$tray = Join-Path $repo 'tray'

Write-Host "Registering Voygent Tray autostart (Scheduled Task at logon)"
Write-Host 'Requires pnpm and that you have run pnpm install in tray/ at least once.'

$cmd = "$env:ComSpec"
$args = "/c cd `"$tray`" && pnpm dev"

$action = New-ScheduledTaskAction -Execute $cmd -Argument $args
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName 'Voygent CE Tray' -Action $action -Trigger $trigger -Settings $settings -Description 'Start Voygent CE Tray at user logon' -User $env:UserName -RunLevel LeastPrivilege -Force | Out-Null
Write-Host '✅ Autostart task registered.'

if ($StartMenu) {
  $shortcutDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
  New-Item -ItemType Directory -Path $shortcutDir -Force | Out-Null
  $lnkPath = Join-Path $shortcutDir 'Voygent CE Tray.lnk'
  $WshShell = New-Object -ComObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut($lnkPath)
  $Shortcut.TargetPath = $env:ComSpec
  $Shortcut.Arguments = $args
  $Shortcut.WorkingDirectory = $tray
  $Shortcut.IconLocation = "$env:SystemRoot\\System32\\shell32.dll, 167"
  $Shortcut.Save()
  Write-Host "✅ Shortcut created: $lnkPath"
}

