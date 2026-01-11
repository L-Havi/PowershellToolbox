# System Tools

function Show-DiskUsage {
    Show-Header -Title "System Tools :: Disk Usage"
    Get-PSDrive -PSProvider FileSystem |
        Select-Object Name,
            @{Name='Used(GB)';Expression={"{0:N2}" -f (($_.Used/1GB))}},
            @{Name='Free(GB)';Expression={"{0:N2}" -f (($_.Free/1GB))}},
            @{Name='Total(GB)';Expression={"{0:N2}" -f (($_.Used + $_.Free)/1GB)}} |
        Format-Table -AutoSize
    Pause-Return
}

function Show-Processes {
    Show-Header -Title "System Tools :: Top Processes (Memory)"
    Get-Process | Sort-Object WorkingSet -Descending |
        Select-Object -First 20 Name, Id, @{Name='Memory(MB)';Expression={"{0:N1}" -f ($_.WorkingSet/1MB)}} |
        Format-Table -AutoSize
    Pause-Return
}

function System-InfoSummary {
    Show-Header -Title "System Tools :: System Info Summary"
    Write-Host "Computer Name: $env:COMPUTERNAME" -ForegroundColor White
    Write-Host "User Name    : $env:USERNAME" -ForegroundColor White
    Write-Host "OS Version   : $([Environment]::OSVersion.VersionString)" -ForegroundColor White
    Write-Host ""
    Write-Host "CPU & Memory:" -ForegroundColor Cyan
    Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model,
        @{Name='TotalPhysicalMemory(GB)';Expression={ "{0:N2}" -f ($_.TotalPhysicalMemory/1GB)}} |
        Format-Table -AutoSize
    Write-Host ""; Write-Host "Operating System:" -ForegroundColor Cyan
    Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture, LastBootUpTime |
        Format-Table -AutoSize
    Pause-Return
}

function Show-SystemToolsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "System Tools"
        Write-Host " [1] Diagnostics" -ForegroundColor White
        Write-Host " [2] Services" -ForegroundColor White
        Write-Host " [3] Processes" -ForegroundColor White
        Write-Host " [4] Registry" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back to main menu" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Show-SystemDiagnosticsMenu }
            '2' { Show-ServicesMenu }
            '3' { Show-ProcessesMenu }
            '4' { Show-RegistryMenu }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-SystemDiagnosticsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "System Tools :: Diagnostics"
        Write-Host " [1] Disk usage" -ForegroundColor White
        Write-Host " [2] System info summary" -ForegroundColor White
        Write-Host " [3] Top processes by memory" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'System.DiskUsage' -Action { Show-DiskUsage } }
            '2' { Invoke-Tool -Name 'System.InfoSummary' -Action { System-InfoSummary } }
            '3' { Invoke-Tool -Name 'System.TopProcesses' -Action { Show-Processes } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-ServicesMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "System Tools :: Services"
        Write-Host " [1] List all" -ForegroundColor White
        Write-Host " [2] Start a service" -ForegroundColor White
        Write-Host " [3] Restart a service" -ForegroundColor White
        Write-Host " [4] Disable service startup" -ForegroundColor White
        Write-Host " [5] Enable service startup" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'System.ServicesList' -Action { List-AllServices } }
            '2' { Invoke-Tool -Name 'System.ServiceStart' -Action { Start-ServiceInteractive } }
            '3' { Invoke-Tool -Name 'System.ServiceRestart' -Action { Restart-ServiceInteractive } }
            '4' { Invoke-Tool -Name 'System.ServiceDisableStartup' -Action { Disable-ServiceStartup } }
            '5' { Invoke-Tool -Name 'System.ServiceEnableStartup' -Action { Enable-ServiceStartup } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-ProcessesMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "System Tools :: Processes"
        Write-Host " [1] List (filter/sort)" -ForegroundColor White
        Write-Host " [2] Start process" -ForegroundColor White
        Write-Host " [3] Stop process" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'System.ProcessList' -Action { List-ProcessesInteractive } }
            '2' { Invoke-Tool -Name 'System.ProcessStart' -Action { Start-ProcessInteractive } }
            '3' { Invoke-Tool -Name 'System.ProcessStop' -Action { Stop-ProcessInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-RegistryMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "System Tools :: Registry"
        Write-Host " [1] Read value" -ForegroundColor White
        Write-Host " [2] Set value" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'System.RegistryRead' -Action { Read-RegistryValueInteractive } }
            '2' { Invoke-Tool -Name 'System.RegistrySet' -Action { Set-RegistryValueInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function List-AllServices {
    Show-Header -Title "System Tools :: Services - List All"
    try {
        Get-CimInstance Win32_Service |
            Select-Object Name, DisplayName, State, StartMode |
            Format-Table -AutoSize
    } catch {
        Write-Host "Failed to query services: $_" -ForegroundColor Red
    }
    Pause-Return
}

function Start-ServiceInteractive {
    Show-Header -Title "System Tools :: Services - Start"
    $name = Read-Host "Enter service name (e.g., Spooler)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "No service name provided." -ForegroundColor Red; Pause-Return; return }
    try {
        Start-Service -Name $name -ErrorAction Stop
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        Write-Host "Started service '$name'. Status: $($svc.Status)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to start service '$name': $_" -ForegroundColor Red
    }
    Pause-Return
}

function Restart-ServiceInteractive {
    Show-Header -Title "System Tools :: Services - Restart"
    $name = Read-Host "Enter service name (e.g., Spooler)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "No service name provided." -ForegroundColor Red; Pause-Return; return }
    try {
        Restart-Service -Name $name -ErrorAction Stop
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        Write-Host "Restarted service '$name'. Status: $($svc.Status)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to restart service '$name': $_" -ForegroundColor Red
    }
    Pause-Return
}

function Disable-ServiceStartup {
    Show-Header -Title "System Tools :: Services - Disable Startup"
    $name = Read-Host "Enter service name to disable (e.g., Spooler)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "No service name provided." -ForegroundColor Red; Pause-Return; return }
    try {
        Set-Service -Name $name -StartupType Disabled -ErrorAction Stop
        $svc = Get-CimInstance Win32_Service -Filter "Name='$name'" -ErrorAction SilentlyContinue
        Write-Host "Set startup to Disabled for '$name'. Current StartMode: $($svc.StartMode)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to disable startup for '$name': $_" -ForegroundColor Red
    }
    Pause-Return
}

function Enable-ServiceStartup {
    Show-Header -Title "System Tools :: Services - Enable Startup"
    $name = Read-Host "Enter service name to enable (e.g., Spooler)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "No service name provided." -ForegroundColor Red; Pause-Return; return }
    $mode = Read-Host "Startup type: automatic/manual (default: automatic)"
    if ([string]::IsNullOrWhiteSpace($mode)) { $mode = 'automatic' }
    $mode = $mode.ToLowerInvariant()
    $startupType = switch ($mode) { 'manual' { 'Manual' } default { 'Automatic' } }
    try {
        Set-Service -Name $name -StartupType $startupType -ErrorAction Stop
        $svc = Get-CimInstance Win32_Service -Filter "Name='$name'" -ErrorAction SilentlyContinue
        Write-Host "Set startup to $startupType for '$name'. Current StartMode: $($svc.StartMode)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to enable startup for '$name': $_" -ForegroundColor Red
    }
    Pause-Return
}

# New defaults helpers
function Get-ProcessDefaults {
    $sec = Get-ConfigSection -SectionName 'ProcessDefaults'
    return [pscustomobject]@{
        Executable = if ($sec.ContainsKey('Executable')) { $sec['Executable'] } else { '' }
        Arguments  = if ($sec.ContainsKey('Arguments'))  { $sec['Arguments'] } else { '' }
        NameToStop = if ($sec.ContainsKey('NameToStop')) { $sec['NameToStop'] } else { '' }
    }
}

function Get-RegistryDefaults {
    $sec = Get-ConfigSection -SectionName 'RegistryDefaults'
    return [pscustomobject]@{
        Hive      = if ($sec.ContainsKey('Hive'))      { $sec['Hive'] } else { 'HKLM' }
        Path      = if ($sec.ContainsKey('Path'))      { $sec['Path'] } else { '' }
        ValueName = if ($sec.ContainsKey('ValueName')) { $sec['ValueName'] } else { '' }
    }
}

function List-ProcessesInteractive {
    Show-Header -Title "System Tools :: Processes - List"
    $def = Get-ProcessDefaults
    $filter = Read-Host ("Name filter (optional)" )
    $sortBy = Read-Host ("Sort by: memory/cpu (default: memory)")
    if ([string]::IsNullOrWhiteSpace($sortBy)) { $sortBy = 'memory' }
    $topIn = Read-Host ("Show top N (optional)")
    [int]$top = 0; [void][int]::TryParse($topIn, [ref]$top)
    $procs = Get-Process
    if (-not [string]::IsNullOrWhiteSpace($filter)) { $procs = $procs | Where-Object { $_.Name -like ("*{0}*" -f $filter) } }
    $procs = $procs | Select-Object Name, Id,
        @{Name='CPU(s)';Expression={$_.CPU}},
        @{Name='Memory(MB)';Expression={"{0:N1}" -f ($_.WorkingSet/1MB)}}
    if ($sortBy.ToLowerInvariant() -eq 'cpu') { $procs = $procs | Sort-Object 'CPU(s)' -Descending }
    else { $procs = $procs | Sort-Object {[double]($_.'Memory(MB)')} -Descending }
    if ($top -gt 0) { $procs = $procs | Select-Object -First $top }
    $procs | Format-Table -AutoSize
    Pause-Return
}

function Start-ProcessInteractive {
    Show-Header -Title "System Tools :: Processes - Start"
    $def = Get-ProcessDefaults
    $exe = Read-Host ("Executable path" + ($(if($def.Executable){" [default: $($def.Executable)]"})))
    if ([string]::IsNullOrWhiteSpace($exe)) { $exe = $def.Executable }
    $args = Read-Host ("Arguments (optional)" + ($(if($def.Arguments){" [default: $($def.Arguments)]"})))
    if ([string]::IsNullOrWhiteSpace($args)) { $args = $def.Arguments }
    if ([string]::IsNullOrWhiteSpace($exe)) { Write-Host "No executable provided." -ForegroundColor Red; Pause-Return; return }
    Write-Host ("Starting: {0} {1}" -f $exe, $args) -ForegroundColor Yellow
    $confirm = Read-Host "Proceed? (y/N)"; if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try {
        if ([string]::IsNullOrWhiteSpace($args)) { Start-Process -FilePath $exe -ErrorAction Stop | Out-Null }
        else { Start-Process -FilePath $exe -ArgumentList $args -ErrorAction Stop | Out-Null }
        Write-Host "Process started." -ForegroundColor Green
    } catch { Write-Host "Failed to start process: $_" -ForegroundColor Red }
    Pause-Return
}

function Stop-ProcessInteractive {
    Show-Header -Title "System Tools :: Processes - Stop"
    $def = Get-ProcessDefaults
    $target = Read-Host ("Process Name or PID" + ($(if($def.NameToStop){" [default: $($def.NameToStop)]"})))
    if ([string]::IsNullOrWhiteSpace($target)) { $target = $def.NameToStop }
    if ([string]::IsNullOrWhiteSpace($target)) { Write-Host "No target provided." -ForegroundColor Red; Pause-Return; return }
    Write-Host ("Stopping: {0}" -f $target) -ForegroundColor Yellow
    $confirm = Read-Host "Proceed? (y/N)"; if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try {
        [int]$procId = 0
        if ([int]::TryParse($target, [ref]$procId)) { Stop-Process -Id $procId -Force -ErrorAction Stop }
        else { Stop-Process -Name $target -Force -ErrorAction Stop }
        Write-Host "Process stopped." -ForegroundColor Green
    } catch { Write-Host "Failed to stop process: $_" -ForegroundColor Red }
    Pause-Return
}

function Read-RegistryValueInteractive {
    Show-Header -Title "System Tools :: Registry - Read Value"
    $def = Get-RegistryDefaults
    $hive = Read-Host ("Hive (HKLM/HKCU)" + ($(if($def.Hive){" [default: $($def.Hive)]"})))
    if ([string]::IsNullOrWhiteSpace($hive)) { $hive = $def.Hive }
    $path = Read-Host ("Key path" + ($(if($def.Path){" [default: $($def.Path)]"})))
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $def.Path }
    $name = Read-Host ("Value name" + ($(if($def.ValueName){" [default: $($def.ValueName)]"})))
    if ([string]::IsNullOrWhiteSpace($name)) { $name = $def.ValueName }
    if ([string]::IsNullOrWhiteSpace($hive) -or [string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($name)) { Write-Host "Hive, path, and value name are required." -ForegroundColor Red; Pause-Return; return }
        $regRoot = "$($hive.Trim().ToUpper()):\"
        $normPath = (($path -replace '[\\/]+','\').TrimStart('\'))
        $regPath = Join-Path -Path $regRoot -ChildPath $normPath
    try {
        $val = Get-ItemProperty -Path $regPath -Name $name
        Write-Host ("{0} => {1}" -f $name, ($val.$name)) -ForegroundColor Green
    } catch { Write-Host "Failed to read registry value: $_" -ForegroundColor Red }
    Pause-Return
}

function Set-RegistryValueInteractive {
    Show-Header -Title "System Tools :: Registry - Set Value"
    $def = Get-RegistryDefaults
    $hive = Read-Host ("Hive (HKLM/HKCU)" + ($(if($def.Hive){" [default: $($def.Hive)]"})))
    if ([string]::IsNullOrWhiteSpace($hive)) { $hive = $def.Hive }
    $path = Read-Host ("Key path" + ($(if($def.Path){" [default: $($def.Path)]"})))
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $def.Path }
    $name = Read-Host ("Value name" + ($(if($def.ValueName){" [default: $($def.ValueName)]"})))
    if ([string]::IsNullOrWhiteSpace($name)) { $name = $def.ValueName }
    $data = Read-Host "New value data (string)"
    if ([string]::IsNullOrWhiteSpace($hive) -or [string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($name)) { Write-Host "Hive, path, and value name are required." -ForegroundColor Red; Pause-Return; return }
        $regRoot = "$($hive.Trim().ToUpper()):\"
        $normPath = (($path -replace '[\\/]+','\').TrimStart('\'))
        $regPath = Join-Path -Path $regRoot -ChildPath $normPath
    Write-Host ("Set {0}\{1}::{2} = '{3}'" -f $hive.Trim().ToUpper(), $normPath, $name, $data) -ForegroundColor Yellow
    $confirm = Read-Host "Proceed? (y/N)"; if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { Set-ItemProperty -Path $regPath -Name $name -Value $data; Write-Host "Registry value updated." -ForegroundColor Green }
    catch { Write-Host "Failed to set registry value: $_" -ForegroundColor Red }
    Pause-Return
}
