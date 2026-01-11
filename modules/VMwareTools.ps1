# VMware Tools

function Get-VMwareConnectionInfo {
    $cfg = Get-VMwareDefaults
    Write-Host "Enter VMware SSH connection details (leave empty to use VmwareDefaults from config.yaml):" -ForegroundColor Cyan
    Write-Host "(If no config file exists, empty = blank defaults.)" -ForegroundColor DarkGray
    Write-Host ""
    $hostPrompt = if ($cfg.Host) { "VMware host or IP (default: $($cfg.Host))" } else { "VMware host or IP (no default)" }
    $userPrompt = if ($cfg.User) { "SSH username (default: $($cfg.User))" } else { "SSH username (no default)" }
    $hostInput = Read-Host $hostPrompt
    $userInput = Read-Host $userPrompt
    $sshMethodPrompt = "SSH method - 'ssh' or 'plink' (default: $($cfg.SshMethod))"
    $sshMethodInput  = Read-Host $sshMethodPrompt
    if ([string]::IsNullOrWhiteSpace($hostInput)) { $hostInput = $cfg.Host }
    if ([string]::IsNullOrWhiteSpace($userInput)) { $userInput = $cfg.User }
    if ([string]::IsNullOrWhiteSpace($sshMethodInput)) { $sshMethodInput = $cfg.SshMethod }
    $sshMethodInput = $sshMethodInput.ToLowerInvariant()
    if ($sshMethodInput -notin @("ssh", "plink")) { Write-Host "Invalid SSH method '$sshMethodInput'. Falling back to 'ssh'." -ForegroundColor Yellow; $sshMethodInput = "ssh" }
    $plinkPath = $cfg.PlinkPath
    if ($sshMethodInput -eq "plink") { $plinkPrompt = "Plink path (default: $($cfg.PlinkPath))"; $plinkInput  = Read-Host $plinkPrompt; if (-not [string]::IsNullOrWhiteSpace($plinkInput)) { $plinkPath = $plinkInput } }
    return [PSCustomObject]@{ LabHost = $hostInput; User = $userInput; SshMethod = $sshMethodInput; PlinkPath = $plinkPath }
}

function Test-VMwareSSHConnection {
    Show-Header -Title "VMware Tools :: Test SSH Connection to Host"
    $info = Get-VMwareConnectionInfo
    Write-Host ""; Write-Host "Testing connectivity to $($info.User)@$($info.LabHost) using '$($info.SshMethod)'..." -ForegroundColor Cyan
    Write-Host "(You may be prompted for password or key passphrase.)" -ForegroundColor DarkGray
    try {
        $output = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "hostname"
        if ($LASTEXITCODE -eq 0 -and $output) { Write-Host ""; Write-Host "SSH connection successful. Remote hostname: $output" -ForegroundColor Green }
        else { Write-Host ""; Write-Host "SSH command exited with code $LASTEXITCODE or empty output. Check credentials/firewall/SSH service." -ForegroundColor Red }
    } catch { Write-Host "Error running SSH/plink: $_" -ForegroundColor Red }
    Pause-Return
}

function Get-VMwareVMList {
    Show-Header -Title "VMware Tools :: List VMs (vim-cmd vmsvc/getallvms)"
    $info = Get-VMwareConnectionInfo
    Write-Host ""; Write-Host "Querying VM list from $($info.User)@$($info.LabHost) using '$($info.SshMethod)'..." -ForegroundColor Cyan
    Write-Host "Command: vim-cmd vmsvc/getallvms" -ForegroundColor DarkGray
    try { $output = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "vim-cmd vmsvc/getallvms"; Write-Host ""; Write-Host "Raw output from 'vim-cmd vmsvc/getallvms':" -ForegroundColor Cyan; Write-Host $output }
    catch { Write-Host "Error retrieving VM list: $_" -ForegroundColor Red }
    Pause-Return
}

function Get-VMwareDatastoreUsage {
    Show-Header -Title "VMware Tools :: Datastore Usage"
    $info = Get-VMwareConnectionInfo
    Write-Host ""; Write-Host "Querying datastore usage from $($info.User)@$($info.LabHost) using '$($info.SshMethod)'..." -ForegroundColor Cyan
    Write-Host "Commands: esxcli storage filesystem list, df -h" -ForegroundColor DarkGray
    try {
        Write-Host ""; Write-Host "== esxcli storage filesystem list ==" -ForegroundColor Yellow
        $out1 = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "esxcli storage filesystem list"
        Write-Host $out1
        Write-Host ""; Write-Host "== df -h (if available on ESXi shell) ==" -ForegroundColor Yellow
        $out2 = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "df -h || echo 'df -h not available on this ESXi shell.'"
        Write-Host $out2
    } catch { Write-Host "Error retrieving datastore usage: $_" -ForegroundColor Red }
    Pause-Return
}

function Show-VMwareToolsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "VMware Tools"
        Write-Host " [1] Connection & Basics" -ForegroundColor White
        Write-Host " [2] VM Lifecycle Management" -ForegroundColor White
        Write-Host " [3] Storage & Datastore Operations" -ForegroundColor White
        Write-Host " [4] Host & Cluster Management" -ForegroundColor White
        Write-Host " [5] User, Role & Permission Management" -ForegroundColor White
        Write-Host " [6] Monitoring, Reporting & Compliance" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back to Hypervisor Tools menu" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Show-VMwareBasicsMenu }
            '2' { Show-VMwareVMLifecycleMenu }
            '3' { Show-VMwareStorageMenu }
            '4' { Show-VMwareHostClusterMenu }
            '5' { Show-VMwareUserPermMenu }
            '6' { Show-VMwareMonitoringMenu }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-VMwareBasicsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "VMware :: Connection & Basics"
        Write-Host " [1] Test SSH connection to VMware host" -ForegroundColor White
        Write-Host " [2] List VMs (vim-cmd vmsvc/getallvms)" -ForegroundColor White
        Write-Host " [3] Datastore usage (esxcli storage filesystem list)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'VMware.TestSSH' -Action { Test-VMwareSSHConnection } }
            '2' { Invoke-Tool -Name 'VMware.ListVMs' -Action { Get-VMwareVMList } }
            '3' { Invoke-Tool -Name 'VMware.DatastoreUsage' -Action { Get-VMwareDatastoreUsage } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-VMwareVMLifecycleMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "VMware :: VM Lifecycle Management"
        Write-Host " [1] Power operations (start/stop/reset/suspend)" -ForegroundColor White
        Write-Host " [2] Delete VM" -ForegroundColor White
        Write-Host " [3] Create snapshot / Revert / Remove" -ForegroundColor White
        Write-Host " [4] Migrate VM (vMotion / Storage vMotion via govc)" -ForegroundColor White
        Write-Host " [5] Create dummy VM (vim-cmd createdummyvm)" -ForegroundColor White
        Write-Host " [6] Clone VM locally (copy+register)" -ForegroundColor White
        Write-Host " [7] Deploy VM from template (govc)" -ForegroundColor White
        Write-Host " [8] Modify VM hardware (CPU/MEM via govc)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'VMware.VM.Power' -Action { VMware-VM-Power } }
            '2' { Invoke-Tool -Name 'VMware.VM.Delete' -Action { VMware-VM-Delete } }
            '3' { Invoke-Tool -Name 'VMware.VM.Snapshot' -Action { VMware-VM-Snapshot } }
            '4' { Invoke-Tool -Name 'VMware.VM.Migrate' -Action { VMware-VM-Migrate } }
            '5' { Invoke-Tool -Name 'VMware.VM.CreateDummy' -Action { VMware-VM-CreateDummy } }
            '6' { Invoke-Tool -Name 'VMware.VM.CloneLocal' -Action { VMware-VM-CloneLocal } }
            '7' { Invoke-Tool -Name 'VMware.VM.DeployTemplate' -Action { VMware-VM-DeployTemplate } }
            '8' { Invoke-Tool -Name 'VMware.VM.SetHardware' -Action { VMware-VM-SetHardware } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
function VMware-VM-SetHardware {
    Show-Header -Title "VMware :: Modify VM Hardware (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot modify VM hardware." -ForegroundColor Yellow; Pause-Return; return }
    $name = Read-Host "VM name"
    $cores = Read-Host "CPU cores (optional)"
    $memMB = Read-Host "Memory MB (optional)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "VM name is required." -ForegroundColor Red; Pause-Return; return }
    $cmd = "$govc vm.change -vm `"$name`""
    if ($cores) { $cmd += " -c $cores" }
    if ($memMB) { $cmd += " -m $memMB" }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Show-VMwareStorageMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "VMware :: Storage & Datastore"
        Write-Host " [1] List datastores (esxcli storage filesystem list)" -ForegroundColor White
        Write-Host " [2] Expand VM disk (vmkfstools -X)" -ForegroundColor White
        Write-Host " [3] Upload ISO to datastore (scp)" -ForegroundColor White
        Write-Host " [4] Create VMFS datastore (esxcli storage vmfs create)" -ForegroundColor White
        Write-Host " [5] Storage policy (govc apply)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'VMware.DatastoreUsage' -Action { Get-VMwareDatastoreUsage } }
            '2' { Invoke-Tool -Name 'VMware.Disk.Expand' -Action { VMware-VM-ExpandDisk } }
            '3' { Invoke-Tool -Name 'VMware.ISO.Upload' -Action { VMware-Upload-ISO } }
            '4' { Invoke-Tool -Name 'VMware.Datastore.Create' -Action { VMware-Datastore-Create } }
            '5' { Invoke-Tool -Name 'VMware.StoragePolicy.Apply' -Action { VMware-StoragePolicy-Apply } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-VMwareHostClusterMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "VMware :: Host & Cluster"
        Write-Host " [1] Add ESXi host to vCenter (govc)" -ForegroundColor White
        Write-Host " [2] Remove ESXi host from vCenter (govc)" -ForegroundColor White
        Write-Host " [3] Configure vSwitch/portgroup/VLAN (esxcli)" -ForegroundColor White
        Write-Host " [4] Rescan storage adapter (esxcli)" -ForegroundColor White
        Write-Host " [5] DRS/HA cluster settings (govc)" -ForegroundColor White
        Write-Host " [6] Patch/update ESXi host (esxcli software profile)" -ForegroundColor White
        Write-Host " [7] Maintenance mode enter/exit (vim-cmd)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'VMware.Host.Add' -Action { VMware-Host-AddToVC } }
            '2' { Invoke-Tool -Name 'VMware.Host.Remove' -Action { VMware-Host-RemoveFromVC } }
            '3' { Invoke-Tool -Name 'VMware.Network.Configure' -Action { VMware-Network-Configure } }
            '4' { Invoke-Tool -Name 'VMware.Storage.Rescan' -Action { VMware-Storage-Adapter-Rescan } }
            '5' { Invoke-Tool -Name 'VMware.Cluster.Settings' -Action { VMware-Cluster-Settings } }
            '6' { Invoke-Tool -Name 'VMware.Host.Patch' -Action { VMware-Host-Patch } }
            '7' { Invoke-Tool -Name 'VMware.Host.Maintenance' -Action { VMware-Host-Maintenance } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-VMwareUserPermMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "VMware :: User, Role & Permission"
        Write-Host " [1] Create ESXi user (esxcli system account add)" -ForegroundColor White
        Write-Host " [2] Create vCenter role (govc role.create)" -ForegroundColor White
        Write-Host " [3] Assign permissions (govc permissions.set)" -ForegroundColor White
        Write-Host " [4] Create SSO user (govc sso.user.create)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'VMware.User.Create' -Action { VMware-ESXi-User-Create } }
            '2' { Invoke-Tool -Name 'VMware.Role.Create' -Action { VMware-VC-Role-Create } }
            '3' { Invoke-Tool -Name 'VMware.Permissions.Assign' -Action { VMware-VC-Permissions-Assign } }
            '4' { Invoke-Tool -Name 'VMware.SSO.User.Create' -Action { VMware-SSO-User-Create } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-VMwareMonitoringMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "VMware :: Monitoring & Reporting"
        Write-Host " [1] Inventory report (govc find/list)" -ForegroundColor White
        Write-Host " [2] Performance metrics sample (govc metric.sample)" -ForegroundColor White
        Write-Host " [3] Host profile compliance check (govc)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'VMware.Report.Inventory' -Action { VMware-Report-Inventory } }
            '2' { Invoke-Tool -Name 'VMware.Metrics.Sample' -Action { VMware-Metrics-Sample } }
            '3' { Invoke-Tool -Name 'VMware.Compliance.Check' -Action { VMware-Compliance-Check } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# --- Implementation Functions ---
function VMware-VM-Power {
    Show-Header -Title "VMware :: VM Power Operations"
    $info = Get-VMwareConnectionInfo
    $vmid = Read-Host "VMID"
    $op = Read-Host "Operation: start/stop/reset/suspend"
    $op = $op.ToLowerInvariant()
    $cmd = switch ($op) {
        'start'   { "vim-cmd vmsvc/power.on $vmid" }
        'stop'    { "vim-cmd vmsvc/power.off $vmid" }
        'reset'   { "vim-cmd vmsvc/power.reset $vmid" }
        'suspend' { "vim-cmd vmsvc/power.suspend $vmid" }
        default   { Write-Host "Unknown op." -ForegroundColor Red; return }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-VM-Delete {
    Show-Header -Title "VMware :: Delete VM"
    $info = Get-VMwareConnectionInfo
    $vmid = Read-Host "VMID"
    $cmd = "vim-cmd vmsvc/destroy $vmid"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-VM-Snapshot {
    Show-Header -Title "VMware :: VM Snapshots"
    $info = Get-VMwareConnectionInfo
    $vmid = Read-Host "VMID"
    $op = Read-Host "Operation: create/revert/remove"
    $name = Read-Host "Snapshot name"
    $cmd = switch ($op.ToLowerInvariant()) {
        'create' { "vim-cmd vmsvc/snapshot.create $vmid $name 0 0" }
        'revert' { "vim-cmd vmsvc/snapshot.revert $vmid -n $name" }
        'remove' { "vim-cmd vmsvc/snapshot.remove $vmid" }
        default  { Write-Host "Unknown op." -ForegroundColor Red; return }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-VM-Migrate {
    Show-Header -Title "VMware :: VM Migrate (govc)"
    $info = Get-VMwareConnectionInfo
    $vmName = Read-Host "VM name"
    $mode = Read-Host "Mode: host|datastore"
    $target = if ($mode -eq 'host') { Read-Host "Target host" } else { Read-Host "Target datastore" }
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot perform vMotion." -ForegroundColor Yellow; Pause-Return; return }
    $cmd = if ($mode -eq 'host') { "$govc vm.migrate -host $target $vmName" } else { "$govc vm.migrate -ds $target $vmName" }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-VM-CreateDummy {
    Show-Header -Title "VMware :: Create Dummy VM"
    $info = Get-VMwareConnectionInfo
    $name = Read-Host "VM name"
    $dsPath = Read-Host "Datastore path (e.g., /vmfs/volumes/datastore1/vms/vm1)"
    $cmd = "vim-cmd vmsvc/createdummyvm $name $dsPath"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-VM-CloneLocal {
    Show-Header -Title "VMware :: Clone VM Locally (copy+register)"
    $info = Get-VMwareConnectionInfo
    $srcPath = Read-Host "Source VM folder path"
    $dstPath = Read-Host "Destination VM folder path"
    $vmx = Read-Host "Destination VMX full path"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand ("cp -r `"$srcPath`" `"$dstPath`"") | Out-Null
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand ("vim-cmd solo/registervm `"$vmx`"") | Out-Null
    Pause-Return
}

function VMware-VM-DeployTemplate {
    Show-Header -Title "VMware :: Deploy VM from Template (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot deploy from template." -ForegroundColor Yellow; Pause-Return; return }
    $template = Read-Host "Template VM name"
    $name = Read-Host "New VM name"
    $folder = Read-Host "Folder (optional)"
    $pool = Read-Host "Resource Pool (optional)"
    $cmd = "$govc vm.clone -vm $template -on=false $name"
    if ($folder) { $cmd += " -folder `"$folder`"" }
    if ($pool) { $cmd += " -pool `"$pool`"" }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-VM-ExpandDisk {
    Show-Header -Title "VMware :: Expand VM Disk"
    $info = Get-VMwareConnectionInfo
    $vmdk = Read-Host "VMDK path (e.g., /vmfs/volumes/datastore1/vms/vm1/vm1.vmdk)"
    $size = Read-Host "New size (e.g., 40G)"
    $cmd = "vmkfstools -X $size $vmdk"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-Upload-ISO {
    Show-Header -Title "VMware :: Upload ISO"
    $info = Get-VMwareConnectionInfo
    $local = Read-Host "Local ISO path"
    $name  = Split-Path -Leaf $local
    $ds    = Read-Host "Datastore name"
    $folder = Read-Host "Folder under datastore (default iso)"
    if ([string]::IsNullOrWhiteSpace($folder)) { $folder = 'iso' }
    $dest  = "/vmfs/volumes/$ds/$folder"
    $cmd = "scp `"$local`" $($info.User)@$($info.LabHost):`"$dest/$name`""
    Write-Host "Running: $cmd" -ForegroundColor Yellow
    Invoke-Expression $cmd | Out-Null
    Pause-Return
}

function VMware-Datastore-Create {
    Show-Header -Title "VMware :: Create VMFS Datastore"
    $info = Get-VMwareConnectionInfo
    $label = Read-Host "Datastore label"
    $device = Read-Host "Device (e.g., naa.*)"
    $cmd = "esxcli storage vmfs create -l $label -S $device"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-StoragePolicy-Apply {
    Show-Header -Title "VMware :: Apply Storage Policy (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot apply storage policy." -ForegroundColor Yellow; Pause-Return; return }
    $vm = Read-Host "VM name"
    $policy = Read-Host "Policy name"
    $cmd = "$govc vm.storage.policy.apply -vm $vm -policy `"$policy`""
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-Host-AddToVC {
    Show-Header -Title "VMware :: Add Host to vCenter (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot add host." -ForegroundColor Yellow; Pause-Return; return }
    $esxiHost = Read-Host "ESXi host FQDN/IP"
    $cmd = "$govc host.add -hostname $esxiHost"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-Host-RemoveFromVC {
    Show-Header -Title "VMware :: Remove Host from vCenter (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot remove host." -ForegroundColor Yellow; Pause-Return; return }
    $esxiHost = Read-Host "ESXi host FQDN/IP"
    $cmd = "$govc host.remove -hostname $esxiHost"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-Network-Configure {
    Show-Header -Title "VMware :: Configure Networking (esxcli)"
    $info = Get-VMwareConnectionInfo
    $vSwitch = Read-Host "vSwitch name"
    $pg = Read-Host "Portgroup name"
    $vlan = Read-Host "VLAN ID"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand ("esxcli network vswitch standard add -v $vSwitch") | Out-Null
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand ("esxcli network vswitch standard portgroup add -v $vSwitch -p $pg") | Out-Null
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand ("esxcli network vswitch standard portgroup set -p $pg -v $vlan") | Out-Null
    Pause-Return
}

function VMware-Storage-Adapter-Rescan {
    Show-Header -Title "VMware :: Rescan Storage Adapter"
    $info = Get-VMwareConnectionInfo
    $adapter = Read-Host "Adapter (e.g., vmhba0)"
    $cmd = "esxcli storage core adapter rescan -A $adapter"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-Cluster-Settings {
    Show-Header -Title "VMware :: Cluster Settings (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot change cluster settings." -ForegroundColor Yellow; Pause-Return; return }
    $cluster = Read-Host "Cluster name"
    $drs = Read-Host "Enable DRS? (y/N)"
    $ha = Read-Host "Enable HA? (y/N)"
    $cmd = "$govc cluster.change -cluster `"$cluster`""
    if ($drs.ToLowerInvariant() -eq 'y') { $cmd += " -drs-enabled" } else { $cmd += " -drs-disabled" }
    if ($ha.ToLowerInvariant() -eq 'y') { $cmd += " -ha-enabled" } else { $cmd += " -ha-disabled" }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-Host-Patch {
    Show-Header -Title "VMware :: Patch/Update Host"
    $info = Get-VMwareConnectionInfo
    $depot = Read-Host "Depot URL"
    $profile = Read-Host "Image profile"
    $cmd = "esxcli software profile update -d $depot -p $profile"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-Host-Maintenance {
    Show-Header -Title "VMware :: Host Maintenance Mode"
    $info = Get-VMwareConnectionInfo
    $op = Read-Host "Operation: enter/exit"
    $cmd = switch ($op.ToLowerInvariant()) {
        'enter' { 'vim-cmd hostsvc/maintenance_mode_enter' }
        'exit'  { 'vim-cmd hostsvc/maintenance_mode_exit' }
        default { Write-Host "Unknown op." -ForegroundColor Red; return }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-ESXi-User-Create {
    Show-Header -Title "VMware :: Create ESXi User"
    $info = Get-VMwareConnectionInfo
    $user = Read-Host "Username"
    $pass = Read-Host "Password"
    $comment = Read-Host "Comment (optional)"
    $cmd = "esxcli system account add -i $user -p $pass"
    if ($comment) { $cmd += " -c `"$comment`"" }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-VC-Role-Create {
    Show-Header -Title "VMware :: Create vCenter Role (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot create role." -ForegroundColor Yellow; Pause-Return; return }
    $role = Read-Host "Role name"
    $privs = Read-Host "Privileges (comma-separated)"
    $cmd = "$govc role.create -privileges `"$privs`" `"$role`""
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-VC-Permissions-Assign {
    Show-Header -Title "VMware :: Assign Permissions (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot assign permissions." -ForegroundColor Yellow; Pause-Return; return }
    $path = Read-Host "Object path (e.g., /datacenter/vm/folder/vmname)"
    $entity = Read-Host "User or group"
    $role = Read-Host "Role"
    $cmd = "$govc permissions.set -principal `"$entity`" -role `"$role`" `"$path`""
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-SSO-User-Create {
    Show-Header -Title "VMware :: Create SSO User (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot create SSO user." -ForegroundColor Yellow; Pause-Return; return }
    $user = Read-Host "Username"
    $domain = Read-Host "Domain (e.g., vsphere.local)"
    $pass = Read-Host "Password"
    $cmd = "$govc sso.user.create -d `"$domain`" -p `"$pass`" `"$user`""
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function VMware-Report-Inventory {
    Show-Header -Title "VMware :: Inventory Report (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; inventory limited." -ForegroundColor Yellow; $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "vim-cmd vmsvc/getallvms"; Write-Host $out; Pause-Return; return }
    $cmd = "$govc find -type m -type h -type d"
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

function VMware-Metrics-Sample {
    Show-Header -Title "VMware :: Metrics Sample (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot sample metrics." -ForegroundColor Yellow; Pause-Return; return }
    $vm = Read-Host "VM name"
    $cmd = "$govc metric.sample -n 1 -i 5 `"$vm`""
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

function VMware-Compliance-Check {
    Show-Header -Title "VMware :: Host Profile Compliance (govc)"
    $info = Get-VMwareConnectionInfo
    $cfg = Get-VMwareDefaults
    $govc = $cfg.GovcPath
    if (-not $govc) { Write-Host "GovcPath not configured in VmwareDefaults; cannot check compliance." -ForegroundColor Yellow; Pause-Return; return }
    $esxiHost = Read-Host "ESXi host name"
    $cmd = "$govc host.profile.check -host `"$esxiHost`""
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}
