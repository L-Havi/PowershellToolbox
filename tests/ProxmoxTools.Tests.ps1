# Pester tests for ProxmoxTools.ps1
$ErrorActionPreference = 'Stop'

Describe 'ProxmoxTools' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $pxPath = Join-Path $root 'modules\ProxmoxTools.ps1'
        . "$commonPath"
        . "$pxPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }

    It 'builds connection info from config defaults when inputs blank' {
        $cfg = [pscustomobject]@{ Host='10.0.0.2'; User='root'; SshMethod='plink'; PlinkPath='C:\tools\plink.exe' }
        Mock -CommandName Get-ProxmoxDefaults -MockWith { $cfg }
        $answers = @('','','','')
        Mock -CommandName Read-Host -MockWith { $script:ans.Dequeue() } | Out-Null
        $script:ans = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ans.Enqueue($_) }
        $info = Get-ProxmoxConnectionInfo
        $info.LabHost | Should -Be '10.0.0.2'
        $info.User | Should -Be 'root'
        $info.SshMethod | Should -Be 'plink'
        $info.PlinkPath | Should -Be 'C:\tools\plink.exe'
    }

    It 'tests SSH connection and invokes hostname' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.3'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'pve-node' }
        $global:LASTEXITCODE = 0
        { Test-ProxmoxSSHConnection } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'hostname' }
    }

    It 'queries VM list via qm list' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.4'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'vmid name status' }
        { Get-ProxmoxVMList } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'qm list' }
    }

    It 'shows storage usage calling pvesm status and df -h' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.5'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'ok' }
        { Get-ProxmoxStorageUsage } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pvesm status' }
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'df -h*' }
    }

    It 'starts a VM via qm start' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.6'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('100','start')
        Mock -CommandName Read-Host -MockWith { $script:ansVM.Dequeue() } | Out-Null
        $script:ansVM = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansVM.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-VM-Power } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'qm start 100' }
    }

    It 'clones a VM via qm clone with full flag' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.7'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('100','200','n')
        Mock -CommandName Read-Host -MockWith { $script:ansClone.Dequeue() } | Out-Null
        $script:ansClone = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansClone.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-VM-Clone } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'qm clone 100 200 --full 1' }
    }

    It 'sets VM hardware via qm set and resize' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.8'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('101','4','8192','scsi0 +10G','virtio')
        Mock -CommandName Read-Host -MockWith { $script:ansHW.Dequeue() } | Out-Null
        $script:ansHW = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansHW.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-VM-SetHardware } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'qm set 101*--cores 4*--memory 8192*--net0 virtio*' }
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'qm resize 101 scsi0 +10G' }
    }

    It 'creates a snapshot via qm snapshot' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.9'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('102','create','snap1')
        Mock -CommandName Read-Host -MockWith { $script:ansSnap.Dequeue() } | Out-Null
        $script:ansSnap = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSnap.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-VM-Snapshot } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'qm snapshot 102 snap1' }
    }

    It 'migrates a VM via qm migrate' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.10'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('103','node2')
        Mock -CommandName Read-Host -MockWith { $script:ansMig.Dequeue() } | Out-Null
        $script:ansMig = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMig.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-VM-Migrate } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'qm migrate 103 node2' }
    }

    It 'triggers vzdump backup' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.11'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('100,101','local','snapshot')
        Mock -CommandName Read-Host -MockWith { $script:ansBkp.Dequeue() } | Out-Null
        $script:ansBkp = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansBkp.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Backup-Trigger } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'vzdump*--vmid 100,101' }
    }

    It 'shows cluster status via pvecm status' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.12'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'quorum OK' }
        { Proxmox-Cluster-Status } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pvecm status' }
    }

    It 'assigns an ACL via pveum aclmod' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.13'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('/vms/100','user@pve','PVEVMUser','y')
        Mock -CommandName Read-Host -MockWith { $script:ansACL.Dequeue() } | Out-Null
        $script:ansACL = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansACL.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Acl-Assign } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'pveum aclmod /vms/100* -user user@pve* -role PVEVMUser* -propagate 1' }
    }

    It 'controls CT power via pct start/stop/shutdown/destroy' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.14'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('200','start')
        Mock -CommandName Read-Host -MockWith { $script:ansCT.Dequeue() } | Out-Null
        $script:ansCT = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansCT.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-CT-Power } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pct start 200' }
    }

    It 'queries VM status and config via qm' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.15'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('105','status')
        Mock -CommandName Read-Host -MockWith { $script:ansQ.Dequeue() } | Out-Null
        $script:ansQ = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansQ.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'running' }
        { Proxmox-VM-Query } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'qm status 105' }
    }

    It 'monitors backups via journalctl vzdump' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.16'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'logs' }
        { Proxmox-Backup-Monitor } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'journalctl -u vzdump*' }
    }

    It 'creates a VM via qm create with optional args' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.30'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('120','vm120','4','4096','local:iso/debian.iso','virtio,bridge=vmbr0')
        Mock -CommandName Read-Host -MockWith { $script:ansCreateVM.Dequeue() } | Out-Null
        $script:ansCreateVM = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansCreateVM.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-VM-Create } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'qm create 120*--name vm120*--cores 4*--memory 4096*--ide2 local:iso/debian.iso,media=cdrom*--net0 virtio,bridge=vmbr0*' }
    }

    It 'creates a CT via pct create with args' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.31'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('210','local:vztmpl/debian.tar.zst','web210','2','2048','local-lvm:8')
        Mock -CommandName Read-Host -MockWith { $script:ansCreateCT.Dequeue() } | Out-Null
        $script:ansCreateCT = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansCreateCT.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-CT-Create } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pct create 210 local:vztmpl/debian.tar.zst -hostname web210 -cores 2 -memory 2048 -rootfs local-lvm:8' }
    }

    It 'lists storage pools via pvesm status' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.17'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'pools' }
        { Proxmox-Storage-List } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pvesm status' }
    }

    It 'uploads ISO via scp constructed command' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.18'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('C:\isos\debian.iso','')
        Mock -CommandName Read-Host -MockWith { $script:ansISO.Dequeue() } | Out-Null
        $script:ansISO = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansISO.Enqueue($_) }
        Mock -CommandName Invoke-Expression -MockWith {}
        { Proxmox-Upload-ISO } | Should -Not -Throw
        Assert-MockCalled Invoke-Expression -Times 1 -ParameterFilter { $Command -like 'scp*debian.iso*root@10.0.0.18*template/iso*' }
    }

    It 'manages cluster nodes via pvecm add/delnode' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.19'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('add','node2')
        Mock -CommandName Read-Host -MockWith { $script:ansCN.Dequeue() } | Out-Null
        $script:ansCN = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansCN.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Cluster-Nodes } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pvecm add node2' }
    }

    It 'shows Ceph status via ceph -s' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.20'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'HEALTH_OK' }
        { Proxmox-Ceph-Status } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'ceph -s' }
    }

    It 'monitors node via CPU/mem/disk command' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.21'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'ok' }
        { Proxmox-Node-Monitor } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1
    }

    It 'powers node via reboot/shutdown' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.22'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('reboot')
        Mock -CommandName Read-Host -MockWith { $script:ansNP.Dequeue() } | Out-Null
        $script:ansNP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansNP.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Node-Power } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'reboot' }
    }

    It 'shows HA status via ha-manager status' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.23'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'HA ok' }
        { Proxmox-HA-Status } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'ha-manager status' }
    }

    It 'creates/modifies user via pveum user add and optional passwd' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.24'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('user@pve','user@example.com','y')
        Mock -CommandName Read-Host -MockWith { $script:ansUM.Dequeue() } | Out-Null
        $script:ansUM = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansUM.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-User-Modify } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'pveum user add user@pve* --email user@example.com*' }
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pveum passwd user@pve' }
    }

    It 'creates role via pveum role add with privileges' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.25'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('MyRole','VM.Console,VM.Config.Disk')
        Mock -CommandName Read-Host -MockWith { $script:ansRC.Dequeue() } | Out-Null
        $script:ansRC = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRC.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Role-Create } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'pveum role add MyRole* -privs "VM.Console,VM.Config.Disk"' }
    }

    It 'lists backup jobs via pvesh get /cluster/backup' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.26'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { '[{"id":"daily"}]' }
        { Proxmox-Backup-Job-List } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pvesh get /cluster/backup' }
    }

    It 'creates backup job via pvesh create /cluster/backup' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.27'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('daily','01:00','mon,tue,wed,thu,fri','local','snapshot','100,101','')
        Mock -CommandName Read-Host -MockWith { $script:ansBJ.Dequeue() } | Out-Null
        $script:ansBJ = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansBJ.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Backup-Job-Create } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'pvesh create /cluster/backup*--id daily*--starttime 01:00*--storage local*--mode snapshot*--compress zstd*--enabled 1*--node $(hostname)*--vmid 100,101*--dow mon,tue,wed,thu,fri*' }
    }

    It 'deletes backup job via pvesh delete /cluster/backup/<id>' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.28'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('daily')
        Mock -CommandName Read-Host -MockWith { $script:ansBJD.Dequeue() } | Out-Null
        $script:ansBJD = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansBJD.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Backup-Job-Delete } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pvesh delete /cluster/backup/daily' }
    }

    It 'adds dir storage via pvesm add dir' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.29'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('dir','data','/mnt/data','iso,backup','')
        Mock -CommandName Read-Host -MockWith { $script:ansSA.Dequeue() } | Out-Null
        $script:ansSA = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSA.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Storage-Add } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'pvesm add dir data*--path /mnt/data*--content iso,backup*' }
    }

    It 'removes storage via pvesm remove <id>' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.32'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('data')
        Mock -CommandName Read-Host -MockWith { $script:ansSR.Dequeue() } | Out-Null
        $script:ansSR = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSR.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Storage-Remove } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pvesm remove data' }
    }

    It 'deletes user via pveum user delete' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.33'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('user@pve')
        Mock -CommandName Read-Host -MockWith { $script:ansUD.Dequeue() } | Out-Null
        $script:ansUD = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansUD.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-User-Delete } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'pveum user delete user@pve' }
    }

    It 'creates user token via pveum usertoken add' {
        $conn = [pscustomobject]@{ LabHost='10.0.0.34'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-ProxmoxConnectionInfo -MockWith { $conn }
        $answers = @('user@pve','mytoken','My token for API')
        Mock -CommandName Read-Host -MockWith { $script:ansUT.Dequeue() } | Out-Null
        $script:ansUT = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansUT.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { Proxmox-Token-Create } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'pveum usertoken add user@pve mytoken* --privsep 1* --comment "My token for API"' }
    }
}
