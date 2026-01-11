# Pester tests for AzureTools.ps1
$ErrorActionPreference = 'Stop'

Describe 'AzureTools' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $azPath = Join-Path $root 'modules\AzureTools.ps1'
        . "$commonPath"
        . "$azPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }

    It 'builds Azure context from defaults when inputs blank' {
        $cfg = [pscustomobject]@{ SubscriptionId='sub123'; TenantId='ten456'; ResourceGroup='rg1'; Location='westeurope' }
        Mock -CommandName Get-AzureDefaults -MockWith { $cfg }
        $answers = @('','','','')
        Mock -CommandName Read-Host -MockWith { $script:ansCtx.Dequeue() } | Out-Null
        $script:ansCtx = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansCtx.Enqueue($_) }
        $info = Get-AzureContextInfo
        $info.SubscriptionId | Should -Be 'sub123'
        $info.TenantId | Should -Be 'ten456'
        $info.ResourceGroup | Should -Be 'rg1'
        $info.Location | Should -Be 'westeurope'
    }

    It 'logs into Azure and sets context' {
        $ctx = [pscustomobject]@{ SubscriptionId='sub789'; TenantId='ten000'; ResourceGroup='rgx'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        Mock -CommandName Azure-ConnectAccount -MockWith {}
        Mock -CommandName Azure-SetContext -MockWith {}
        { Azure-Login } | Should -Not -Throw
        Assert-MockCalled Azure-ConnectAccount -Times 1 -ParameterFilter { $TenantId -eq 'ten000' }
        Assert-MockCalled Azure-SetContext -Times 1 -ParameterFilter { $SubscriptionId -eq 'sub789' }
    }

    It 'creates a resource group with defaults' {
        $ctx = [pscustomobject]@{ SubscriptionId='sub1'; TenantId='ten1'; ResourceGroup='rg2'; Location='eastus2' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('','')
        Mock -CommandName Read-Host -MockWith { $script:ansRG.Dequeue() } | Out-Null
        $script:ansRG = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRG.Enqueue($_) }
        Mock -CommandName Azure-NewResourceGroupCmd -MockWith {}
        { Azure-New-ResourceGroup } | Should -Not -Throw
        Assert-MockCalled Azure-NewResourceGroupCmd -Times 1 -ParameterFilter { $Name -eq 'rg2' -and $Location -eq 'eastus2' }
    }

    It 'creates a virtual network' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg3'; Location='westeurope' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vnet1','10.0.0.0/16','','')
        Mock -CommandName Read-Host -MockWith { $script:ansVnet.Dequeue() } | Out-Null
        $script:ansVnet = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansVnet.Enqueue($_) }
        Mock -CommandName Azure-NewVirtualNetworkCmd -MockWith {}
        { Azure-New-VirtualNetwork } | Should -Not -Throw
        Assert-MockCalled Azure-NewVirtualNetworkCmd -Times 1 -ParameterFilter { $Name -eq 'vnet1' -and $ResourceGroupName -eq 'rg3' -and $Location -eq 'westeurope' -and $AddressPrefix -eq '10.0.0.0/16' }
    }

    It 'creates a network security group with a default rule' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg3'; Location='westeurope' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('nsg1','','')
        Mock -CommandName Read-Host -MockWith { $script:ansNSG.Dequeue() } | Out-Null
        $script:ansNSG = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansNSG.Enqueue($_) }
        Mock -CommandName Azure-NewNSGCmd -MockWith { [pscustomobject]@{ SecurityRules = New-Object System.Collections.ArrayList } }
        Mock -CommandName Azure-CreateNSGRuleConfigCmd -MockWith { [pscustomobject]@{ Name = 'AllowRDP' } }
        Mock -CommandName Azure-SetNSGRulesCmd -MockWith {}
        { Azure-New-NetworkSecurityGroup } | Should -Not -Throw
        Assert-MockCalled Azure-NewNSGCmd -Times 1 -ParameterFilter { $Name -eq 'nsg1' -and $ResourceGroupName -eq 'rg3' -and $Location -eq 'westeurope' }
        Assert-MockCalled Azure-CreateNSGRuleConfigCmd -Times 1 -ParameterFilter { $Name -eq 'AllowRDP' }
        Assert-MockCalled Azure-SetNSGRulesCmd -Times 1
    }

    It 'adds a subnet to a virtual network' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg3'; Location='westeurope' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vnet1','subnet1','10.0.1.0/24','')
        Mock -CommandName Read-Host -MockWith { $script:ansSubnet.Dequeue() } | Out-Null
        $script:ansSubnet = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSubnet.Enqueue($_) }
        Mock -CommandName Azure-GetVirtualNetworkCmd -MockWith { [pscustomobject]@{} }
        Mock -CommandName Azure-AddSubnetConfigCmd -MockWith { [pscustomobject]@{} }
        Mock -CommandName Azure-SetVirtualNetworkCmd -MockWith {}
        { Azure-Add-Subnet-ToVNet } | Should -Not -Throw
        Assert-MockCalled Azure-GetVirtualNetworkCmd -Times 1 -ParameterFilter { $Name -eq 'vnet1' -and $ResourceGroupName -eq 'rg3' }
        Assert-MockCalled Azure-AddSubnetConfigCmd -Times 1 -ParameterFilter { $Name -eq 'subnet1' -and $Prefix -eq '10.0.1.0/24' }
        Assert-MockCalled Azure-SetVirtualNetworkCmd -Times 1
    }

    It 'creates a service principal and assigns a role' {
        $ctx = [pscustomobject]@{ SubscriptionId='subX'; TenantId='tenX'; ResourceGroup='rgX'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('sp-tool','Contributor','subscription')
        Mock -CommandName Read-Host -MockWith { $script:ansSP.Dequeue() } | Out-Null
        $script:ansSP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSP.Enqueue($_) }
        Mock -CommandName Azure-NewServicePrincipalCmd -MockWith { [pscustomobject]@{ Id = '1111' } }
        Mock -CommandName Azure-NewRoleAssignmentCmd -MockWith {}
        { Azure-Identity-CreateServicePrincipal } | Should -Not -Throw
        Assert-MockCalled Azure-NewServicePrincipalCmd -Times 1 -ParameterFilter { $DisplayName -eq 'sp-tool' }
        Assert-MockCalled Azure-NewRoleAssignmentCmd -Times 1 -ParameterFilter { $ObjectId -eq '1111' -and $RoleDefinitionName -eq 'Contributor' -and $Scope -eq '/subscriptions/subX' }
    }

    It 'creates a full VM via Az cmdlets' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg6'; Location='southcentralus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vm02','','','UbuntuLTS','Standard_B2s','adminuser','Adm1nPass!')
        Mock -CommandName Read-Host -MockWith { $script:ansVM2.Dequeue() } | Out-Null
        $script:ansVM2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansVM2.Enqueue($_) }
        Mock -CommandName Azure-NewVmCmd -MockWith {}
        { Azure-VM-CreateFull } | Should -Not -Throw
        Assert-MockCalled Azure-NewVmCmd -Times 1 -ParameterFilter { $Name -eq 'vm02' -and $ResourceGroupName -eq 'rg6' -and $Location -eq 'southcentralus' -and $Image -eq 'UbuntuLTS' -and $Size -eq 'Standard_B2s' }
    }

    It 'creates a storage account' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg4'; Location='centralus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('stlab','','')
        Mock -CommandName Read-Host -MockWith { $script:ansSA.Dequeue() } | Out-Null
        $script:ansSA = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSA.Enqueue($_) }
        Mock -CommandName Azure-NewStorageAccountCmd -MockWith {}
        { Azure-New-StorageAccount } | Should -Not -Throw
        Assert-MockCalled Azure-NewStorageAccountCmd -Times 1 -ParameterFilter { $Name -eq 'stlab' -and $ResourceGroupName -eq 'rg4' -and $Location -eq 'centralus' }
    }

    It 'exports a resource group template' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg5'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('.\\output\\rg5.json')
        Mock -CommandName Read-Host -MockWith { $script:ansExp.Dequeue() } | Out-Null
        $script:ansExp = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansExp.Enqueue($_) }
        Mock -CommandName Azure-ExportResourceGroupCmd -MockWith {}
        { Azure-Export-ResourceGroupTemplate } | Should -Not -Throw
        Assert-MockCalled Azure-ExportResourceGroupCmd -Times 1 -ParameterFilter { $ResourceGroupName -eq 'rg5' -and $Path -eq '.\\output\\rg5.json' }
    }

    It 'queries metrics via Get-AzMetric' {
        $answers = @('/subscriptions/x/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm01','Percentage CPU')
        Mock -CommandName Read-Host -MockWith { $script:ansMet.Dequeue() } | Out-Null
        $script:ansMet = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMet.Enqueue($_) }
        Mock -CommandName Azure-GetMetricCmd -MockWith {}
        { Azure-Get-Metric } | Should -Not -Throw
        Assert-MockCalled Azure-GetMetricCmd -Times 1 -ParameterFilter { $ResourceId -like '*virtualMachines/vm01' -and $MetricName -eq 'Percentage CPU' }
    }

    It 'creates a VM via az CLI build string' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg6'; Location='southcentralus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vm01','','','UbuntuLTS','Standard_B2s','adminuser','Adm1nPass!')
        Mock -CommandName Read-Host -MockWith { $script:ansVM.Dequeue() } | Out-Null
        $script:ansVM = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansVM.Enqueue($_) }
        Mock -CommandName Invoke-Expression -MockWith {}
        { Azure-VM-CreateQuick } | Should -Not -Throw
        Assert-MockCalled Invoke-Expression -Times 1 -ParameterFilter { $Command -like 'az vm create*--resource-group "rg6"*--name "vm01"*--location "southcentralus"*--image "UbuntuLTS"*--size "Standard_B2s"*--admin-username "adminuser"*--admin-password "Adm1nPass!"*' }
    }

    It 'creates a service principal and assigns role' {
        $ctx = [pscustomobject]@{ SubscriptionId='sub123'; TenantId='ten456'; ResourceGroup='rg1'; Location='westeurope' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('sp-display','Contributor','subscription')
        Mock -CommandName Read-Host -MockWith { $script:ansSP.Dequeue() } | Out-Null
        $script:ansSP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSP.Enqueue($_) }
        $spObj = [pscustomobject]@{ Id = '0000-1111' }
        Mock -CommandName Azure-NewServicePrincipalCmd -MockWith { $spObj }
        Mock -CommandName Azure-NewRoleAssignmentCmd -MockWith {}
        { Azure-Identity-CreateServicePrincipal } | Should -Not -Throw
        Assert-MockCalled Azure-NewServicePrincipalCmd -Times 1 -ParameterFilter { $DisplayName -eq 'sp-display' }
        Assert-MockCalled Azure-NewRoleAssignmentCmd -Times 1 -ParameterFilter { $ObjectId -eq '0000-1111' -and $RoleDefinitionName -eq 'Contributor' -and $Scope -like '/subscriptions/sub123' }
    }

    It 'creates an NSG with a default RDP rule' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg7'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('nsg1','','')
        Mock -CommandName Read-Host -MockWith { $script:ansNSG.Dequeue() } | Out-Null
        $script:ansNSG = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansNSG.Enqueue($_) }
        $nsgObj = [pscustomobject]@{ SecurityRules = @() }
        Mock -CommandName Azure-NewNSGCmd -MockWith { $nsgObj }
        Mock -CommandName Azure-CreateNSGRuleConfigCmd -MockWith { [pscustomobject]@{ Name='AllowRDP' } }
        Mock -CommandName Azure-SetNSGRulesCmd -MockWith {}
        { Azure-New-NetworkSecurityGroup } | Should -Not -Throw
        Assert-MockCalled Azure-NewNSGCmd -Times 1 -ParameterFilter { $Name -eq 'nsg1' -and $ResourceGroupName -eq 'rg7' -and $Location -eq 'eastus' }
        Assert-MockCalled Azure-SetNSGRulesCmd -Times 1
    }

    It 'adds a subnet to an existing VNet' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg8'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vnet1','subnet1','10.0.1.0/24','')
        Mock -CommandName Read-Host -MockWith { $script:ansSub.Dequeue() } | Out-Null
        $script:ansSub = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSub.Enqueue($_) }
        $vnetObj = [pscustomobject]@{ }
        Mock -CommandName Azure-GetVirtualNetworkCmd -MockWith { $vnetObj }
        Mock -CommandName Azure-AddSubnetConfigCmd -MockWith { $vnetObj }
        Mock -CommandName Azure-SetVirtualNetworkCmd -MockWith {}
        { Azure-Add-Subnet-ToVNet } | Should -Not -Throw
        Assert-MockCalled Azure-GetVirtualNetworkCmd -Times 1 -ParameterFilter { $Name -eq 'vnet1' -and $ResourceGroupName -eq 'rg8' }
        Assert-MockCalled Azure-SetVirtualNetworkCmd -Times 1
    }

    It 'creates a VM via Az cmdlets' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rg9'; Location='westus2' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vm02','','','UbuntuLTS','Standard_B2s','adminuser','Adm1nPass!')
        Mock -CommandName Read-Host -MockWith { $script:ansFull.Dequeue() } | Out-Null
        $script:ansFull = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansFull.Enqueue($_) }
        Mock -CommandName Azure-NewVmCmd -MockWith {}
        { Azure-VM-CreateFull } | Should -Not -Throw
        Assert-MockCalled Azure-NewVmCmd -Times 1 -ParameterFilter { $Name -eq 'vm02' -and $ResourceGroupName -eq 'rg9' -and $Location -eq 'westus2' -and $Image -eq 'UbuntuLTS' -and $Size -eq 'Standard_B2s' }
    }

    It 'creates a service principal and assigns role at subscription scope' {
        $ctx = [pscustomobject]@{ SubscriptionId='subX'; TenantId='tenX'; ResourceGroup='rgX'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('sp-display','Contributor','subscription')
        Mock -CommandName Read-Host -MockWith { $script:ansSP.Dequeue() } | Out-Null
        $script:ansSP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSP.Enqueue($_) }
        $spObj = [pscustomobject]@{ Id='1111-2222' ; DisplayName='sp-display' }
        Mock -CommandName Azure-NewServicePrincipalCmd -MockWith { $spObj }
        Mock -CommandName Azure-NewRoleAssignmentCmd -MockWith {}
        { Azure-Identity-CreateServicePrincipal } | Should -Not -Throw
        Assert-MockCalled Azure-NewServicePrincipalCmd -Times 1 -ParameterFilter { $DisplayName -eq 'sp-display' }
        Assert-MockCalled Azure-NewRoleAssignmentCmd -Times 1 -ParameterFilter { $ObjectId -eq '1111-2222' -and $RoleDefinitionName -eq 'Contributor' -and $Scope -eq '/subscriptions/subX' }
    }

    It 'uses default role when blank for service principal' {
        $ctx = [pscustomobject]@{ SubscriptionId='subY'; TenantId='tenY'; ResourceGroup='rgY'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        Mock -CommandName Get-AzureDefaults -MockWith { [pscustomobject]@{ RoleDefinitionName='Contributor' } }
        $answers = @('sp2','','subscription')
        Mock -CommandName Read-Host -MockWith { $script:ansSP2.Dequeue() } | Out-Null
        $script:ansSP2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSP2.Enqueue($_) }
        $spObj = [pscustomobject]@{ Id='abcd'; DisplayName='sp2' }
        Mock -CommandName Azure-NewServicePrincipalCmd -MockWith { $spObj }
        Mock -CommandName Azure-NewRoleAssignmentCmd -MockWith {}
        { Azure-Identity-CreateServicePrincipal } | Should -Not -Throw
        Assert-MockCalled Azure-NewRoleAssignmentCmd -Times 1 -ParameterFilter { $RoleDefinitionName -eq 'Contributor' -and $Scope -eq '/subscriptions/subY' }
    }

    It 'creates NSG with default RDP rule' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rgN'; Location='westeurope' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('nsg1','','')
        Mock -CommandName Read-Host -MockWith { $script:ansNSG.Dequeue() } | Out-Null
        $script:ansNSG = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansNSG.Enqueue($_) }
        $nsgObj = [pscustomobject]@{ Name='nsg1'; SecurityRules=@() }
        Mock -CommandName Azure-NewNSGCmd -MockWith { $nsgObj }
        Mock -CommandName Azure-CreateNSGRuleConfigCmd -MockWith { [pscustomobject]@{ Name='AllowRDP'; DestinationPortRange=3389 } }
        Mock -CommandName Azure-SetNSGRulesCmd -MockWith {}
        { Azure-New-NetworkSecurityGroup } | Should -Not -Throw
        Assert-MockCalled Azure-NewNSGCmd -Times 1 -ParameterFilter { $Name -eq 'nsg1' -and $ResourceGroupName -eq 'rgN' -and $Location -eq 'westeurope' }
        Assert-MockCalled Azure-SetNSGRulesCmd -Times 1
    }

    It 'adds a subnet to an existing VNet' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rgV'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vnet1','sub1','10.0.1.0/24','')
        Mock -CommandName Read-Host -MockWith { $script:ansSub.Dequeue() } | Out-Null
        $script:ansSub = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSub.Enqueue($_) }
        $vnetObj = [pscustomobject]@{ Name='vnet1'; Subnets=@() }
        Mock -CommandName Azure-GetVirtualNetworkCmd -MockWith { $vnetObj }
        Mock -CommandName Azure-AddSubnetConfigCmd -MockWith { $vnetObj }
        Mock -CommandName Azure-SetVirtualNetworkCmd -MockWith {}
        { Azure-Add-Subnet-ToVNet } | Should -Not -Throw
        Assert-MockCalled Azure-GetVirtualNetworkCmd -Times 1 -ParameterFilter { $Name -eq 'vnet1' -and $ResourceGroupName -eq 'rgV' }
        Assert-MockCalled Azure-SetVirtualNetworkCmd -Times 1
    }

    It 'associates NSG to a subnet' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rgA'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vnet2','sub2','nsg2','')
        Mock -CommandName Read-Host -MockWith { $script:ansAssoc.Dequeue() } | Out-Null
        $script:ansAssoc = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansAssoc.Enqueue($_) }
        $subObj = [pscustomobject]@{ Name='sub2'; AddressPrefix='10.0.2.0/24' }
        $vnetObj = [pscustomobject]@{ Name='vnet2'; Subnets=@($subObj) }
        $nsgObj = [pscustomobject]@{ Name='nsg2' }
        Mock -CommandName Azure-GetVirtualNetworkCmd -MockWith { $vnetObj }
        Mock -CommandName Azure-GetNSGCmd -MockWith { $nsgObj }
        Mock -CommandName Azure-SetSubnetConfigCmd -MockWith {}
        Mock -CommandName Azure-SetVirtualNetworkCmd -MockWith {}
        { Azure-Associate-NSG-ToSubnet } | Should -Not -Throw
        Assert-MockCalled Azure-SetSubnetConfigCmd -Times 1 -ParameterFilter { $SubnetName -eq 'sub2' }
        Assert-MockCalled Azure-SetVirtualNetworkCmd -Times 1
    }

    It 'adds NSG preset SSH rule' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rgP'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        Mock -CommandName Get-AzureDefaults -MockWith { [pscustomobject]@{ DefaultNSGName='nsg1' } }
        $answers = @('','ssh','')
        Mock -CommandName Read-Host -MockWith { $script:ansPreset.Dequeue() } | Out-Null
        $script:ansPreset = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansPreset.Enqueue($_) }
        $nsgObj = [pscustomobject]@{ Name='nsg1'; SecurityRules=@() }
        Mock -CommandName Azure-GetNSGCmd -MockWith { $nsgObj }
        Mock -CommandName Azure-CreateNSGRuleConfigCmd -MockWith { [pscustomobject]@{ Name='AllowSSH'; DestinationPortRange=22 } }
        Mock -CommandName Azure-SetNSGRulesCmd -MockWith {}
        { Azure-NSG-AddPresetRule } | Should -Not -Throw
        Assert-MockCalled Azure-SetNSGRulesCmd -Times 1
    }

    It 'adds NSG preset HTTP rule' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rgP'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        Mock -CommandName Get-AzureDefaults -MockWith { [pscustomobject]@{ DefaultNSGName='nsg1' } }
        $answers = @('','http','')
        Mock -CommandName Read-Host -MockWith { $script:ansPresetHttp.Dequeue() } | Out-Null
        $script:ansPresetHttp = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansPresetHttp.Enqueue($_) }
        $nsgObj = [pscustomobject]@{ Name='nsg1'; SecurityRules=@() }
        Mock -CommandName Azure-GetNSGCmd -MockWith { $nsgObj }
        Mock -CommandName Azure-CreateNSGRuleConfigCmd -MockWith { [pscustomobject]@{ Name='AllowHTTP'; DestinationPortRange=80 } }
        Mock -CommandName Azure-SetNSGRulesCmd -MockWith {}
        { Azure-NSG-AddPresetRule } | Should -Not -Throw
        Assert-MockCalled Azure-SetNSGRulesCmd -Times 1
    }

    It 'exports single resource via az CLI command' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rgE'; Location='eastus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('','vnet1','Microsoft.Network/virtualNetworks','.\\output\\vnet1.json')
        Mock -CommandName Read-Host -MockWith { $script:ansExpRes.Dequeue() } | Out-Null
        $script:ansExpRes = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansExpRes.Enqueue($_) }
        Mock -CommandName Invoke-Expression -MockWith {}
        { Azure-Export-Resource } | Should -Not -Throw
        Assert-MockCalled Invoke-Expression -Times 1 -ParameterFilter { $Command -like 'az resource export*--resource-group "rgE"*--name "vnet1"*--resource-type "Microsoft.Network/virtualNetworks"*--output json*' }
    }

    It 'creates a VM via Az cmdlets wrapper' {
        $ctx = [pscustomobject]@{ SubscriptionId='s'; TenantId='t'; ResourceGroup='rgZ'; Location='centralus' }
        Mock -CommandName Get-AzureContextInfo -MockWith { $ctx }
        $answers = @('vm02','','','UbuntuLTS','Standard_B2s','adminuser','Adm1nPass!')
        Mock -CommandName Read-Host -MockWith { $script:ansVMF.Dequeue() } | Out-Null
        $script:ansVMF = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansVMF.Enqueue($_) }
        Mock -CommandName Azure-NewVmCmd -MockWith {}
        { Azure-VM-CreateFull } | Should -Not -Throw
        Assert-MockCalled Azure-NewVmCmd -Times 1 -ParameterFilter { $Name -eq 'vm02' -and $ResourceGroupName -eq 'rgZ' -and $Location -eq 'centralus' -and $Image -eq 'UbuntuLTS' -and $Size -eq 'Standard_B2s' }
    }
}

Describe 'Azure IaC helpers' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        . (Join-Path $root 'modules\Common.ps1')
        . (Join-Path $root 'modules\AzureTools.ps1')
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'decompiles ARM JSON to Bicep using az CLI' {
        $answers = @('.\arm.json','.\main.bicep')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        Mock -CommandName Invoke-Expression -MockWith {}
        { Azure-Bicep-Decompile } | Should -Not -Throw
        Assert-MockCalled Invoke-Expression -Times 1 -ParameterFilter { $Command -like '*az bicep decompile*' }
    }

    It 'builds Bicep to ARM JSON using az CLI' {
        $answers = @('.\main.bicep','.\arm.json')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        Mock -CommandName Invoke-Expression -MockWith {}
        { Azure-Bicep-Build } | Should -Not -Throw
        Assert-MockCalled Invoke-Expression -Times 1 -ParameterFilter { $Command -like '*az bicep build*' }
    }
}
