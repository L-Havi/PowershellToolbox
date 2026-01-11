# Hypervisor Tools (Wrapper)

function Show-HypervisorToolsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Hypervisor Tools"
        Write-Host " [1] Proxmox Tools" -ForegroundColor White
        Write-Host " [2] VMware Tools" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back to main menu" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select a hypervisor"
        switch ($selection) {
                '1' { Invoke-Tool -Name 'Hypervisor.ProxmoxMenu' -Action { Show-ProxmoxToolsMenu } }
                '2' { Invoke-Tool -Name 'Hypervisor.VMwareMenu' -Action { Show-VMwareToolsMenu } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
