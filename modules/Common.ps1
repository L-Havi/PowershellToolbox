# Common helpers and configuration/SSH utilities

function Clear-Screen {
    Clear-Host
}

function Show-Header {
    param(
        [string]$Title = "PowerShell Toolbox",
        [switch]$NoClear
    )

    if (-not $NoClear) { Clear-Screen }
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ("                 {0}" -f $Title) -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-StartScreen {
    Clear-Screen

    $psver = $PSVersionTable.PSVersion.ToString()
    $date  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $hostn = $env:COMPUTERNAME
    $user  = $env:USERNAME

    # Generate a PowerShell-like glyph (white '>' and underscore) on blue background
    $logo = @(
        "NNNMMWNNWMWNNWMMWNNWMWNNWMMNNNWMMWNNWMWNNWMMWNNWMWNNWMWNNWMM",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "WNWWWWNNWMWNNWWWWNNWWWNNWWWWNWWWWWNNWWWNNWWWWNWWWWNNWWWWNWWM",
        "WWWNNWWWWNWWWWNNWNK0000000000000000000000000000KXWWWWNNWWWNN",
        "WWWWWWWWWWWWNWWWKdc::::looc::::::::::::::::::::cONWWWWWWWWWW",
        "WWWWWWWWWWWWWWWNx:::::o0NNOo:;:::::::::::::;::;l0WWWWWWWWWWW",
        "WMWNNWWWWNNWMWN0l:::::ckXWWNOl:::::::::::::::;:dXWWWWNNWMWNN",
        "WNWWWWNNWWWNNWNkc:;:::::oONMWX0kl:::;:::::::::cOWWNNWMWWNWWM",
        "WWWWWWWWWWWWWWKo::::::::::o0NMMWKxc:;::::;:;;:dKWWWWWWWWWWWW",
        "WWWWNWWWWWWWWNkc;::::::::::cdKNWMWKd:;;:::;:;ckNWWWWWWWWWWWW",
        "WNWWWWNNWMWNNKo::::::;::::::oONWMWNkc;:::::::oKWMWNNWMWNNWWM",
        "WWWNNWWWWNWWWOc::::::::::lx0NWWNKxl:::::::::ckNNNWWWWNNWWWNN",
        "WWWWWWWWWWWWXd:::;::::cdOXWWKkxoc:;:::::::::l0WWWWWWWWWWWWWW",
        "WWWWWWNWWWWNOc;::::cokKWWXOxocccccccc:;:::;:xXWWWWWWWWWWWWWW",
        "WMWNNWWWWNNXd:::::o0NWN0xld0XXXXXXXXKd:;:::l0WWNNWWWWNNWMWNN",
        "WNWWWWNNWWWOl:::::dO0ko:::okOOOOOOOOko:::;:dXNNWMWNNWWWWNWWM",
        "WWWWWWWWWWNOlcccccccccccccccccccccccccccccdKNWWWWWWWWWWWWWWW",
        "WWWWNWWWWNNNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXNWWWWWNWWWWNWWWWWW",
        "NNWWMWNNWMWNNWWWWNNWMWNNWMWWNWWWWWNNWMWNNWWWWNNWMWNNWMWNNWWM",
        "WWWNNWWWWNWWWWNNWMWWNWWWWNNWWWWNNWWWNNWWWWNNWMWNNWWWWNNWWWNN",
        "WWWWWWWWWWWWWWWWWWNWNNWWNNNWWWNNNNNWNNNWWWWWWWWWWWWWWWWWWWWW",
        "NNNMMWNNWMWNNWMMNXNWWWWWWWWWWWWWNNNNNNNWWWWWNNNWMWNNWMMNNNMM"
    )

    $topLine    = "WWWNNWWWWNWWWWNNWNK0000000000000000000000000000KXWWWWNNWWWNN"
    $bottomLine = "WWWWWWWWWWNOlcccccccccccccccccccccccccccccdKNWWWWWWWWWWWWWWW"
    $topIdx     = [System.Array]::IndexOf($logo, $topLine)
    $bottomIdx  = [System.Array]::IndexOf($logo, $bottomLine)
    $baseSegments = @('looc')

    for ($row = 0; $row -lt $logo.Count; $row++) {
        $line = $logo[$row]

        if ($row -lt $topIdx -or $row -gt $bottomIdx -or $row -eq $topIdx -or $row -eq $bottomIdx) {
            Write-Host $line -ForegroundColor Black
            continue
        }

        $firstColon = $line.IndexOf(':')
        $firstSemi  = $line.IndexOf(';')
        if ($firstColon -eq -1 -and $firstSemi -eq -1) {
            # No delimiters: preserve original mid coloring (white, blue for ':' ';')
            foreach ($ch in $line.ToCharArray()) {
                if ($ch -eq ':' -or $ch -eq ';') { Write-Host $ch -ForegroundColor Blue -NoNewline }
                else { Write-Host $ch -ForegroundColor White -NoNewline }
            }
            Write-Host
            continue
        }
        if ($firstColon -eq -1) { $firstDelim = $firstSemi }
        elseif ($firstSemi -eq -1) { $firstDelim = $firstColon }
        else { $firstDelim = [Math]::Min($firstColon, $firstSemi) }

        $lastColon = $line.LastIndexOf(':')
        $lastSemi  = $line.LastIndexOf(';')
        $lastDelim = if ($lastColon -eq -1 -and $lastSemi -eq -1) { $firstDelim } else { [Math]::Max($lastColon, $lastSemi) }

        # Row-specific blue segments
        $rowSegments = @()
        $rowSegments += $baseSegments
        if ($row -eq 14) { $rowSegments += 'cccccccc' }      # row 15 (1-based)
        if ($row -eq 15) { $rowSegments += 'xld' }           # row 16 (1-based)
        if ($row -eq 16) { $rowSegments += ':::::dO0ko:::okOOOOOOOOko:::;:' } # row 17 (1-based)

        $i = 0
        while ($i -lt $line.Length) {
            if ($i -lt $firstDelim -or $i -gt $lastDelim) {
                # Outer segments → black
                Write-Host $line[$i] -ForegroundColor Black -NoNewline
                $i++
                continue
            }

            # Inside between first and last delimiter: blue substrings and delimiters; white otherwise
            $matched = $false
            foreach ($seg in $rowSegments) {
                if ($i + $seg.Length -le $line.Length -and $line.Substring($i, $seg.Length) -eq $seg) {
                    Write-Host $seg -ForegroundColor Blue -NoNewline
                    $i += $seg.Length
                    $matched = $true
                    break
                }
            }
            if ($matched) { continue }

            $ch = $line[$i]
            if ($ch -eq ':' -or $ch -eq ';') { Write-Host $ch -ForegroundColor Blue -NoNewline }
            else { Write-Host $ch -ForegroundColor White -NoNewline }
            $i++
        }
        Write-Host
    }

    Write-Host ""
    Write-Host "PowerShell Toolbox"
    Write-Host "PS $psver  |  $hostn\$user  |  $date"
    Write-Host "Config: $Global:LabConfigFile"
    Write-Host ""
}

function Pause-Return {
    Write-Host ""
    Write-Host "Press Enter to return to the menu..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
}

function Show-ProgressWrapper {
    param(
        [string]$Activity,
        [int]$PercentComplete
    )
    Write-Progress -Activity $Activity -Status "$PercentComplete% complete" -PercentComplete $PercentComplete
}

# Config handling utilities
function Get-ConfigSection {
    param(
        [Parameter(Mandatory=$true)][string]$SectionName
    )

    if (-not $Global:LabConfigFile) {
        $Global:LabConfigFile = Join-Path (Split-Path -Parent $PSScriptRoot) "config.yaml"
    }
    if (-not (Test-Path $Global:LabConfigFile)) { return @{} }

    $result    = @{}
    $inSection = $false

    Get-Content $Global:LabConfigFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -like "#*" -or $line -eq "") { return }

        if ($line -eq "${SectionName}:") { $inSection = $true; return }

        if ($inSection -and $line -match '^[A-Za-z0-9_]+:\s*$') { $inSection = $false; return }

        if (-not $inSection) { return }

        if ($line -match "^(?<Key>[A-Za-z0-9_]+)\s*:\s*[`"']?(?<Val>.+?)[`"']?`$") {
            $key = $matches['Key']
            $val = $matches['Val']
            $result[$key] = $val
        }
    }

    return $result
}

function Get-ProxmoxDefaults {
    $section = Get-ConfigSection -SectionName "ProxmoxDefaults"

    return [PSCustomObject]@{
        Host = if ($section.ContainsKey("Host")) { $section["Host"] } else { "" }
        User = if ($section.ContainsKey("User")) { $section["User"] } else { "" }
        SshMethod = if ($section.ContainsKey("SshMethod")) { $section["SshMethod"] } else { "ssh" }
        PlinkPath = if ($section.ContainsKey("PlinkPath")) { $section["PlinkPath"] } else { "plink.exe" }
    }
}

function Get-VMwareDefaults {
    $section = Get-ConfigSection -SectionName "VmwareDefaults"

    return [PSCustomObject]@{
        Host = if ($section.ContainsKey("Host")) { $section["Host"] } else { "" }
        User = if ($section.ContainsKey("User")) { $section["User"] } else { "" }
        SshMethod = if ($section.ContainsKey("SshMethod")) { $section["SshMethod"] } else { "ssh" }
        PlinkPath = if ($section.ContainsKey("PlinkPath")) { $section["PlinkPath"] } else { "plink.exe" }
    }
}

function Get-AzureDefaults {
    $section = Get-ConfigSection -SectionName "AzureDefaults"

    return [PSCustomObject]@{
        SubscriptionId = if ($section.ContainsKey("SubscriptionId")) { $section["SubscriptionId"] } else { "" }
        TenantId       = if ($section.ContainsKey("TenantId")) { $section["TenantId"] } else { "" }
        ResourceGroup  = if ($section.ContainsKey("ResourceGroup")) { $section["ResourceGroup"] } else { "" }
        Location       = if ($section.ContainsKey("Location")) { $section["Location"] } else { "" }
        RoleDefinitionName = if ($section.ContainsKey("RoleDefinitionName")) { $section["RoleDefinitionName"] } else { "Contributor" }
        DefaultVNetName    = if ($section.ContainsKey("DefaultVNetName")) { $section["DefaultVNetName"] } else { "" }
        DefaultSubnetName  = if ($section.ContainsKey("DefaultSubnetName")) { $section["DefaultSubnetName"] } else { "" }
        DefaultNSGName     = if ($section.ContainsKey("DefaultNSGName")) { $section["DefaultNSGName"] } else { "" }
        DefaultImage       = if ($section.ContainsKey("DefaultImage")) { $section["DefaultImage"] } else { "UbuntuLTS" }
        DefaultVMSize      = if ($section.ContainsKey("DefaultVMSize")) { $section["DefaultVMSize"] } else { "Standard_B2s" }
    }
}

function Get-AppOutputSettings {
    $sec = Get-ConfigSection -SectionName "OutputSettings"
    return [PSCustomObject]@{
        Enabled = if ($sec.ContainsKey('Enabled')) { [System.Convert]::ToBoolean($sec['Enabled']) } else { $false }
        Folder  = if ($sec.ContainsKey('Folder')) { $sec['Folder'] } else { (Join-Path (Split-Path -Parent $PSScriptRoot) 'output') }
        WriteHashManifest = if ($sec.ContainsKey('WriteHashManifest')) { [System.Convert]::ToBoolean($sec['WriteHashManifest']) } else { $true }
    }
}

function Get-AppLoggingSettings {
    $sec = Get-ConfigSection -SectionName "LoggingSettings"
    return [PSCustomObject]@{
        Enabled = if ($sec.ContainsKey('Enabled')) { [System.Convert]::ToBoolean($sec['Enabled']) } else { $false }
        Folder  = if ($sec.ContainsKey('Folder')) { $sec['Folder'] } else { (Join-Path (Split-Path -Parent $PSScriptRoot) 'logs') }
        FileName = if ($sec.ContainsKey('FileName')) { $sec['FileName'] } else { 'toolbox.log' }
    }
}

function Initialize-AppIO {
    $out = Get-AppOutputSettings
    $log = Get-AppLoggingSettings
    try { if (-not (Test-Path -LiteralPath $out.Folder)) { New-Item -ItemType Directory -Path $out.Folder -Force | Out-Null } } catch {}
    try { if (-not (Test-Path -LiteralPath $log.Folder)) { New-Item -ItemType Directory -Path $log.Folder -Force | Out-Null } } catch {}
}

function Write-ToolLog {
    param([Parameter(Mandatory=$true)][string]$Message)
    $log = Get-AppLoggingSettings
    if (-not $log.Enabled) { return }
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $path = Join-Path $log.Folder $log.FileName
    try { Add-Content -Path $path -Value "[$ts] $Message" -Encoding utf8 } catch {}
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$Action
    )
    $out = Get-AppOutputSettings
    $log = Get-AppLoggingSettings
    $transcriptStarted = $false
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outFile = Join-Path $out.Folder ("{0}_{1}.txt" -f ($Name -replace '[^A-Za-z0-9_\-]', '_'), $stamp)
    Write-ToolLog -Message ("START {0}" -f $Name)
    if ($out.Enabled) {
        try { Start-Transcript -Path $outFile -Force -ErrorAction Stop; $transcriptStarted = $true } catch { Write-ToolLog -Message ("Transcript failed to start: {0}" -f $_) }
    }
    try { & $Action } finally {
        if ($transcriptStarted) { try { Stop-Transcript | Out-Null } catch {} }
        Write-ToolLog -Message ("END {0}" -f $Name)
    }
}

# SSH helpers
function Invoke-LabSSH {
    param(
        [Parameter(Mandatory=$true)][string]$User,
        [Parameter(Mandatory=$true)][string]$LabHost,
        [Parameter(Mandatory=$true)][string]$RemoteCommand
    )

    $cmd = "ssh $User@$LabHost $RemoteCommand"
    Write-Host "Running (ssh): $cmd" -ForegroundColor DarkGray
    return Invoke-Expression $cmd
}

function Invoke-LabPlink {
    param(
        [Parameter(Mandatory=$true)][string]$User,
        [Parameter(Mandatory=$true)][string]$LabHost,
        [Parameter(Mandatory=$true)][string]$RemoteCommand,
        [Parameter(Mandatory=$true)][string]$PlinkPath
    )

    $cmd = "`"$PlinkPath`" -ssh $User@$LabHost `"$RemoteCommand`""
    Write-Host "Running (plink): $cmd" -ForegroundColor DarkGray
    return Invoke-Expression $cmd
}

function Invoke-LabRemoteCommand {
    param(
        [Parameter(Mandatory=$true)]$Conn,
        [Parameter(Mandatory=$true)][string]$RemoteCommand
    )

    if ([string]::IsNullOrWhiteSpace($Conn.LabHost) -or [string]::IsNullOrWhiteSpace($Conn.User)) {
        Write-Host "LabHost or User is empty. Please provide valid values." -ForegroundColor Red
        return $null
    }

    if ($Conn.SshMethod -eq "plink") {
        return Invoke-LabPlink -User $Conn.User -LabHost $Conn.LabHost -RemoteCommand $RemoteCommand -PlinkPath $Conn.PlinkPath
    } else {
        return Invoke-LabSSH -User $Conn.User -LabHost $Conn.LabHost -RemoteCommand $RemoteCommand
    }
}
