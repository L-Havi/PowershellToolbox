# Proxmox Tools

function Get-ProxmoxConnectionInfo {
    $cfg = Get-ProxmoxDefaults
    Write-Host "Enter Proxmox SSH connection details (leave empty to use ProxmoxDefaults from config.yaml):" -ForegroundColor Cyan
    Write-Host "(If no config file exists, empty = blank defaults.)" -ForegroundColor DarkGray
    Write-Host ""
    $hostPrompt = if ($cfg.Host) { "Proxmox host or IP (default: $($cfg.Host))" } else { "Proxmox host or IP (no default)" }
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

function Test-ProxmoxSSHConnection {
    Show-Header -Title "Proxmox Tools :: Test SSH Connection to Node"
    $info = Get-ProxmoxConnectionInfo
    Write-Host ""; Write-Host "Testing connectivity to $($info.User)@$($info.LabHost) using '$($info.SshMethod)'..." -ForegroundColor Cyan
    Write-Host "(You may be prompted for password or key passphrase.)" -ForegroundColor DarkGray
    try {
        $output = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "hostname"
        if ($LASTEXITCODE -eq 0 -and $output) { Write-Host ""; Write-Host "SSH connection successful. Remote hostname: $output" -ForegroundColor Green }
        else { Write-Host ""; Write-Host "SSH command exited with code $LASTEXITCODE or empty output. Check credentials/firewall." -ForegroundColor Red }
    } catch { Write-Host "Error running SSH/plink: $_" -ForegroundColor Red }
    Pause-Return
}

function Get-ProxmoxVMList {
    Show-Header -Title "Proxmox Tools :: List VMs (qm list)"
    $info = Get-ProxmoxConnectionInfo
    Write-Host ""; Write-Host "Querying VM list from $($info.User)@$($info.LabHost) using '$($info.SshMethod)'..." -ForegroundColor Cyan
    try { $output = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "qm list"; Write-Host ""; Write-Host "Raw output from 'qm list':" -ForegroundColor Cyan; Write-Host $output }
    catch { Write-Host "Error retrieving VM list: $_" -ForegroundColor Red }
    Pause-Return
}

function Get-ProxmoxStorageUsage {
    Show-Header -Title "Proxmox Tools :: Storage Usage on Node"
    $info = Get-ProxmoxConnectionInfo
    Write-Host ""; Write-Host "Querying storage status from $($info.User)@$($info.LabHost) using '$($info.SshMethod)'..." -ForegroundColor Cyan
    try {
        Write-Host ""; Write-Host "== pvesm status ==" -ForegroundColor Yellow
        $out1 = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "pvesm status"
        Write-Host $out1
        Write-Host ""; Write-Host "== df -h (top level) ==" -ForegroundColor Yellow
        $out2 = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "df -h --output=source,size,used,avail,target | head -n 15"
        Write-Host $out2
    } catch { Write-Host "Error retrieving storage usage: $_" -ForegroundColor Red }
    Pause-Return
}

function Show-ProxmoxToolsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Proxmox Tools"
        Write-Host " [1] Connection & Basics" -ForegroundColor White
        Write-Host " [2] VM & Container Management" -ForegroundColor White
        Write-Host " [3] Storage & Backup Automation" -ForegroundColor White
        Write-Host " [4] Cluster & Node Operations" -ForegroundColor White
        Write-Host " [5] User & Permission Management" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back to Hypervisor Tools menu" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Show-ProxmoxBasicsMenu }
            '2' { Show-ProxmoxVMCTMenu }
            '3' { Show-ProxmoxStorageBackupMenu }
            '4' { Show-ProxmoxClusterNodeMenu }
            '5' { Show-ProxmoxUserPermMenu }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-ProxmoxBasicsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Proxmox :: Connection & Basics"
        Write-Host " [1] Test SSH connection to node" -ForegroundColor White
        Write-Host " [2] List VMs (qm list)" -ForegroundColor White
        Write-Host " [3] Show storage usage (pvesm status + df -h)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Proxmox.TestSSH' -Action { Test-ProxmoxSSHConnection } }
            '2' { Invoke-Tool -Name 'Proxmox.ListVMs' -Action { Get-ProxmoxVMList } }
            '3' { Invoke-Tool -Name 'Proxmox.StorageUsage' -Action { Get-ProxmoxStorageUsage } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# --- VM & Container Management ---
function Show-ProxmoxVMCTMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Proxmox :: VM & Container Management"
        Write-Host " [1] Start/Stop/Restart/Delete VM" -ForegroundColor White
        Write-Host " [2] Start/Stop/Shutdown/Delete CT (LXC)" -ForegroundColor White
        Write-Host " [3] Clone VM (full or linked)" -ForegroundColor White
        Write-Host " [4] Modify VM hardware (CPU/RAM/disk/NIC)" -ForegroundColor White
        Write-Host " [5] Create snapshot / Restore snapshot (VM)" -ForegroundColor White
        Write-Host " [6] Migrate VM between nodes" -ForegroundColor White
        Write-Host " [7] Query VM status / config" -ForegroundColor White
        Write-Host " [8] Create VM" -ForegroundColor White
        Write-Host " [9] Create CT (LXC)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Proxmox.VM.Power' -Action { Proxmox-VM-Power } }
            '2' { Invoke-Tool -Name 'Proxmox.CT.Power' -Action { Proxmox-CT-Power } }
            '3' { Invoke-Tool -Name 'Proxmox.VM.Clone' -Action { Proxmox-VM-Clone } }
            '4' { Invoke-Tool -Name 'Proxmox.VM.Hardware' -Action { Proxmox-VM-SetHardware } }
            '5' { Invoke-Tool -Name 'Proxmox.VM.Snapshot' -Action { Proxmox-VM-Snapshot } }
            '6' { Invoke-Tool -Name 'Proxmox.VM.Migrate' -Action { Proxmox-VM-Migrate } }
            '7' { Invoke-Tool -Name 'Proxmox.VM.Query' -Action { Proxmox-VM-Query } }
            '8' { Invoke-Tool -Name 'Proxmox.VM.Create' -Action { Proxmox-VM-Create } }
            '9' { Invoke-Tool -Name 'Proxmox.CT.Create' -Action { Proxmox-CT-Create } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Proxmox-VM-Power {
    Show-Header -Title "Proxmox :: VM Power Operations"
    $info = Get-ProxmoxConnectionInfo
    $vmid = Read-Host "VMID"
    $op = Read-Host "Operation: start/stop/restart/delete"
    $op = $op.ToLowerInvariant()
    $cmd = switch ($op) {
        'start'   { "qm start $vmid" }
        'stop'    { "qm stop $vmid" }
        'restart' { "qm reboot $vmid" }
        'delete'  { "qm destroy $vmid" }
        default   { Write-Host "Unknown op." -ForegroundColor Red; return }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-VM-Create {
    Show-Header -Title "Proxmox :: Create VM"
    $info = Get-ProxmoxConnectionInfo
    $vmid   = Read-Host "New VMID"
    $name   = Read-Host "VM name"
    $cores  = Read-Host "CPU cores (optional)"
    $memMB  = Read-Host "Memory (MB, optional)"
    $iso    = Read-Host "ISO storage path (e.g., local:iso/debian.iso) [optional]"
    $net    = Read-Host "Network spec (e.g., virtio,bridge=vmbr0) [optional]"
    if ([string]::IsNullOrWhiteSpace($vmid) -or [string]::IsNullOrWhiteSpace($name)) { Write-Host "VMID and name are required." -ForegroundColor Red; Pause-Return; return }
    $args = @("--name $name")
    if ($cores) { $args += "--cores $cores" }
    if ($memMB) { $args += "--memory $memMB" }
    if ($iso) { $args += "--ide2 $iso,media=cdrom" }
    if ($net) { $args += "--net0 $net" }
    $cmd = "qm create $vmid $($args -join ' ')"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-CT-Power {
    Show-Header -Title "Proxmox :: Container (LXC) Power Operations"
    $info = Get-ProxmoxConnectionInfo
    $ctid = Read-Host "CTID"
    $op = Read-Host "Operation: start/stop/shutdown/delete"
    $op = $op.ToLowerInvariant()
    $cmd = switch ($op) {
        'start'   { "pct start $ctid" }
        'stop'    { "pct stop $ctid" }
        'shutdown'{ "pct shutdown $ctid" }
        'delete'  { "pct destroy $ctid" }
        default   { Write-Host "Unknown op." -ForegroundColor Red; return }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-CT-Create {
    Show-Header -Title "Proxmox :: Create Container (LXC)"
    $info = Get-ProxmoxConnectionInfo
    $ctid      = Read-Host "New CTID"
    $ostmpl    = Read-Host "OS template (e.g., local:vztmpl/debian.tar.zst)"
    $hostname  = Read-Host "Hostname"
    $cores     = Read-Host "CPU cores (optional)"
    $memMB     = Read-Host "Memory (MB, optional)"
    $rootfs    = Read-Host "Rootfs (e.g., local-lvm:8) [optional]"
    if ([string]::IsNullOrWhiteSpace($ctid) -or [string]::IsNullOrWhiteSpace($ostmpl) -or [string]::IsNullOrWhiteSpace($hostname)) { Write-Host "CTID, template, and hostname are required." -ForegroundColor Red; Pause-Return; return }
    $args = @("-hostname $hostname")
    if ($cores) { $args += "-cores $cores" }
    if ($memMB) { $args += "-memory $memMB" }
    if ($rootfs) { $args += "-rootfs $rootfs" }
    $cmd = "pct create $ctid $ostmpl $($args -join ' ')"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}
function Proxmox-VM-Clone {
    Show-Header -Title "Proxmox :: Clone VM"
    $info = Get-ProxmoxConnectionInfo
    $src = Read-Host "Source VMID"
    $dst = Read-Host "New VMID"
    $linked = Read-Host "Linked clone? (y/N)"
    $fullFlag = if ($linked.ToLowerInvariant() -eq 'y') { '--full 0' } else { '--full 1' }
    $cmd = "qm clone $src $dst $fullFlag"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-VM-SetHardware {
    Show-Header -Title "Proxmox :: Set VM Hardware"
    $info = Get-ProxmoxConnectionInfo
    $vmid = Read-Host "VMID"
    $cores = Read-Host "CPU cores (optional)"
    $memMB = Read-Host "Memory (MB, optional)"
    $diskArg = Read-Host "Disk resize spec (e.g., scsi0 +10G, optional)"
    $nicModel = Read-Host "NIC model (e.g., virtio, optional)"
    $args = @()
    if ($cores) { $args += "--cores $cores" }
    if ($memMB) { $args += "--memory $memMB" }
    if ($nicModel) { $args += "--net0 $nicModel" }
    $cmd = if ($args.Count -gt 0) { "qm set $vmid ${args}" } else { "echo 'No changes'" }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    if ($diskArg) { Invoke-LabRemoteCommand -Conn $info -RemoteCommand ("qm resize $vmid $diskArg") | Out-Null }
    Pause-Return
}

function Proxmox-VM-Snapshot {
    Show-Header -Title "Proxmox :: VM Snapshots"
    $info = Get-ProxmoxConnectionInfo
    $vmid = Read-Host "VMID"
    $op   = Read-Host "Operation: create/restore"
    $snap = Read-Host "Snapshot name"
    $cmd = switch ($op.ToLowerInvariant()) {
        'create'  { "qm snapshot $vmid $snap" }
        'restore' { "qm rollback $vmid $snap" }
        default   { Write-Host "Unknown op." -ForegroundColor Red; return }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-VM-Migrate {
    Show-Header -Title "Proxmox :: VM Migrate"
    $info = Get-ProxmoxConnectionInfo
    $vmid = Read-Host "VMID"
    $target = Read-Host "Target node name"
    $cmd = "qm migrate $vmid $target"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-VM-Query {
    Show-Header -Title "Proxmox :: VM Query"
    $info = Get-ProxmoxConnectionInfo
    $vmid = Read-Host "VMID"
    $which = Read-Host "Query: status/config"
    $cmd = switch ($which.ToLowerInvariant()) {
        'status' { "qm status $vmid" }
        'config' { "qm config $vmid" }
        default  { Write-Host "Unknown query." -ForegroundColor Red; return }
    }
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

# --- Storage & Backup Automation ---
function Show-ProxmoxStorageBackupMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Proxmox :: Storage & Backup"
        Write-Host " [1] Trigger backup (vzdump)" -ForegroundColor White
        Write-Host " [2] Monitor backup jobs" -ForegroundColor White
        Write-Host " [3] Manage storage pools (list)" -ForegroundColor White
        Write-Host " [4] Upload ISO (path)" -ForegroundColor White
        Write-Host " [5] Resize VM disk (qm resize)" -ForegroundColor White
        Write-Host " [6] Backup jobs (list/create/delete)" -ForegroundColor White
        Write-Host " [7] Add storage (dir/nfs/cifs)" -ForegroundColor White
        Write-Host " [8] Remove storage" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Proxmox.Backup.Trigger' -Action { Proxmox-Backup-Trigger } }
            '2' { Invoke-Tool -Name 'Proxmox.Backup.Monitor' -Action { Proxmox-Backup-Monitor } }
            '3' { Invoke-Tool -Name 'Proxmox.Storage.List' -Action { Proxmox-Storage-List } }
            '4' { Invoke-Tool -Name 'Proxmox.UploadISO' -Action { Proxmox-Upload-ISO } }
            '5' { Invoke-Tool -Name 'Proxmox.Disk.Resize' -Action { Proxmox-VM-ResizeDisk } }
            '6' { Invoke-Tool -Name 'Proxmox.Backup.Jobs' -Action { Show-ProxmoxBackupJobsMenu } }
            '7' { Invoke-Tool -Name 'Proxmox.Storage.Add' -Action { Proxmox-Storage-Add } }
            '8' { Invoke-Tool -Name 'Proxmox.Storage.Remove' -Action { Proxmox-Storage-Remove } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Proxmox-Backup-Trigger {
    Show-Header -Title "Proxmox :: Trigger Backup (vzdump)"
    $info = Get-ProxmoxConnectionInfo
    $ids  = Read-Host "VMIDs/CTIDs (comma-separated)"
    $store = Read-Host "Storage target (e.g., local, nfs)"
    $mode = Read-Host "Mode: snapshot/stop (default snapshot)"
    if ([string]::IsNullOrWhiteSpace($mode)) { $mode = 'snapshot' }
    $cmd = "vzdump --mode $mode --storage $store --node `"$(hostname)`" --compress zstd --mailto root@localhost --quiet 1 --all 0 --vmid $ids"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-Backup-Monitor {
    Show-Header -Title "Proxmox :: Monitor Backups"
    $info = Get-ProxmoxConnectionInfo
    $cmd = "journalctl -u vzdump --since '1 day ago' --no-pager | tail -n 100"
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

function Proxmox-Storage-List {
    Show-Header -Title "Proxmox :: Storage Pools (list)"
    $info = Get-ProxmoxConnectionInfo
    $cmd = "pvesm status"
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

function Proxmox-Upload-ISO {
    Show-Header -Title "Proxmox :: Upload ISO"
    $info = Get-ProxmoxConnectionInfo
    $local = Read-Host "Local ISO path"
    $name  = Split-Path -Leaf $local
    $dest  = Read-Host "Remote iso folder (default /var/lib/vz/template/iso)"
    if ([string]::IsNullOrWhiteSpace($dest)) { $dest = '/var/lib/vz/template/iso' }
    $cmd = "scp `"$local`" $($info.User)@$($info.LabHost):`"$dest/$name`""
    Write-Host "Running: $cmd" -ForegroundColor Yellow
    Invoke-Expression $cmd | Out-Null
    Pause-Return
}

function Proxmox-VM-ResizeDisk {
    Show-Header -Title "Proxmox :: Resize VM Disk"
    $info = Get-ProxmoxConnectionInfo
    $vmid = Read-Host "VMID"
    $diskSpec = Read-Host "Disk spec & size change (e.g., scsi0 +10G)"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand ("qm resize $vmid $diskSpec") | Out-Null
    Pause-Return
}

function Show-ProxmoxBackupJobsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Proxmox :: Backup Jobs"
        Write-Host " [1] List backup jobs" -ForegroundColor White
        Write-Host " [2] Create backup job" -ForegroundColor White
        Write-Host " [3] Delete backup job" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Proxmox.Backup.Job.List' -Action { Proxmox-Backup-Job-List } }
            '2' { Invoke-Tool -Name 'Proxmox.Backup.Job.Create' -Action { Proxmox-Backup-Job-Create } }
            '3' { Invoke-Tool -Name 'Proxmox.Backup.Job.Delete' -Action { Proxmox-Backup-Job-Delete } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Proxmox-Backup-Job-List {
    Show-Header -Title "Proxmox :: List Backup Jobs"
    $info = Get-ProxmoxConnectionInfo
    $cmd = "pvesh get /cluster/backup"
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

function Proxmox-Backup-Job-Create {
    Show-Header -Title "Proxmox :: Create Backup Job"
    $info = Get-ProxmoxConnectionInfo
    $jobId = Read-Host "Job ID"
    $start = Read-Host "Start time (HH:MM)"
    $dow = Read-Host "Days of week (e.g., mon,tue,wed; optional)"
    $storage = Read-Host "Target storage (e.g., local, nfs)"
    $mode = Read-Host "Mode: snapshot/stop (default snapshot)"
    if ([string]::IsNullOrWhiteSpace($mode)) { $mode = 'snapshot' }
    $vmids = Read-Host "VMIDs/CTIDs (comma-separated)"
    $nodeIn = Read-Host "Node (blank = current node)"
    $nodeExpr = if ([string]::IsNullOrWhiteSpace($nodeIn)) { '$(hostname)' } else { $nodeIn }
    if ([string]::IsNullOrWhiteSpace($jobId) -or [string]::IsNullOrWhiteSpace($start) -or [string]::IsNullOrWhiteSpace($storage) -or [string]::IsNullOrWhiteSpace($vmids)) {
        Write-Host "Job ID, start time, storage, and VMIDs are required." -ForegroundColor Red
        Pause-Return; return
    }
    $args = @("--id $jobId","--starttime $start","--storage $storage","--mode $mode","--compress zstd","--enabled 1","--node $nodeExpr","--vmid $vmids")
    if ($dow) { $args += "--dow $dow" }
    $cmd = "pvesh create /cluster/backup $($args -join ' ')"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-Backup-Job-Delete {
    Show-Header -Title "Proxmox :: Delete Backup Job"
    $info = Get-ProxmoxConnectionInfo
    $jobId = Read-Host "Job ID"
    if ([string]::IsNullOrWhiteSpace($jobId)) { Write-Host "Job ID required." -ForegroundColor Red; Pause-Return; return }
    $cmd = "pvesh delete /cluster/backup/$jobId"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-Storage-Add {
    Show-Header -Title "Proxmox :: Add Storage"
    $info = Get-ProxmoxConnectionInfo
    $type = Read-Host "Type: dir/nfs/cifs"
    $storeId = Read-Host "Storage ID (name)"
    if ($type.ToLowerInvariant() -notin @('dir','nfs','cifs')) { Write-Host "Unknown type." -ForegroundColor Red; Pause-Return; return }
    if ([string]::IsNullOrWhiteSpace($storeId)) { Write-Host "Storage ID required." -ForegroundColor Red; Pause-Return; return }
    switch ($type.ToLowerInvariant()) {
        'dir' {
            $path = Read-Host "Path (e.g., /mnt/storage)"
            $content = Read-Host "Content types (e.g., iso,backup,vztmpl; optional)"
            $cmd = "pvesm add dir $storeId --path $path"
            if ($content) { $cmd += " --content $content" }
        }
        'nfs' {
            $server = Read-Host "NFS server"
            $export = Read-Host "NFS export (e.g., /srv/nfs)"
            $options = Read-Host "Mount options (optional)"
            $cmd = "pvesm add nfs $storeId --server $server --export $export"
            if ($options) { $cmd += " --options $options" }
        }
        'cifs' {
            $server = Read-Host "SMB server"
            $share = Read-Host "Share name"
            $username = Read-Host "Username (optional)"
            $password = Read-Host "Password (optional)"
            $cmd = "pvesm add cifs $storeId --server $server --share $share"
            if ($username) { $cmd += " --username $username" }
            if ($password) { $cmd += " --password $password" }
        }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-Storage-Remove {
    Show-Header -Title "Proxmox :: Remove Storage"
    $info = Get-ProxmoxConnectionInfo
    $storeId = Read-Host "Storage ID"
    if ([string]::IsNullOrWhiteSpace($storeId)) { Write-Host "Storage ID required." -ForegroundColor Red; Pause-Return; return }
    $cmd = "pvesm remove $storeId"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

# --- Cluster & Node Operations ---
function Show-ProxmoxClusterNodeMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Proxmox :: Cluster & Node Operations"
        Write-Host " [1] Cluster health & quorum (pvecm status)" -ForegroundColor White
        Write-Host " [2] Manage nodes (add/remove)" -ForegroundColor White
        Write-Host " [3] Ceph cluster status" -ForegroundColor White
        Write-Host " [4] Monitor node CPU/RAM/disk" -ForegroundColor White
        Write-Host " [5] Reboot or shutdown node" -ForegroundColor White
        Write-Host " [6] HA groups & policies status" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Proxmox.Cluster.Status' -Action { Proxmox-Cluster-Status } }
            '2' { Invoke-Tool -Name 'Proxmox.Cluster.Nodes' -Action { Proxmox-Cluster-Nodes } }
            '3' { Invoke-Tool -Name 'Proxmox.Ceph.Status' -Action { Proxmox-Ceph-Status } }
            '4' { Invoke-Tool -Name 'Proxmox.Node.Monitor' -Action { Proxmox-Node-Monitor } }
            '5' { Invoke-Tool -Name 'Proxmox.Node.Power' -Action { Proxmox-Node-Power } }
            '6' { Invoke-Tool -Name 'Proxmox.HA.Status' -Action { Proxmox-HA-Status } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Proxmox-Cluster-Status {
    Show-Header -Title "Proxmox :: Cluster Status"
    $info = Get-ProxmoxConnectionInfo
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand "pvecm status"
    Write-Host $out
    Pause-Return
}

function Proxmox-Cluster-Nodes {
    Show-Header -Title "Proxmox :: Manage Nodes"
    $info = Get-ProxmoxConnectionInfo
    $op = Read-Host "Operation: add/remove"
    $peer = Read-Host "Peer hostname/IP"
    $cmd = switch ($op.ToLowerInvariant()) {
        'add'    { "pvecm add $peer" }
        'remove' { "pvecm delnode $peer" }
        default  { Write-Host "Unknown op." -ForegroundColor Red; return }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-Ceph-Status {
    Show-Header -Title "Proxmox :: Ceph Status"
    $info = Get-ProxmoxConnectionInfo
    $cmd = "ceph -s"
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

function Proxmox-Node-Monitor {
    Show-Header -Title "Proxmox :: Node Monitor"
    $info = Get-ProxmoxConnectionInfo
    $cmd = "echo CPU:`$(grep -c ^processor /proc/cpuinfo); free -m; df -h --output=source,size,used,avail,target | head -n 15"
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

function Proxmox-Node-Power {
    Show-Header -Title "Proxmox :: Node Power"
    $info = Get-ProxmoxConnectionInfo
    $op = Read-Host "Operation: reboot/shutdown"
    $cmd = switch ($op.ToLowerInvariant()) {
        'reboot'   { 'reboot' }
        'shutdown' { 'shutdown -h now' }
        default    { Write-Host "Unknown op." -ForegroundColor Red; return }
    }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-HA-Status {
    Show-Header -Title "Proxmox :: HA Groups & Policies"
    $info = Get-ProxmoxConnectionInfo
    $cmd = "ha-manager status"
    $out = Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd
    Write-Host $out
    Pause-Return
}

# --- User & Permission Management ---
function Show-ProxmoxUserPermMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "Proxmox :: User & Permission Management"
        Write-Host " [1] Create/Modify user" -ForegroundColor White
        Write-Host " [2] Create role" -ForegroundColor White
        Write-Host " [3] Assign permissions (ACL)" -ForegroundColor White
        Write-Host " [4] Delete user" -ForegroundColor White
        Write-Host " [5] Create user API token" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'Proxmox.User.Modify' -Action { Proxmox-User-Modify } }
            '2' { Invoke-Tool -Name 'Proxmox.Role.Create' -Action { Proxmox-Role-Create } }
            '3' { Invoke-Tool -Name 'Proxmox.Permissions.Assign' -Action { Proxmox-Acl-Assign } }
            '4' { Invoke-Tool -Name 'Proxmox.User.Delete' -Action { Proxmox-User-Delete } }
            '5' { Invoke-Tool -Name 'Proxmox.User.Token.Create' -Action { Proxmox-Token-Create } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Proxmox-User-Modify {
    Show-Header -Title "Proxmox :: Create/Modify User"
    $info = Get-ProxmoxConnectionInfo
    $user = Read-Host "User (e.g., user@pve)"
    $email = Read-Host "Email (optional)"
    $passSet = Read-Host "Set password? (y/N)"
    $cmd = "pveum user add $user"
    if ($email) { $cmd += " --email $email" }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    if ($passSet.ToLowerInvariant() -eq 'y') {
        $cmd2 = "pveum passwd $user"
        Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd2 | Out-Null
    }
    Pause-Return
}

function Proxmox-Role-Create {
    Show-Header -Title "Proxmox :: Create Role"
    $info = Get-ProxmoxConnectionInfo
    $role = Read-Host "Role name"
    $privs = Read-Host "Privileges (comma-separated, e.g., VM.Console,VM.Config.Disk)"
    $cmd = "pveum role add $role -privs `"$privs`""
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-Acl-Assign {
    Show-Header -Title "Proxmox :: Assign Permissions (ACL)"
    $info = Get-ProxmoxConnectionInfo
    $path = Read-Host "Path (e.g., /vms/100 or /)"
    $entity = Read-Host "User or group (e.g., user@pve)"
    $role = Read-Host "Role (e.g., PVEVMUser)"
    $propagate = Read-Host "Propagate? (y/N)"
    $propFlag = if ($propagate.ToLowerInvariant() -eq 'y') { '-propagate 1' } else { '-propagate 0' }
    $cmd = "pveum aclmod $path -user $entity -role $role $propFlag"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-User-Delete {
    Show-Header -Title "Proxmox :: Delete User"
    $info = Get-ProxmoxConnectionInfo
    $user = Read-Host "User (e.g., user@pve)"
    if ([string]::IsNullOrWhiteSpace($user)) { Write-Host "User required." -ForegroundColor Red; Pause-Return; return }
    $cmd = "pveum user delete $user"
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}

function Proxmox-Token-Create {
    Show-Header -Title "Proxmox :: Create User API Token"
    $info = Get-ProxmoxConnectionInfo
    $user = Read-Host "User (e.g., user@pve)"
    $tokenId = Read-Host "Token ID (name)"
    $comment = Read-Host "Comment (optional)"
    if ([string]::IsNullOrWhiteSpace($user) -or [string]::IsNullOrWhiteSpace($tokenId)) { Write-Host "User and token ID required." -ForegroundColor Red; Pause-Return; return }
    $cmd = "pveum usertoken add $user $tokenId --privsep 1"
    if ($comment) { $cmd += " --comment `"$comment`"" }
    Invoke-LabRemoteCommand -Conn $info -RemoteCommand $cmd | Out-Null
    Pause-Return
}
