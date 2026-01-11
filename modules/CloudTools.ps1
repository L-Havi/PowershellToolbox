# Cloud Environments (Wrapper)

function Show-CloudEnvironmentsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Cloud Environments"
        Write-Host " [1] Azure Tools" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back to main menu" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select a cloud environment"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Cloud.AzureMenu' -Action { Show-AzureToolsMenu } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
