# Security Tools

function List-LocalAdmins {
    Show-Header -Title "Security Tools :: Local Administrators"
    try {
        $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        if (-not $admins) { Write-Host "No members found in local Administrators group." -ForegroundColor Yellow }
        else { Write-Host "Members of local Administrators group:" -ForegroundColor Cyan; $admins | Select-Object Name, ObjectClass, PrincipalSource | Format-Table -AutoSize }
    } catch {
        Write-Host "Get-LocalGroupMember failed (older OS or no module). Falling back to 'net localgroup'..." -ForegroundColor Yellow
        Write-Host ""; cmd.exe /c "net localgroup Administrators"
    }
    Pause-Return
}

function Check-DefenderStatus {
    Show-Header -Title "Security Tools :: Windows Defender Status"
    try {
        $prefs = Get-MpPreference -ErrorAction Stop
        $status = Get-MpComputerStatus -ErrorAction Stop
        Write-Host "Real-time protection : $($status.RealTimeProtectionEnabled)" -ForegroundColor White
        Write-Host "Behavior monitoring  : $($status.BehaviorMonitorEnabled)" -ForegroundColor White
        Write-Host "IOAV protection      : $($status.IOAVProtectionEnabled)" -ForegroundColor White
        Write-Host "Cloud protection     : $($status.IsTamperProtected)" -ForegroundColor White
        Write-Host ""; Write-Host "Antivirus enabled    : $($status.AntivirusEnabled)" -ForegroundColor White
        Write-Host "Antispyware enabled  : $($status.AntispywareEnabled)" -ForegroundColor White
        Write-Host ""; Write-Host "Last quick scan      : $($status.LastQuickScanEndTime)" -ForegroundColor White
        Write-Host "Last full scan       : $($status.LastFullScanEndTime)" -ForegroundColor White
        Write-Host ""; Write-Host "Engine version       : $($status.AMEngineVersion)" -ForegroundColor White
        Write-Host "AV signature version : $($status.AVSignatureVersion)" -ForegroundColor White
    } catch {
        Write-Host "Windows Defender cmdlets are not available on this system." -ForegroundColor Red
        Write-Host "This may be a server without Defender or a system with another AV solution." -ForegroundColor Yellow
    }
    Pause-Return
}

function Check-FirewallStatus {
    Show-Header -Title "Security Tools :: Windows Firewall Status"
    try {
        $profiles = Get-NetFirewallProfile -ErrorAction Stop
        $profiles | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
    } catch { Write-Host "Failed to query Windows Firewall profiles: $_" -ForegroundColor Red }
    Pause-Return
}

function Show-SecurityToolsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Security Tools"
        Write-Host " [1] List local Administrators group members" -ForegroundColor White
        Write-Host " [2] Check Windows Defender status" -ForegroundColor White
        Write-Host " [3] Check Windows Firewall status" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back to main menu" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Security.LocalAdmins' -Action { List-LocalAdmins } }
            '2' { Invoke-Tool -Name 'Security.DefenderStatus' -Action { Check-DefenderStatus } }
            '3' { Invoke-Tool -Name 'Security.FirewallStatus' -Action { Check-FirewallStatus } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
