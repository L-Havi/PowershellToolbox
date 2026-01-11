<#
.SYNOPSIS
  Modular PowerShell Toolbox loader.

.DESCRIPTION
  Dot-sources category tool files and shows the main menu.
#>

# Initialize global paths
$Global:WorkspaceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:LabConfigFile = Join-Path $Global:WorkspaceRoot "config.yaml"

# Load modules
. (Join-Path $Global:WorkspaceRoot "modules\\Common.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\FileTools.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\NetworkTools.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\SystemTools.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\SecurityTools.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\ProxmoxTools.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\VMwareTools.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\HypervisorTools.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\CloudTools.ps1")
. (Join-Path $Global:WorkspaceRoot "modules\\AzureTools.ps1")

# Main Menu
function Show-MainMenu {
    $choice = $null
  $firstRender = $true
  while ($choice -ne '0') {
    if ($firstRender) {
      Show-Header -Title "PowerShell Toolbox :: Main Menu" -NoClear
      $firstRender = $false
    } else {
      Show-Header -Title "PowerShell Toolbox :: Main Menu"
    }

        Write-Host " [1] File Management Tools" -ForegroundColor White
        Write-Host " [2] Network Tools" -ForegroundColor White
        Write-Host " [3] System Tools" -ForegroundColor White
        Write-Host " [4] Security Tools" -ForegroundColor White
        Write-Host " [5] Hypervisor Tools" -ForegroundColor White
        Write-Host " [6] Cloud Environments" -ForegroundColor White
        Write-Host ""
        Write-Host " [0] Exit" -ForegroundColor DarkGray
        Write-Host ""
        $choice = Read-Host "Select a category"

        switch ($choice) {
            '1' { Show-FileToolsMenu }
            '2' { Show-NetworkToolsMenu }
            '3' { Show-SystemToolsMenu }
            '4' { Show-SecurityToolsMenu }
            '5' { Show-HypervisorToolsMenu }
            '6' { Show-CloudEnvironmentsMenu }
            '0' { Write-Host "Exiting..." -ForegroundColor Cyan; break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# Entry point: only when executed, not dot-sourced
if ($MyInvocation.InvocationName -ne '.') { Initialize-AppIO; Show-StartScreen; Show-MainMenu }
