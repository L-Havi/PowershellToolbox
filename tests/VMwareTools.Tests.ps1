# Pester tests for VMwareTools.ps1
$ErrorActionPreference = 'Stop'

Describe 'VMwareTools' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $vmwPath = Join-Path $root 'modules\VMwareTools.ps1'
        . "$commonPath"
        . "$vmwPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }

    It 'builds VMware connection info from defaults when inputs blank' {
        $cfg = [pscustomobject]@{ Host='10.1.0.2'; User='root'; SshMethod='ssh'; PlinkPath='plink.exe' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        $answers = @('','','')
        Mock -CommandName Read-Host -MockWith { $script:ans2.Dequeue() } | Out-Null
        $script:ans2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ans2.Enqueue($_) }
        $info = Get-VMwareConnectionInfo
        $info.LabHost | Should -Be '10.1.0.2'
        $info.User | Should -Be 'root'
        $info.SshMethod | Should -Be 'ssh'
    }

    It 'tests SSH connection and invokes hostname' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.3'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'esxi-host' }
        $global:LASTEXITCODE = 0
        { Test-VMwareSSHConnection } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'hostname' }
    }

    It 'queries VM list via vim-cmd' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.4'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'vm list' }
        { Get-VMwareVMList } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'vim-cmd vmsvc/getallvms' }
    }

    It 'shows datastore usage calling esxcli and df -h' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.5'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'ok' }
        { Get-VMwareDatastoreUsage } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'esxcli storage filesystem list' }
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'df -h*' }
    }

    It 'performs VM power operations via vim-cmd' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.6'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('123','start')
        Mock -CommandName Read-Host -MockWith { $script:ansVMP.Dequeue() } | Out-Null
        $script:ansVMP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansVMP.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-Power } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'vim-cmd vmsvc/power.on 123' }
    }

    It 'deletes a VM via vim-cmd vmsvc/destroy' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.7'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('124')
        Mock -CommandName Read-Host -MockWith { $script:ansVMD.Dequeue() } | Out-Null
        $script:ansVMD = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansVMD.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-Delete } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'vim-cmd vmsvc/destroy 124' }
    }

    It 'creates a snapshot via vim-cmd snapshot.create' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.8'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('125','create','prepatch')
        Mock -CommandName Read-Host -MockWith { $script:ansSnap.Dequeue() } | Out-Null
        $script:ansSnap = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSnap.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-Snapshot } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'vim-cmd vmsvc/snapshot.create 125 prepatch 0 0' }
    }

    It 'migrates a VM via govc vm.migrate (host)' {
        $cfg = [pscustomobject]@{ Host='10.1.0.9'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.9'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('vm01','host','esxi02')
        Mock -CommandName Read-Host -MockWith { $script:ansMig.Dequeue() } | Out-Null
        $script:ansMig = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMig.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-Migrate } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'govc vm.migrate -host esxi02 vm01' }
    }

    It 'creates a dummy VM via vim-cmd vmsvc/createdummyvm' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.10'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('vm02','/vmfs/volumes/datastore1/vms/vm02')
        Mock -CommandName Read-Host -MockWith { $script:ansDummy.Dequeue() } | Out-Null
        $script:ansDummy = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansDummy.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-CreateDummy } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'vim-cmd vmsvc/createdummyvm vm02 /vmfs/volumes/datastore1/vms/vm02' }
    }

    It 'clones a VM locally via cp and register' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.11'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('/vmfs/volumes/datastore1/vms/src','/vmfs/volumes/datastore1/vms/dst','/vmfs/volumes/datastore1/vms/dst/dst.vmx')
        Mock -CommandName Read-Host -MockWith { $script:ansClone.Dequeue() } | Out-Null
        $script:ansClone = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansClone.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-CloneLocal } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'cp -r*src*dst*' }
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'vim-cmd solo/registervm*dst.vmx*' }
    }

    It 'deploys a VM from template via govc vm.clone' {
        $cfg = [pscustomobject]@{ Host='10.1.0.12'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.12'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('tmpl01','vm03','','')
        Mock -CommandName Read-Host -MockWith { $script:ansTpl.Dequeue() } | Out-Null
        $script:ansTpl = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansTpl.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-DeployTemplate } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'govc vm.clone -vm tmpl01 -on=false vm03' }
    }

    It 'expands a VM disk via vmkfstools -X' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.13'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('/vmfs/volumes/datastore1/vms/vm3/vm3.vmdk','60G')
        Mock -CommandName Read-Host -MockWith { $script:ansDisk.Dequeue() } | Out-Null
        $script:ansDisk = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansDisk.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-ExpandDisk } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'vmkfstools -X 60G /vmfs/volumes/datastore1/vms/vm3/vm3.vmdk' }
    }

    It 'uploads ISO via scp to datastore folder' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.14'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('C:\isos\debian.iso','datastore1','')
        Mock -CommandName Read-Host -MockWith { $script:ansISO.Dequeue() } | Out-Null
        $script:ansISO = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansISO.Enqueue($_) }
        Mock -CommandName Invoke-Expression -MockWith {}
        { VMware-Upload-ISO } | Should -Not -Throw
        Assert-MockCalled Invoke-Expression -Times 1 -ParameterFilter { $Command -like 'scp*debian.iso*root@10.1.0.14*/vmfs/volumes/datastore1/iso/debian.iso*' }
    }

    It 'creates a VMFS datastore via esxcli storage vmfs create' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.15'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('ds2','naa.123')
        Mock -CommandName Read-Host -MockWith { $script:ansDS.Dequeue() } | Out-Null
        $script:ansDS = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansDS.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-Datastore-Create } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'esxcli storage vmfs create -l ds2 -S naa.123' }
    }

    It 'adds an ESXi host to vCenter via govc host.add' {
        $cfg = [pscustomobject]@{ Host='10.1.0.16'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.16'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('esxi01.local')
        Mock -CommandName Read-Host -MockWith { $script:ansHA.Dequeue() } | Out-Null
        $script:ansHA = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansHA.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-Host-AddToVC } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'govc host.add -hostname esxi01.local' }
    }

    It 'configures networking via esxcli vswitch and portgroup' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.17'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('vSwitch1','PG-VM','20')
        Mock -CommandName Read-Host -MockWith { $script:ansNet.Dequeue() } | Out-Null
        $script:ansNet = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansNet.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-Network-Configure } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'esxcli network vswitch standard add -v vSwitch1' }
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'esxcli network vswitch standard portgroup add -v vSwitch1 -p PG-VM' }
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'esxcli network vswitch standard portgroup set -p PG-VM -v 20' }
    }

    It 'enters maintenance mode via vim-cmd hostsvc/maintenance_mode_enter' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.18'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('enter')
        Mock -CommandName Read-Host -MockWith { $script:ansMM.Dequeue() } | Out-Null
        $script:ansMM = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMM.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-Host-Maintenance } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'vim-cmd hostsvc/maintenance_mode_enter' }
    }

    It 'creates ESXi user via esxcli system account add' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.19'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('ops','Secret123!','Operator')
        Mock -CommandName Read-Host -MockWith { $script:ansUsr.Dequeue() } | Out-Null
        $script:ansUsr = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansUsr.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-ESXi-User-Create } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'esxcli system account add* -i ops* -p Secret123!* -c "Operator"' }
    }

    It 'creates vCenter role via govc role.create' {
        $cfg = [pscustomobject]@{ Host='10.1.0.20'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.20'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('OpsRole','System.View,VirtualMachine.Interact')
        Mock -CommandName Read-Host -MockWith { $script:ansRole.Dequeue() } | Out-Null
        $script:ansRole = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRole.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VC-Role-Create } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'govc role.create* -privileges "System.View,VirtualMachine.Interact"* "OpsRole"' }
    }

    It 'assigns permissions via govc permissions.set' {
        $cfg = [pscustomobject]@{ Host='10.1.0.21'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.21'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('/dc1/vm/Prod/vm01','domain\\user','OpsRole')
        Mock -CommandName Read-Host -MockWith { $script:ansPerm.Dequeue() } | Out-Null
        $script:ansPerm = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansPerm.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VC-Permissions-Assign } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'govc permissions.set* -principal "domain\\user"* -role "OpsRole"* "/dc1/vm/Prod/vm01"' }
    }

    It 'generates inventory via govc find' {
        $cfg = [pscustomobject]@{ Host='10.1.0.22'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.22'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { '/dc1/vm/vm01' }
        { VMware-Report-Inventory } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'govc find -type m -type h -type d' }
    }

    It 'removes an ESXi host from vCenter via govc host.remove' {
        $cfg = [pscustomobject]@{ Host='10.1.0.23'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.23'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('esxi01.local')
        Mock -CommandName Read-Host -MockWith { $script:ansHR.Dequeue() } | Out-Null
        $script:ansHR = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansHR.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-Host-RemoveFromVC } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'govc host.remove -hostname esxi01.local' }
    }

    It 'rescans a storage adapter via esxcli' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.24'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('vmhba0')
        Mock -CommandName Read-Host -MockWith { $script:ansRescan.Dequeue() } | Out-Null
        $script:ansRescan = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRescan.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-Storage-Adapter-Rescan } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'esxcli storage core adapter rescan -A vmhba0' }
    }

    It 'changes cluster DRS/HA via govc cluster.change' {
        $cfg = [pscustomobject]@{ Host='10.1.0.25'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.25'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('Cluster1','y','n')
        Mock -CommandName Read-Host -MockWith { $script:ansClu.Dequeue() } | Out-Null
        $script:ansClu = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansClu.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-Cluster-Settings } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'govc cluster.change* -cluster "Cluster1"* -drs-enabled* -ha-disabled*' }
    }

    It 'patches a host via esxcli software profile update' {
        $conn = [pscustomobject]@{ LabHost='10.1.0.26'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('http://depot','ESXi-8.0-Profile')
        Mock -CommandName Read-Host -MockWith { $script:ansPatch.Dequeue() } | Out-Null
        $script:ansPatch = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansPatch.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-Host-Patch } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -eq 'esxcli software profile update -d http://depot -p ESXi-8.0-Profile' }
    }

    It 'checks host profile compliance via govc host.profile.check' {
        $cfg = [pscustomobject]@{ Host='10.1.0.27'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.27'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('esxi01')
        Mock -CommandName Read-Host -MockWith { $script:ansComp.Dequeue() } | Out-Null
        $script:ansComp = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansComp.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith { 'Compliant' }
        { VMware-Compliance-Check } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'govc host.profile.check* -host "esxi01"' }
    }

    It 'applies a storage policy via govc vm.storage.policy.apply' {
        $cfg = [pscustomobject]@{ Host='10.1.0.28'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.28'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('vm01','GoldPolicy')
        Mock -CommandName Read-Host -MockWith { $script:ansSP.Dequeue() } | Out-Null
        $script:ansSP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSP.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-StoragePolicy-Apply } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'govc vm.storage.policy.apply* -vm vm01* -policy "GoldPolicy"' }
    }

    It 'modifies VM hardware via govc vm.change' {
        $cfg = [pscustomobject]@{ Host='10.1.0.29'; User='root'; SshMethod='ssh'; PlinkPath=''; GovcPath='govc' }
        $conn = [pscustomobject]@{ LabHost='10.1.0.29'; User='root'; SshMethod='ssh'; PlinkPath='' }
        Mock -CommandName Get-VMwareDefaults -MockWith { $cfg }
        Mock -CommandName Get-VMwareConnectionInfo -MockWith { $conn }
        $answers = @('vm01','4','8192')
        Mock -CommandName Read-Host -MockWith { $script:ansHW.Dequeue() } | Out-Null
        $script:ansHW = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansHW.Enqueue($_) }
        Mock -CommandName Invoke-LabRemoteCommand -MockWith {}
        { VMware-VM-SetHardware } | Should -Not -Throw
        Assert-MockCalled Invoke-LabRemoteCommand -Times 1 -ParameterFilter { $RemoteCommand -like 'govc vm.change* -vm "vm01"* -c 4* -m 8192*' }
    }
}
