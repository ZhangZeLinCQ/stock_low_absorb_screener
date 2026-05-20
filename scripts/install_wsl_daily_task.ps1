param(
    [string]$WslDistro = "Ubuntu",
    [string]$ProjectPathInWsl = "/mnt/d/GitProject/GPgetter/low_absorb_screener"
)

$Action = New-ScheduledTaskAction `
    -Execute "wsl.exe" `
    -Argument "-d $WslDistro -- bash -lc 'cd $ProjectPathInWsl && bash scripts/run_low_absorb_daily.sh'"

$Trigger = New-ScheduledTaskTrigger -Daily -At 17:00
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable

Register-ScheduledTask `
    -TaskName "LowAbsorbScreenerDaily" `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Daily low-absorb stock screener update at 17:00" `
    -Force
