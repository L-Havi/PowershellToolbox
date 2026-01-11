# Network Tools

function Test-HostReachability {
    Show-Header -Title "Network Tools :: Ping Host"
    $target = Read-Host "Enter hostname or IP to ping"
    if ([string]::IsNullOrWhiteSpace($target)) { Write-Host "No target provided." -ForegroundColor Red; Pause-Return; return }
    $count = Read-Host "Number of echo requests (default: 4)"
    if (-not [int]::TryParse($count, [ref]$null)) { $count = 4 }
    Write-Host ""; Write-Host "Pinging $target ($count times)..." -ForegroundColor Cyan
    Test-Connection -ComputerName $target -Count $count -ErrorAction SilentlyContinue |
        Select-Object Address, ResponseTime, Status | Format-Table -AutoSize
    Pause-Return
}

function Show-IPConfig {
    Show-Header -Title "Network Tools :: IP Configuration"
    Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-Table -AutoSize
    Pause-Return
}

function Simple-PortCheck {
    Show-Header -Title "Network Tools :: TCP Port Check"
    $target = Read-Host "Enter hostname or IP"
    if ([string]::IsNullOrWhiteSpace($target)) { Write-Host "No target provided." -ForegroundColor Red; Pause-Return; return }
    $port = Read-Host "Enter TCP port (e.g. 22, 80, 3389)"
    if (-not [int]::TryParse($port, [ref]$null)) { Write-Host "Invalid port." -ForegroundColor Red; Pause-Return; return }
    Write-Host ""; Write-Host "Testing TCP port $port on $target..." -ForegroundColor Cyan
    try {
        $result = Test-NetConnection -ComputerName $target -Port $port -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) { Write-Host "Port $port on $target is OPEN." -ForegroundColor Green }
        else { Write-Host "Port $port on $target is CLOSED or filtered." -ForegroundColor Yellow }
    } catch { Write-Host "Error running Test-NetConnection: $_" -ForegroundColor Red }
    Pause-Return
}

function Show-NetworkToolsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools"
        Write-Host " [1] Diagnostics (Ping, IP, Port)" -ForegroundColor White
        Write-Host " [2] Adapter & IP" -ForegroundColor White
        Write-Host " [3] DNS & DHCP" -ForegroundColor White
        Write-Host " [4] Shares & Drives" -ForegroundColor White
        Write-Host " [5] Routing" -ForegroundColor White
        Write-Host " [6] Remote Connections" -ForegroundColor White
        Write-Host " [7] Listeners" -ForegroundColor White
        Write-Host " [8] Transfers (SFTP/FTP)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back to main menu" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1'  { Show-NetworkDiagnosticsMenu }
            '2'  { Show-AdapterIPMenu }
            '3'  { Show-DnsDhcpMenu }
            '4'  { Show-SharesDrivesMenu }
            '5'  { Show-RoutingMenu }
            '6'  { Show-RemoteConnectionsMenu }
            '7'  { Show-ListenersMenu }
            '8'  { Show-TransfersMenu }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# Submenus
function Show-NetworkDiagnosticsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools :: Diagnostics"
        Write-Host " [1] Ping host" -ForegroundColor White
        Write-Host " [2] Show IP configuration" -ForegroundColor White
        Write-Host " [3] Test TCP port" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Net.PingHost' -Action { Test-HostReachability } }
            '2' { Invoke-Tool -Name 'Net.IPConfig' -Action { Show-IPConfig } }
            '3' { Invoke-Tool -Name 'Net.PortCheck' -Action { Simple-PortCheck } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-AdapterIPMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools :: Adapter & IP"
        Write-Host " [1] Show adapter properties" -ForegroundColor White
        Write-Host " [2] Set IPv4 static address" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Net.AdapterProperties' -Action { Show-NetworkAdapterProperties } }
            '2' { Invoke-Tool -Name 'Net.SetIPv4Static' -Action { Set-IPv4StaticInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-DnsDhcpMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools :: DNS & DHCP"
        Write-Host " [1] Set DNS servers" -ForegroundColor White
        Write-Host " [2] Set DNS connection suffix" -ForegroundColor White
        Write-Host " [3] DHCP: show status" -ForegroundColor White
        Write-Host " [4] DHCP: enable on adapter" -ForegroundColor White
        Write-Host " [5] DHCP: release lease" -ForegroundColor White
        Write-Host " [6] DHCP: renew lease" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Net.SetDnsServers' -Action { Set-DnsServersInteractive } }
            '2' { Invoke-Tool -Name 'Net.SetDnsSuffix' -Action { Set-DnsSuffixInteractive } }
            '3' { Invoke-Tool -Name 'Net.DHCPStatus' -Action { Show-DHCPStatus } }
            '4' { Invoke-Tool -Name 'Net.EnableDHCP' -Action { Enable-DHCPInteractive } }
            '5' { Invoke-Tool -Name 'Net.ReleaseDHCP' -Action { Release-DHCPInteractive } }
            '6' { Invoke-Tool -Name 'Net.RenewDHCP' -Action { Renew-DHCPInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-SharesDrivesMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools :: Shares & Drives"
        Write-Host " [1] Create SMB share" -ForegroundColor White
        Write-Host " [2] Remove SMB share" -ForegroundColor White
        Write-Host " [3] Map network drive" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Net.CreateSMBShare' -Action { New-SMBShareInteractive } }
            '2' { Invoke-Tool -Name 'Net.RemoveSMBShare' -Action { Remove-SMBShareInteractive } }
            '3' { Invoke-Tool -Name 'Net.MapDrive' -Action { Map-NetworkDriveInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-RoutingMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools :: Routing"
        Write-Host " [1] Routes: show table" -ForegroundColor White
        Write-Host " [2] Routes: add route" -ForegroundColor White
        Write-Host " [3] Routes: remove route" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Net.RoutesShow' -Action { Show-RoutingTable } }
            '2' { Invoke-Tool -Name 'Net.RouteAdd' -Action { Add-RouteInteractive } }
            '3' { Invoke-Tool -Name 'Net.RouteRemove' -Action { Remove-RouteInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-RemoteConnectionsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools :: Remote Connections"
        Write-Host " [1] Remote: SSH" -ForegroundColor White
        Write-Host " [2] Remote: Telnet" -ForegroundColor White
        Write-Host " [3] Remote: RDP" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Net.RemoteSSH' -Action { Start-SSHSessionInteractive } }
            '2' { Invoke-Tool -Name 'Net.RemoteTelnet' -Action { Start-TelnetSessionInteractive } }
            '3' { Invoke-Tool -Name 'Net.RemoteRDP' -Action { Start-RDPSessionInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-ListenersMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools :: Listeners"
        Write-Host " [1] Start TCP listener" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Net.TcpListener' -Action { Start-TcpListenerInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-TransfersMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Network Tools :: Transfers (SFTP/FTP)"
        Write-Host " [1] Remote: SFTP (psftp)" -ForegroundColor White
        Write-Host " [2] Remote: FTP (ftp.exe)" -ForegroundColor White
        Write-Host " [3] SFTP: Upload file" -ForegroundColor White
        Write-Host " [4] SFTP: Download file" -ForegroundColor White
        Write-Host " [5] FTP: Upload file" -ForegroundColor White
        Write-Host " [6] FTP: Download file" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Net.RemoteSFTP' -Action { Start-SFTPSessionInteractive } }
            '2' { Invoke-Tool -Name 'Net.RemoteFTP' -Action { Start-FTPSessionInteractive } }
            '3' { Invoke-Tool -Name 'Net.SFTPUpload' -Action { Start-SFTPUploadInteractive } }
            '4' { Invoke-Tool -Name 'Net.SFTPDownload' -Action { Start-SFTPDownloadInteractive } }
            '5' { Invoke-Tool -Name 'Net.FTPUpload' -Action { Start-FTPUploadInteractive } }
            '6' { Invoke-Tool -Name 'Net.FTPDownload' -Action { Start-FTPDownloadInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# Optional defaults from config.yaml -> NetworkDefaults section
function Get-NetworkDefaults {
    try { return Get-ConfigSection -SectionName "NetworkDefaults" } catch { return @{} }
}

function Get-RemoteDefaults {
    try { return Get-ConfigSection -SectionName "RemoteDefaults" } catch { return @{} }
}

function Get-ListenerDefaults {
    try { return Get-ConfigSection -SectionName "ListenerDefaults" } catch { return @{} }
}

function Get-TransferDefaults {
    try { return Get-ConfigSection -SectionName "TransferDefaults" } catch { return @{} }
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal $id
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-NetworkAdapterProperties {
    Show-Header -Title "Network Tools :: Adapter Properties"
    Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed | Format-Table -AutoSize
    Write-Host ""; Write-Host "IPv4 configuration:" -ForegroundColor Cyan
    Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-Table -AutoSize
    Pause-Return
}

function ConvertTo-PrefixLength {
    param([Parameter(Mandatory=$true)][string]$SubnetMask)
    $bytes = $SubnetMask.Split('.') | ForEach-Object {[int]$_}
    if ($bytes.Count -ne 4) { throw "Invalid subnet mask: $SubnetMask" }
    $bits = 0
    foreach ($b in $bytes) {
        $bin = [Convert]::ToString($b,2)
        $bits += ($bin.ToCharArray() | Where-Object { $_ -eq '1' }).Count
    }
    return [int]$bits
}

function Set-IPv4StaticInteractive {
    Show-Header -Title "Network Tools :: Set IPv4 Static Address"
    $def = Get-NetworkDefaults
    $alias = Read-Host ("Interface alias (e.g., Ethernet)" + ($(if($def.InterfaceAlias){" [default: $($def.InterfaceAlias)]"})))
    if ([string]::IsNullOrWhiteSpace($alias)) { $alias = $def.InterfaceAlias }
    if ([string]::IsNullOrWhiteSpace($alias)) { Write-Host "No interface alias provided." -ForegroundColor Red; Pause-Return; return }

    $ip = Read-Host ("IPv4 address" + ($(if($def.IPv4Address){" [default: $($def.IPv4Address)]"})))
    if ([string]::IsNullOrWhiteSpace($ip)) { $ip = $def.IPv4Address }
    if ([string]::IsNullOrWhiteSpace($ip)) { Write-Host "No IPv4 address provided." -ForegroundColor Red; Pause-Return; return }

    $pl = $null
    $maskOrPrefix = Read-Host ("Subnet mask or prefix length (e.g., 255.255.255.0 or 24)" + ($(if($def.PrefixLength){" [default: $($def.PrefixLength)]"} elseif($def.SubnetMask){" [default mask: $($def.SubnetMask)]"})))
    if ([string]::IsNullOrWhiteSpace($maskOrPrefix)) { $maskOrPrefix = ($def.PrefixLength, $def.SubnetMask | Where-Object {$_})[0] }
    if ($maskOrPrefix -match '^[0-9]+$') { $pl = [int]$maskOrPrefix }
    else { try { $pl = ConvertTo-PrefixLength -SubnetMask $maskOrPrefix } catch { Write-Host $_ -ForegroundColor Red; Pause-Return; return } }

    $gw = Read-Host ("Default gateway (optional)" + ($(if($def.DefaultGateway){" [default: $($def.DefaultGateway)]"})))
    if ([string]::IsNullOrWhiteSpace($gw)) { $gw = $def.DefaultGateway }

    Write-Host ""; Write-Host "About to set static IPv4:" -ForegroundColor Yellow
    Write-Host " Interface : $alias" -ForegroundColor Yellow
    Write-Host " IP/Prefix : $ip/$pl" -ForegroundColor Yellow
    if ($gw) { Write-Host " Gateway   : $gw" -ForegroundColor Yellow }
    if (-not (Test-IsAdmin)) { Write-Host "Note: This likely requires Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }

    try {
        Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.PrefixOrigin -eq 'Manual' } | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        if ($gw) {
            New-NetIPAddress -InterfaceAlias $alias -IPAddress $ip -PrefixLength $pl -DefaultGateway $gw -ErrorAction Stop | Out-Null
        } else {
            New-NetIPAddress -InterfaceAlias $alias -IPAddress $ip -PrefixLength $pl -ErrorAction Stop | Out-Null
        }
        Write-Host "Static IPv4 applied." -ForegroundColor Green
    } catch { Write-Host "Failed to set static IP: $_" -ForegroundColor Red }
    Pause-Return
}

function Set-DnsServersInteractive {
    Show-Header -Title "Network Tools :: Set DNS Servers"
    $def = Get-NetworkDefaults
    $alias = Read-Host ("Interface alias" + ($(if($def.InterfaceAlias){" [default: $($def.InterfaceAlias)]"})))
    if ([string]::IsNullOrWhiteSpace($alias)) { $alias = $def.InterfaceAlias }
    if ([string]::IsNullOrWhiteSpace($alias)) { Write-Host "No interface alias provided." -ForegroundColor Red; Pause-Return; return }
    $dnsDefault = $def.DnsServers
    $dnsInput = Read-Host ("Comma-separated DNS servers" + ($(if($dnsDefault){" [default: $dnsDefault]"})))
    if ([string]::IsNullOrWhiteSpace($dnsInput)) { $dnsInput = $dnsDefault }
    if ([string]::IsNullOrWhiteSpace($dnsInput)) { Write-Host "No DNS servers provided." -ForegroundColor Red; Pause-Return; return }
    $servers = $dnsInput.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    Write-Host ("Set DNS servers on {0}: {1}" -f $alias, ($servers -join ', ')) -ForegroundColor Yellow
    if (-not (Test-IsAdmin)) { Write-Host "Note: Requires Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses $servers -ErrorAction Stop; Write-Host "DNS servers updated." -ForegroundColor Green }
    catch { Write-Host "Failed to set DNS servers: $_" -ForegroundColor Red }
    Pause-Return
}

function Set-DnsSuffixInteractive {
    Show-Header -Title "Network Tools :: Set DNS Connection Suffix"
    $def = Get-NetworkDefaults
    $alias = Read-Host ("Interface alias" + ($(if($def.InterfaceAlias){" [default: $($def.InterfaceAlias)]"})))
    if ([string]::IsNullOrWhiteSpace($alias)) { $alias = $def.InterfaceAlias }
    if ([string]::IsNullOrWhiteSpace($alias)) { Write-Host "No interface alias provided." -ForegroundColor Red; Pause-Return; return }
    $suffix = Read-Host ("Connection-specific DNS suffix" + ($(if($def.DnsSuffix){" [default: $($def.DnsSuffix)]"})))
    if ([string]::IsNullOrWhiteSpace($suffix)) { $suffix = $def.DnsSuffix }
    if ([string]::IsNullOrWhiteSpace($suffix)) { Write-Host "No DNS suffix provided." -ForegroundColor Red; Pause-Return; return }
    Write-Host "Set DNS suffix on $alias to '$suffix'" -ForegroundColor Yellow
    if (-not (Test-IsAdmin)) { Write-Host "Note: Requires Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { Set-DnsClient -InterfaceAlias $alias -ConnectionSpecificSuffix $suffix -ErrorAction Stop; Write-Host "DNS suffix updated." -ForegroundColor Green }
    catch { Write-Host "Failed to set DNS suffix: $_" -ForegroundColor Red }
    Pause-Return
}

function Show-DHCPStatus {
    Show-Header -Title "Network Tools :: DHCP Status"
    Get-NetIPInterface -AddressFamily IPv4 | Select-Object InterfaceAlias, Dhcp, ConnectionState |
        Format-Table -AutoSize
    Write-Host ""; Write-Host "Current IPv4 addresses (Manual vs DHCP):" -ForegroundColor Cyan
    Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress, PrefixLength, PrefixOrigin |
        Format-Table -AutoSize
    Pause-Return
}

function Enable-DHCPInteractive {
    Show-Header -Title "Network Tools :: Enable DHCP on Adapter"
    $def = Get-NetworkDefaults
    $alias = Read-Host ("Interface alias" + ($(if($def.InterfaceAlias){" [default: $($def.InterfaceAlias)]"})))
    if ([string]::IsNullOrWhiteSpace($alias)) { $alias = $def.InterfaceAlias }
    if ([string]::IsNullOrWhiteSpace($alias)) { Write-Host "No interface alias provided." -ForegroundColor Red; Pause-Return; return }
    Write-Host "This will enable DHCP and remove manual IPv4 addresses on '$alias'" -ForegroundColor Yellow
    if (-not (Test-IsAdmin)) { Write-Host "Note: Requires Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try {
        Set-NetIPInterface -InterfaceAlias $alias -Dhcp Enabled -ErrorAction Stop
        Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.PrefixOrigin -eq 'Manual' } | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        Set-DnsClientServerAddress -InterfaceAlias $alias -ResetServerAddresses -ErrorAction SilentlyContinue
        Write-Host "DHCP enabled and manual addresses cleared." -ForegroundColor Green
    } catch { Write-Host "Failed to enable DHCP: $_" -ForegroundColor Red }
    Pause-Return
}

function Release-DHCPInteractive {
    Show-Header -Title "Network Tools :: DHCP Release"
    $alias = Read-Host "Interface alias to release (as shown by ipconfig /all)"
    if ([string]::IsNullOrWhiteSpace($alias)) { Write-Host "No interface alias provided." -ForegroundColor Red; Pause-Return; return }
    Write-Host "Releasing DHCP lease on '$alias'" -ForegroundColor Yellow
    if (-not (Test-IsAdmin)) { Write-Host "Note: May require Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { cmd.exe /c "ipconfig /release `"$alias`"" } catch { Write-Host "Release failed: $_" -ForegroundColor Red }
    Pause-Return
}

function Renew-DHCPInteractive {
    Show-Header -Title "Network Tools :: DHCP Renew"
    $alias = Read-Host "Interface alias to renew (as shown by ipconfig /all)"
    if ([string]::IsNullOrWhiteSpace($alias)) { Write-Host "No interface alias provided." -ForegroundColor Red; Pause-Return; return }
    Write-Host "Renewing DHCP lease on '$alias'" -ForegroundColor Yellow
    if (-not (Test-IsAdmin)) { Write-Host "Note: May require Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { cmd.exe /c "ipconfig /renew `"$alias`"" } catch { Write-Host "Renew failed: $_" -ForegroundColor Red }
    Pause-Return
}

function New-SMBShareInteractive {
    Show-Header -Title "Network Tools :: Create SMB Share"
    $def = Get-NetworkDefaults
    $shareName = Read-Host ("Share name" + ($(if($def.ShareName){" [default: $($def.ShareName)]"})))
    if ([string]::IsNullOrWhiteSpace($shareName)) { $shareName = $def.ShareName }
    $path = Read-Host ("Local path to share" + ($(if($def.SharePath){" [default: $($def.SharePath)]"})))
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $def.SharePath }
    if ([string]::IsNullOrWhiteSpace($shareName) -or [string]::IsNullOrWhiteSpace($path)) { Write-Host "Share name and path required." -ForegroundColor Red; Pause-Return; return }
    if (-not (Test-Path $path)) {
        $mk = Read-Host "Path does not exist. Create it? (y/N)"
        if ($mk.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
        try { New-Item -ItemType Directory -Path $path -Force | Out-Null } catch { Write-Host "Failed to create folder: $_" -ForegroundColor Red; Pause-Return; return }
    }
    if (-not (Test-IsAdmin)) { Write-Host "Note: Creating shares requires Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Create SMB share '$shareName' for '$path'? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try {
        if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) { Write-Host "Share '$shareName' already exists." -ForegroundColor Yellow }
        else { New-SmbShare -Name $shareName -Path $path -FullAccess $env:USERNAME -ErrorAction Stop | Out-Null; Write-Host "Share created." -ForegroundColor Green }
    } catch { Write-Host "Failed to create share: $_" -ForegroundColor Red }
    Pause-Return
}

function Remove-SMBShareInteractive {
    Show-Header -Title "Network Tools :: Remove SMB Share"
    $name = Read-Host "Share name to remove"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "No share name provided." -ForegroundColor Red; Pause-Return; return }
    if (-not (Test-IsAdmin)) { Write-Host "Note: Removing shares requires Administrator privileges." -ForegroundColor DarkYellow }
    if (-not (Get-SmbShare -Name $name -ErrorAction SilentlyContinue)) { Write-Host "Share '$name' not found." -ForegroundColor Yellow; Pause-Return; return }
    $confirm = Read-Host "Really remove share '$name'? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { Remove-SmbShare -Name $name -Force -ErrorAction Stop; Write-Host "Share removed." -ForegroundColor Green }
    catch { Write-Host "Failed to remove share: $_" -ForegroundColor Red }
    Pause-Return
}

function Map-NetworkDriveInteractive {
    Show-Header -Title "Network Tools :: Map Network Drive"
    $def = Get-NetworkDefaults
    $drive = Read-Host ("Drive letter (e.g., Z)" + ($(if($def.DriveLetter){" [default: $($def.DriveLetter)]"})))
    if ([string]::IsNullOrWhiteSpace($drive)) { $drive = $def.DriveLetter }
    if ([string]::IsNullOrWhiteSpace($drive)) { Write-Host "No drive letter provided." -ForegroundColor Red; Pause-Return; return }
    $drive = $drive.TrimEnd(':')
    $unc = Read-Host ("UNC path (e.g., \\server\\share)" + ($(if($def.UNCPath){" [default: $($def.UNCPath)]"})))
    if ([string]::IsNullOrWhiteSpace($unc)) { $unc = $def.UNCPath }
    if ([string]::IsNullOrWhiteSpace($unc)) { Write-Host "No UNC path provided." -ForegroundColor Red; Pause-Return; return }
    $useCred = Read-Host "Provide credentials? (y/N)"
    $cred = $null
    if ($useCred.ToLowerInvariant() -eq 'y') { $cred = Get-Credential -Message "Enter credentials for $unc" }
    if (Get-PSDrive -Name $drive -ErrorAction SilentlyContinue) { Write-Host ("Drive {0}: already exists; unmount it first." -f $drive) -ForegroundColor Yellow; Pause-Return; return }
    try {
        if ($cred) { New-PSDrive -Name $drive -PSProvider FileSystem -Root $unc -Persist -Credential $cred -ErrorAction Stop | Out-Null }
        else { New-PSDrive -Name $drive -PSProvider FileSystem -Root $unc -Persist -ErrorAction Stop | Out-Null }
        Write-Host ("Mapped {0}: to {1}" -f $drive, $unc) -ForegroundColor Green
    } catch { Write-Host "Failed to map drive: $_" -ForegroundColor Red }
    Pause-Return
}

function Show-RoutingTable {
    Show-Header -Title "Network Tools :: Routing Table"
    try {
        Get-NetRoute -AddressFamily IPv4 |
            Select-Object DestinationPrefix, NextHop, InterfaceAlias, RouteMetric, Protocol | Format-Table -AutoSize
    } catch { Write-Host "Failed to get routes: $_" -ForegroundColor Red }
    Pause-Return
}

function Add-RouteInteractive {
    Show-Header -Title "Network Tools :: Add Route"
    $def = Get-NetworkDefaults
    $prefix = Read-Host ("Destination prefix (e.g., 10.0.0.0/24)" + ($(if($def.RouteDestinationPrefix){" [default: $($def.RouteDestinationPrefix)]"})))
    if ([string]::IsNullOrWhiteSpace($prefix)) { $prefix = $def.RouteDestinationPrefix }
    $nexthop = Read-Host ("Next hop (e.g., 192.168.1.1)" + ($(if($def.RouteNextHop){" [default: $($def.RouteNextHop)]"})))
    if ([string]::IsNullOrWhiteSpace($nexthop)) { $nexthop = $def.RouteNextHop }
    $alias = Read-Host ("Interface alias" + ($(if($def.RouteInterfaceAlias){" [default: $($def.RouteInterfaceAlias)]"})))
    if ([string]::IsNullOrWhiteSpace($alias)) { $alias = $def.RouteInterfaceAlias }
    $metricIn = Read-Host ("Route metric (optional)" + ($(if($def.RouteMetric){" [default: $($def.RouteMetric)]"})))
    if ([string]::IsNullOrWhiteSpace($metricIn)) { $metricIn = $def.RouteMetric }
    [int]$metric = 0; if ($metricIn -and [int]::TryParse($metricIn, [ref]$metric)) { }
    if ([string]::IsNullOrWhiteSpace($prefix) -or [string]::IsNullOrWhiteSpace($nexthop) -or [string]::IsNullOrWhiteSpace($alias)) { Write-Host "Prefix, NextHop and InterfaceAlias are required." -ForegroundColor Red; Pause-Return; return }
    Write-Host "Add route: $prefix via $nexthop on $alias (metric=$metricIn)" -ForegroundColor Yellow
    if (-not (Test-IsAdmin)) { Write-Host "Note: Requires Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Proceed? (y/N)"; if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try {
        if ($metric -gt 0) { New-NetRoute -DestinationPrefix $prefix -NextHop $nexthop -InterfaceAlias $alias -RouteMetric $metric -ErrorAction Stop }
        else { New-NetRoute -DestinationPrefix $prefix -NextHop $nexthop -InterfaceAlias $alias -ErrorAction Stop }
        Write-Host "Route added." -ForegroundColor Green
    } catch { Write-Host "Failed to add route: $_" -ForegroundColor Red }
    Pause-Return
}

function Remove-RouteInteractive {
    Show-Header -Title "Network Tools :: Remove Route"
    $def = Get-NetworkDefaults
    $prefix = Read-Host ("Destination prefix to remove" + ($(if($def.RouteDestinationPrefix){" [default: $($def.RouteDestinationPrefix)]"})))
    if ([string]::IsNullOrWhiteSpace($prefix)) { $prefix = $def.RouteDestinationPrefix }
    $nexthop = Read-Host ("Next hop (optional)" + ($(if($def.RouteNextHop){" [default: $($def.RouteNextHop)]"})))
    if ([string]::IsNullOrWhiteSpace($nexthop)) { $nexthop = $def.RouteNextHop }
    $alias = Read-Host ("Interface alias (optional)" + ($(if($def.RouteInterfaceAlias){" [default: $($def.RouteInterfaceAlias)]"})))
    if ([string]::IsNullOrWhiteSpace($alias)) { $alias = $def.RouteInterfaceAlias }
    if ([string]::IsNullOrWhiteSpace($prefix)) { Write-Host "Destination prefix is required." -ForegroundColor Red; Pause-Return; return }
    Write-Host "Remove route: $prefix" -ForegroundColor Yellow
    if ($nexthop) { Write-Host " NextHop: $nexthop" -ForegroundColor Yellow }
    if ($alias) { Write-Host " Interface: $alias" -ForegroundColor Yellow }
    if (-not (Test-IsAdmin)) { Write-Host "Note: Requires Administrator privileges." -ForegroundColor DarkYellow }
    $confirm = Read-Host "Proceed? (y/N)"; if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try {
        if ($nexthop -and $alias) { Remove-NetRoute -DestinationPrefix $prefix -NextHop $nexthop -InterfaceAlias $alias -Confirm:$false -ErrorAction Stop }
        elseif ($nexthop) { Remove-NetRoute -DestinationPrefix $prefix -NextHop $nexthop -Confirm:$false -ErrorAction Stop }
        elseif ($alias) { Remove-NetRoute -DestinationPrefix $prefix -InterfaceAlias $alias -Confirm:$false -ErrorAction Stop }
        else { Remove-NetRoute -DestinationPrefix $prefix -Confirm:$false -ErrorAction Stop }
        Write-Host "Route removed." -ForegroundColor Green
    } catch { Write-Host "Failed to remove route: $_" -ForegroundColor Red }
    Pause-Return
}

function Start-SSHSessionInteractive {
    Show-Header -Title "Network Tools :: Remote SSH"
    $def = Get-RemoteDefaults
    $sshHost = Read-Host ("SSH host" + ($(if($def.SSHHost){" [default: $($def.SSHHost)]"})))
    if ([string]::IsNullOrWhiteSpace($sshHost)) { $sshHost = $def.SSHHost }
    $user = Read-Host ("SSH username" + ($(if($def.SSHUser){" [default: $($def.SSHUser)]"})))
    if ([string]::IsNullOrWhiteSpace($user)) { $user = $def.SSHUser }
    $portIn = Read-Host ("SSH port (default 22)" + ($(if($def.SSHPort){" [default: $($def.SSHPort)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = ($def.SSHPort, '22' | Where-Object { $_ })[0] }
    [int]$port = 22; [void][int]::TryParse($portIn, [ref]$port)
    if ([string]::IsNullOrWhiteSpace($sshHost) -or [string]::IsNullOrWhiteSpace($user)) { Write-Host "Host and User are required." -ForegroundColor Red; Pause-Return; return }
    Write-Host ("Starting SSH: ssh -p {0} {1}@{2}" -f $port, $user, $sshHost) -ForegroundColor Yellow
    try { Start-Process -FilePath "ssh" -ArgumentList @("-p", "$port", ("{0}@{1}" -f $user, $sshHost)) -ErrorAction Stop | Out-Null; Write-Host "Launched ssh." -ForegroundColor Green }
    catch { Write-Host "Failed to start ssh: $_" -ForegroundColor Red }
    Pause-Return
}

function Start-TelnetSessionInteractive {
    Show-Header -Title "Network Tools :: Remote Telnet"
    $def = Get-RemoteDefaults
    $telnetHost = Read-Host ("Telnet host" + ($(if($def.TelnetHost){" [default: $($def.TelnetHost)]"})))
    if ([string]::IsNullOrWhiteSpace($telnetHost)) { $telnetHost = $def.TelnetHost }
    $portIn = Read-Host ("Telnet port (default 23)" + ($(if($def.TelnetPort){" [default: $($def.TelnetPort)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = ($def.TelnetPort, '23' | Where-Object { $_ })[0] }
    [int]$port = 23; [void][int]::TryParse($portIn, [ref]$port)
    Write-Host ("Starting telnet: telnet {0} {1}" -f $telnetHost, $port) -ForegroundColor Yellow
    try { Start-Process -FilePath "telnet" -ArgumentList @("$telnetHost", "$port") -ErrorAction Stop | Out-Null; Write-Host "Launched telnet." -ForegroundColor Green }
    catch { Write-Host "Failed to start telnet: $_" -ForegroundColor Red }
    Pause-Return
}

function Start-RDPSessionInteractive {
    Show-Header -Title "Network Tools :: Remote RDP"
    $def = Get-RemoteDefaults
    $rdpHost = Read-Host ("RDP host" + ($(if($def.RDPHost){" [default: $($def.RDPHost)]"})))
    if ([string]::IsNullOrWhiteSpace($rdpHost)) { $rdpHost = $def.RDPHost }
    $portIn = Read-Host ("RDP port (optional; default 3389)" + ($(if($def.RDPPort){" [default: $($def.RDPPort)]"})))
    $target = $rdpHost
    if (-not [string]::IsNullOrWhiteSpace($portIn)) { $target = ("{0}:{1}" -f $rdpHost, $portIn) }
    if ([string]::IsNullOrWhiteSpace($target)) { Write-Host "Host is required." -ForegroundColor Red; Pause-Return; return }
    Write-Host ("Starting RDP: mstsc /v:{0}" -f $target) -ForegroundColor Yellow
    try { Start-Process -FilePath "mstsc.exe" -ArgumentList @("/v:$target") -ErrorAction Stop | Out-Null; Write-Host "Launched RDP." -ForegroundColor Green }
    catch { Write-Host "Failed to start RDP: $_" -ForegroundColor Red }
    Pause-Return
}

function New-TcpListenerWrapper {
    param([Parameter(Mandatory=$true)][string]$BindAddress,[Parameter(Mandatory=$true)][int]$Port)
    $ip = [System.Net.IPAddress]::Parse($BindAddress)
    return [System.Net.Sockets.TcpListener]::new($ip, $Port)
}

function Start-TcpListenerInteractive {
    Show-Header -Title "Network Tools :: TCP Listener"
    $def = Get-ListenerDefaults
    $bind = Read-Host ("Bind address (e.g., 0.0.0.0)" + ($(if($def.BindAddress){" [default: $($def.BindAddress)]"})))
    if ([string]::IsNullOrWhiteSpace($bind)) { $bind = ($def.BindAddress, '0.0.0.0' | Where-Object { $_ })[0] }
    $portIn = Read-Host ("Port" + ($(if($def.Port){" [default: $($def.Port)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = $def.Port }
    [int]$port = 0; if (-not [int]::TryParse($portIn, [ref]$port)) { Write-Host "Invalid port." -ForegroundColor Red; Pause-Return; return }
    $secondsIn = Read-Host ("Auto-stop after N seconds (optional)" + ($(if($def.AutoStopSeconds){" [default: $($def.AutoStopSeconds)]"})))
    if ([string]::IsNullOrWhiteSpace($secondsIn)) { $secondsIn = $def.AutoStopSeconds }
    [int]$seconds = 0; [void][int]::TryParse($secondsIn, [ref]$seconds)
    Write-Host ("Starting TCP listener on {0}:{1}" -f $bind, $port) -ForegroundColor Yellow
    try {
        $listener = New-TcpListenerWrapper -BindAddress $bind -Port $port
        $listener.Start()
        Write-Host "Listening. Press Enter to stop..." -ForegroundColor Cyan
        if ($seconds -gt 0) { Start-Sleep -Seconds $seconds }
        else { [void][System.Console]::ReadLine() }
    } catch { Write-Host "Listener error: $_" -ForegroundColor Red }
    finally { try { if ($listener) { $listener.Stop() } } catch {} }
    Write-Host "Listener stopped." -ForegroundColor Green
    Pause-Return
}

function Start-SFTPSessionInteractive {
    Show-Header -Title "Network Tools :: Remote SFTP (psftp)"
    $def = Get-TransferDefaults
    $sftpHost = Read-Host ("SFTP host" + ($(if($def.SFTPHost){" [default: $($def.SFTPHost)]"})))
    if ([string]::IsNullOrWhiteSpace($sftpHost)) { $sftpHost = $def.SFTPHost }
    $user = Read-Host ("SFTP username" + ($(if($def.SFTPUser){" [default: $($def.SFTPUser)]"})))
    if ([string]::IsNullOrWhiteSpace($user)) { $user = $def.SFTPUser }
    $portIn = Read-Host ("SFTP port (default 22)" + ($(if($def.SFTPPort){" [default: $($def.SFTPPort)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = ($def.SFTPPort,'22' | Where-Object { $_ })[0] }
    [int]$port = 22; [void][int]::TryParse($portIn, [ref]$port)

    $psftpCmd = $null
    $cmdFound = Get-Command psftp -ErrorAction SilentlyContinue
    if ($cmdFound) { $psftpCmd = $cmdFound.Source }
    else {
        $fallback = $def.PSFTPPath
        if (-not [string]::IsNullOrWhiteSpace($fallback) -and (Test-Path -LiteralPath $fallback)) { $psftpCmd = $fallback }
        else {
            $psftpCmd = Read-Host "psftp.exe not found. Enter full path (or leave blank to cancel)"
            if ([string]::IsNullOrWhiteSpace($psftpCmd) -or -not (Test-Path -LiteralPath $psftpCmd)) { Write-Host "psftp.exe not available." -ForegroundColor Red; Pause-Return; return }
        }
    }

    if ([string]::IsNullOrWhiteSpace($sftpHost) -or [string]::IsNullOrWhiteSpace($user)) { Write-Host "Host and User are required." -ForegroundColor Red; Pause-Return; return }
    Write-Host ("Starting SFTP: {0} -P {1} {2}@{3}" -f $psftpCmd, $port, $user, $sftpHost) -ForegroundColor Yellow
    try { Start-Process -FilePath $psftpCmd -ArgumentList @('-P', "$port", ("{0}@{1}" -f $user, $sftpHost)) -ErrorAction Stop | Out-Null; Write-Host "Launched SFTP (psftp)." -ForegroundColor Green }
    catch { Write-Host "Failed to start psftp: $_" -ForegroundColor Red }
    Pause-Return
}

function Start-FTPSessionInteractive {
    Show-Header -Title "Network Tools :: Remote FTP (ftp.exe)"
    $def = Get-TransferDefaults
    $ftpHost = Read-Host ("FTP host" + ($(if($def.FTPHost){" [default: $($def.FTPHost)]"})))
    if ([string]::IsNullOrWhiteSpace($ftpHost)) { $ftpHost = $def.FTPHost }
    $portIn = Read-Host ("FTP port (default 21)" + ($(if($def.FTPPort){" [default: $($def.FTPPort)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = ($def.FTPPort,'21' | Where-Object { $_ })[0] }
    [int]$port = 21; [void][int]::TryParse($portIn, [ref]$port)

    if ([string]::IsNullOrWhiteSpace($ftpHost)) { Write-Host "Host is required." -ForegroundColor Red; Pause-Return; return }
    Write-Host ("Starting ftp.exe. In the FTP prompt, type: open {0} {1}" -f $ftpHost, $port) -ForegroundColor Yellow
    try { Start-Process -FilePath 'ftp' -ErrorAction Stop | Out-Null; Write-Host "Launched ftp.exe." -ForegroundColor Green }
    catch { Write-Host "Failed to start ftp.exe: $_" -ForegroundColor Red }
    Pause-Return
}

function New-TempScriptFile {
    param([Parameter(Mandatory=$true)][string]$Prefix,[Parameter()][string[]]$Lines)
    $tmp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("{0}_{1}.txt" -f $Prefix, [System.Guid]::NewGuid().ToString('N')))
    if ($Lines) { Set-Content -Path $tmp -Value ($Lines -join "`r`n") -Encoding ascii }
    return $tmp
}

function New-TempFilePath {
    param([Parameter(Mandatory=$true)][string]$Prefix,[Parameter(Mandatory=$true)][string]$BaseName)
    return [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("{0}_{1}_{2}" -f $Prefix, [System.Guid]::NewGuid().ToString('N'), $BaseName))
}

function Start-SFTPUploadInteractive {
    Show-Header -Title "Network Tools :: SFTP Upload (psftp)"
    $def = Get-TransferDefaults
    $sftpHost = Read-Host ("SFTP host" + ($(if($def.SFTPHost){" [default: $($def.SFTPHost)]"})))
    if ([string]::IsNullOrWhiteSpace($sftpHost)) { $sftpHost = $def.SFTPHost }
    $user = Read-Host ("SFTP username" + ($(if($def.SFTPUser){" [default: $($def.SFTPUser)]"})))
    if ([string]::IsNullOrWhiteSpace($user)) { $user = $def.SFTPUser }
    $portIn = Read-Host ("SFTP port (default 22)" + ($(if($def.SFTPPort){" [default: $($def.SFTPPort)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = ($def.SFTPPort,'22' | Where-Object { $_ })[0] }
    [int]$port = 22; [void][int]::TryParse($portIn, [ref]$port)
    $local = Read-Host "Local file to upload"
    if (-not (Test-Path -LiteralPath $local -PathType Leaf)) { Write-Host "Local file not found." -ForegroundColor Red; Pause-Return; return }
    $remotePath = Read-Host ("Remote path (folder)" + ($(if($def.SFTPRemotePath){" [default: $($def.SFTPRemotePath)]"})))
    if ([string]::IsNullOrWhiteSpace($remotePath)) { $remotePath = $def.SFTPRemotePath }

    $cred = Get-Credential -Message "Enter SFTP password for $user@$sftpHost" -UserName $user
    $pw = $cred.GetNetworkCredential().Password

    $psftpCmd = $null
    $cmdFound = Get-Command psftp -ErrorAction SilentlyContinue
    if ($cmdFound) { $psftpCmd = $cmdFound.Source } else { $psftpCmd = ($def.PSFTPPath) }
    if ([string]::IsNullOrWhiteSpace($psftpCmd)) { Write-Host "psftp.exe not found." -ForegroundColor Red; Pause-Return; return }

    $script = New-TempScriptFile -Prefix 'psftp' -Lines @("cd $remotePath","put $local","quit")
    Write-Host ("Uploading via SFTP: {0} -> {1}:{2}" -f $local, $sftpHost, $remotePath) -ForegroundColor Yellow
    try {
        $p = Start-Process -FilePath $psftpCmd -ArgumentList @('-P', "$port", '-pw', "$pw", ("{0}@{1}" -f $user, $sftpHost), '-b', "$script") -PassThru -ErrorAction Stop
        $p.WaitForExit()
        Write-Host "SFTP upload completed." -ForegroundColor Green

        $base = Split-Path -Leaf $local
        $tmpGet = New-TempFilePath -Prefix 'sftp_verify' -BaseName $base
        $script2 = New-TempScriptFile -Prefix 'psftp' -Lines @("cd $remotePath","get $base $tmpGet","quit")
        Write-Host "Verifying upload by re-downloading for hash compare..." -ForegroundColor Cyan
        $p2 = Start-Process -FilePath $psftpCmd -ArgumentList @('-P', "$port", '-pw', "$pw", ("{0}@{1}" -f $user, $sftpHost), '-b', "$script2") -PassThru -ErrorAction Stop
        $p2.WaitForExit()
        $h1 = Get-FileHash -Path $local -Algorithm SHA256
        $h2 = Get-FileHash -Path $tmpGet -Algorithm SHA256
        if ($h1.Hash -eq $h2.Hash) { Write-Host "Verification OK: SHA256 hashes match." -ForegroundColor Green }
        else { Write-Host "Verification FAILED: SHA256 mismatch." -ForegroundColor Red }
        try { Remove-Item -LiteralPath $tmpGet -Force -ErrorAction SilentlyContinue } catch {}
    }
    catch { Write-Host "Failed to start SFTP upload: $_" -ForegroundColor Red }
    finally { try { Remove-Item -LiteralPath $script -Force -ErrorAction SilentlyContinue } catch {} }
    Pause-Return
}

function Start-SFTPDownloadInteractive {
    Show-Header -Title "Network Tools :: SFTP Download (psftp)"
    $def = Get-TransferDefaults
    $sftpHost = Read-Host ("SFTP host" + ($(if($def.SFTPHost){" [default: $($def.SFTPHost)]"})))
    if ([string]::IsNullOrWhiteSpace($sftpHost)) { $sftpHost = $def.SFTPHost }
    $user = Read-Host ("SFTP username" + ($(if($def.SFTPUser){" [default: $($def.SFTPUser)]"})))
    if ([string]::IsNullOrWhiteSpace($user)) { $user = $def.SFTPUser }
    $portIn = Read-Host ("SFTP port (default 22)" + ($(if($def.SFTPPort){" [default: $($def.SFTPPort)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = ($def.SFTPPort,'22' | Where-Object { $_ })[0] }
    [int]$port = 22; [void][int]::TryParse($portIn, [ref]$port)
    $remotePath = Read-Host ("Remote path (folder)" + ($(if($def.SFTPRemotePath){" [default: $($def.SFTPRemotePath)]"})))
    if ([string]::IsNullOrWhiteSpace($remotePath)) { $remotePath = $def.SFTPRemotePath }
    $remoteFile = Read-Host "Remote file name to download"
    $localDest = Read-Host "Local destination file path"

    $cred = Get-Credential -Message "Enter SFTP password for $user@$sftpHost" -UserName $user
    $pw = $cred.GetNetworkCredential().Password

    $psftpCmd = $null
    $cmdFound = Get-Command psftp -ErrorAction SilentlyContinue
    if ($cmdFound) { $psftpCmd = $cmdFound.Source } else { $psftpCmd = ($def.PSFTPPath) }
    if ([string]::IsNullOrWhiteSpace($psftpCmd)) { Write-Host "psftp.exe not found." -ForegroundColor Red; Pause-Return; return }

    $script = New-TempScriptFile -Prefix 'psftp' -Lines @("cd $remotePath","get $remoteFile $localDest","quit")
    Write-Host ("Downloading via SFTP: {0}:{1}/{2} -> {3}" -f $sftpHost, $remotePath, $remoteFile, $localDest) -ForegroundColor Yellow
    try {
        $p = Start-Process -FilePath $psftpCmd -ArgumentList @('-P', "$port", '-pw', "$pw", ("{0}@{1}" -f $user, $sftpHost), '-b', "$script") -PassThru -ErrorAction Stop
        $p.WaitForExit()
        Write-Host "SFTP download completed." -ForegroundColor Green

        $tmpGet = New-TempFilePath -Prefix 'sftp_verify' -BaseName $remoteFile
        $script2 = New-TempScriptFile -Prefix 'psftp' -Lines @("cd $remotePath","get $remoteFile $tmpGet","quit")
        Write-Host "Verifying download by re-downloading for hash compare..." -ForegroundColor Cyan
        $p2 = Start-Process -FilePath $psftpCmd -ArgumentList @('-P', "$port", '-pw', "$pw", ("{0}@{1}" -f $user, $sftpHost), '-b', "$script2") -PassThru -ErrorAction Stop
        $p2.WaitForExit()
        $h1 = Get-FileHash -Path $localDest -Algorithm SHA256
        $h2 = Get-FileHash -Path $tmpGet -Algorithm SHA256
        if ($h1.Hash -eq $h2.Hash) { Write-Host "Verification OK: SHA256 hashes match." -ForegroundColor Green }
        else { Write-Host "Verification FAILED: SHA256 mismatch." -ForegroundColor Red }
        try { Remove-Item -LiteralPath $tmpGet -Force -ErrorAction SilentlyContinue } catch {}
    }
    catch { Write-Host "Failed to start SFTP download: $_" -ForegroundColor Red }
    finally { try { Remove-Item -LiteralPath $script -Force -ErrorAction SilentlyContinue } catch {} }
    Pause-Return
}

function Start-FTPUploadInteractive {
    Show-Header -Title "Network Tools :: FTP Upload (ftp.exe)"
    $def = Get-TransferDefaults
    $ftpHost = Read-Host ("FTP host" + ($(if($def.FTPHost){" [default: $($def.FTPHost)]"})))
    if ([string]::IsNullOrWhiteSpace($ftpHost)) { $ftpHost = $def.FTPHost }
    $portIn = Read-Host ("FTP port (default 21)" + ($(if($def.FTPPort){" [default: $($def.FTPPort)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = ($def.FTPPort,'21' | Where-Object { $_ })[0] }
    [int]$port = 21; [void][int]::TryParse($portIn, [ref]$port)
    $user = Read-Host "FTP username"
    $cred = Get-Credential -Message "Enter FTP password for $user@$ftpHost" -UserName $user
    $pw = $cred.GetNetworkCredential().Password
    $local = Read-Host "Local file to upload"
    if (-not (Test-Path -LiteralPath $local -PathType Leaf)) { Write-Host "Local file not found." -ForegroundColor Red; Pause-Return; return }
    $remotePath = Read-Host ("Remote path (folder)" + ($(if($def.FTPRemotePath){" [default: $($def.FTPRemotePath)]"})))
    if ([string]::IsNullOrWhiteSpace($remotePath)) { $remotePath = $def.FTPRemotePath }

    $lines = @("open $ftpHost $port","user $user $pw","binary","cd $remotePath","put $local","quit")
    $script = New-TempScriptFile -Prefix 'ftp' -Lines $lines
    Write-Host ("Uploading via FTP: {0} -> {1}:{2}" -f $local, $ftpHost, $remotePath) -ForegroundColor Yellow
    try {
        $p = Start-Process -FilePath 'ftp' -ArgumentList @("-s:$script") -PassThru -ErrorAction Stop
        $p.WaitForExit()
        Write-Host "FTP upload completed." -ForegroundColor Green

        $base = Split-Path -Leaf $local
        $tmpGet = New-TempFilePath -Prefix 'ftp_verify' -BaseName $base
        $lines2 = @("open $ftpHost $port","user $user $pw","binary","cd $remotePath","get $base $tmpGet","quit")
        $script2 = New-TempScriptFile -Prefix 'ftp' -Lines $lines2
        Write-Host "Verifying upload by re-downloading for hash compare..." -ForegroundColor Cyan
        $p2 = Start-Process -FilePath 'ftp' -ArgumentList @("-s:$script2") -PassThru -ErrorAction Stop
        $p2.WaitForExit()
        $h1 = Get-FileHash -Path $local -Algorithm SHA256
        $h2 = Get-FileHash -Path $tmpGet -Algorithm SHA256
        if ($h1.Hash -eq $h2.Hash) { Write-Host "Verification OK: SHA256 hashes match." -ForegroundColor Green }
        else { Write-Host "Verification FAILED: SHA256 mismatch." -ForegroundColor Red }
        try { Remove-Item -LiteralPath $tmpGet -Force -ErrorAction SilentlyContinue } catch {}
    }
    catch { Write-Host "Failed to start FTP upload: $_" -ForegroundColor Red }
    finally { try { Remove-Item -LiteralPath $script -Force -ErrorAction SilentlyContinue } catch {} }
    Pause-Return
}

function Start-FTPDownloadInteractive {
    Show-Header -Title "Network Tools :: FTP Download (ftp.exe)"
    $def = Get-TransferDefaults
    $ftpHost = Read-Host ("FTP host" + ($(if($def.FTPHost){" [default: $($def.FTPHost)]"})))
    if ([string]::IsNullOrWhiteSpace($ftpHost)) { $ftpHost = $def.FTPHost }
    $portIn = Read-Host ("FTP port (default 21)" + ($(if($def.FTPPort){" [default: $($def.FTPPort)]"})))
    if ([string]::IsNullOrWhiteSpace($portIn)) { $portIn = ($def.FTPPort,'21' | Where-Object { $_ })[0] }
    [int]$port = 21; [void][int]::TryParse($portIn, [ref]$port)
    $user = Read-Host "FTP username"
    $cred = Get-Credential -Message "Enter FTP password for $user@$ftpHost" -UserName $user
    $pw = $cred.GetNetworkCredential().Password
    $remotePath = Read-Host ("Remote path (folder)" + ($(if($def.FTPRemotePath){" [default: $($def.FTPRemotePath)]"})))
    if ([string]::IsNullOrWhiteSpace($remotePath)) { $remotePath = $def.FTPRemotePath }
    $remoteFile = Read-Host "Remote file name to download"
    $localDest = Read-Host "Local destination file path"

    $lines = @("open $ftpHost $port","user $user $pw","binary","cd $remotePath","get $remoteFile $localDest","quit")
    $script = New-TempScriptFile -Prefix 'ftp' -Lines $lines
    Write-Host ("Downloading via FTP: {0}:{1}/{2} -> {3}" -f $ftpHost, $remotePath, $remoteFile, $localDest) -ForegroundColor Yellow
    try {
        $p = Start-Process -FilePath 'ftp' -ArgumentList @("-s:$script") -PassThru -ErrorAction Stop
        $p.WaitForExit()
        Write-Host "FTP download completed." -ForegroundColor Green

        $tmpGet = New-TempFilePath -Prefix 'ftp_verify' -BaseName $remoteFile
        $lines2 = @("open $ftpHost $port","user $user $pw","binary","cd $remotePath","get $remoteFile $tmpGet","quit")
        $script2 = New-TempScriptFile -Prefix 'ftp' -Lines $lines2
        Write-Host "Verifying download by re-downloading for hash compare..." -ForegroundColor Cyan
        $p2 = Start-Process -FilePath 'ftp' -ArgumentList @("-s:$script2") -PassThru -ErrorAction Stop
        $p2.WaitForExit()
        $h1 = Get-FileHash -Path $localDest -Algorithm SHA256
        $h2 = Get-FileHash -Path $tmpGet -Algorithm SHA256
        if ($h1.Hash -eq $h2.Hash) { Write-Host "Verification OK: SHA256 hashes match." -ForegroundColor Green }
        else { Write-Host "Verification FAILED: SHA256 mismatch." -ForegroundColor Red }
        try { Remove-Item -LiteralPath $tmpGet -Force -ErrorAction SilentlyContinue } catch {}
    }
    catch { Write-Host "Failed to start FTP download: $_" -ForegroundColor Red }
    finally { try { Remove-Item -LiteralPath $script -Force -ErrorAction SilentlyContinue } catch {} }
    Pause-Return
}
