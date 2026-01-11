# Azure Tools

function Get-AzureContextInfo {
    $def = Get-AzureDefaults
    $sub = Read-Host ("SubscriptionId [{0}]" -f $def.SubscriptionId)
    $ten = Read-Host ("TenantId [{0}]" -f $def.TenantId)
    $rg  = Read-Host ("ResourceGroup [{0}]" -f $def.ResourceGroup)
    $loc = Read-Host ("Location [{0}]" -f $def.Location)

    [pscustomobject]@{
        SubscriptionId = if ([string]::IsNullOrWhiteSpace($sub)) { $def.SubscriptionId } else { $sub }
        TenantId       = if ([string]::IsNullOrWhiteSpace($ten)) { $def.TenantId } else { $ten }
        ResourceGroup  = if ([string]::IsNullOrWhiteSpace($rg)) { $def.ResourceGroup } else { $rg }
        Location       = if ([string]::IsNullOrWhiteSpace($loc)) { $def.Location } else { $loc }
    }
}

function Show-AzureToolsMenu {
    $choice = $null
    while ($choice -ne '0') {
        Show-Header -Title "Azure Tools"
        Write-Host " [1] Auth & Identity" -ForegroundColor White
        Write-Host " [2] Resource Provisioning" -ForegroundColor White
        Write-Host " [3] Networking" -ForegroundColor White
        Write-Host " [4] Storage" -ForegroundColor White
        Write-Host " [5] IaC (Export Template)" -ForegroundColor White
        Write-Host " [6] Monitoring" -ForegroundColor White
        Write-Host " [7] Full VM Creation (Az)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $choice = Read-Host "Select a category"
        switch ($choice) {
            '1' { Invoke-Tool -Name 'Azure.Auth' -Action { Azure-Login } }
            '2' { Invoke-Tool -Name 'Azure.Provision' -Action { Azure-ProvisioningMenu } }
            '3' { Invoke-Tool -Name 'Azure.Networking' -Action { Azure-NetworkingMenu } }
            '4' { Invoke-Tool -Name 'Azure.Storage' -Action { Azure-StorageMenu } }
            '5' { Invoke-Tool -Name 'Azure.IaCMenu' -Action { Azure-IaCMenu } }
            '6' { Invoke-Tool -Name 'Azure.Monitoring' -Action { Azure-Get-Metric } }
            '7' { Invoke-Tool -Name 'Azure.VMFull' -Action { Azure-VM-CreateFull } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Azure-IaCMenu {
    $sel = $null
    while ($sel -ne '0') {
        Show-Header -Title "Azure :: IaC"
        Write-Host " [1] Export Resource Group template" -ForegroundColor White
        Write-Host " [2] Export single resource (az CLI)" -ForegroundColor White
        Write-Host " [3] Bicep: Decompile ARM JSON to Bicep" -ForegroundColor White
        Write-Host " [4] Bicep: Build Bicep to ARM JSON" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $sel = Read-Host "Select an action"
        switch ($sel) {
            '1' { Azure-Export-ResourceGroupTemplate }
            '2' { Azure-Export-Resource }
            '3' { Azure-Bicep-Decompile }
            '4' { Azure-Bicep-Build }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Azure-ConnectAccount { param([string]$TenantId) Connect-AzAccount -Tenant $TenantId }
function Azure-SetContext   { param([string]$SubscriptionId) Set-AzContext -Subscription $SubscriptionId }
function Azure-NewResourceGroupCmd { param([string]$Name,[string]$Location) New-AzResourceGroup -Name $Name -Location $Location }
function Azure-NewVirtualNetworkCmd { param([string]$Name,[string]$ResourceGroupName,[string]$Location,[string]$AddressPrefix) New-AzVirtualNetwork -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $AddressPrefix }
function Azure-NewStorageAccountCmd { param([string]$Name,[string]$ResourceGroupName,[string]$Location) New-AzStorageAccount -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location -SkuName Standard_LRS -Kind StorageV2 }
function Azure-ExportResourceGroupCmd { param([string]$ResourceGroupName,[string]$Path) Export-AzResourceGroup -ResourceGroupName $ResourceGroupName -Path $Path }
function Azure-GetMetricCmd { param([string]$ResourceId,[string]$MetricName) Get-AzMetric -ResourceId $ResourceId -TimeGrain 00:05:00 -MetricName $MetricName }

function Azure-Login {
    $ctx = Get-AzureContextInfo
    try {
        Azure-ConnectAccount -TenantId $ctx.TenantId | Out-Null
        Azure-SetContext -SubscriptionId $ctx.SubscriptionId | Out-Null
        Write-Host ("Connected to subscription {0}" -f $ctx.SubscriptionId) -ForegroundColor Green
    } catch {
        Write-Host ("Azure login failed: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-ProvisioningMenu {
    $sel = $null
    while ($sel -ne '0') {
        Show-Header -Title "Azure :: Provisioning"
        Write-Host " [1] Create Resource Group" -ForegroundColor White
        Write-Host " [2] Create Virtual Machine (quick)" -ForegroundColor White
        Write-Host " [3] Create Service Principal" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $sel = Read-Host "Select an action"
        switch ($sel) {
            '1' { Azure-New-ResourceGroup }
            '2' { Azure-VM-CreateQuick }
            '3' { Azure-Identity-CreateServicePrincipal }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Azure-NetworkingMenu {
    $sel = $null
    while ($sel -ne '0') {
        Show-Header -Title "Azure :: Networking"
        Write-Host " [1] Create Virtual Network" -ForegroundColor White
        Write-Host " [2] Create Network Security Group" -ForegroundColor White
        Write-Host " [3] Add Subnet to VNet" -ForegroundColor White
        Write-Host " [4] Associate NSG to Subnet" -ForegroundColor White
        Write-Host " [5] Add NSG preset rule (HTTP/SSH)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $sel = Read-Host "Select an action"
        switch ($sel) {
            '1' { Azure-New-VirtualNetwork }
            '2' { Azure-New-NetworkSecurityGroup }
            '3' { Azure-Add-Subnet-ToVNet }
            '4' { Azure-Associate-NSG-ToSubnet }
            '5' { Azure-NSG-AddPresetRule }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Azure-StorageMenu {
    $sel = $null
    while ($sel -ne '0') {
        Show-Header -Title "Azure :: Storage"
        Write-Host " [1] Create Storage Account" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $sel = Read-Host "Select an action"
        switch ($sel) {
            '1' { Azure-New-StorageAccount }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Azure-New-ResourceGroup {
    $ctx = Get-AzureContextInfo
    $name = Read-Host ("ResourceGroup Name [{0}]" -f $ctx.ResourceGroup)
    $loc  = Read-Host ("Location [{0}]" -f $ctx.Location)
    $rgName = if ([string]::IsNullOrWhiteSpace($name)) { $ctx.ResourceGroup } else { $name }
    $rgLoc  = if ([string]::IsNullOrWhiteSpace($loc))  { $ctx.Location } else { $loc }
    try {
        Azure-NewResourceGroupCmd -Name $rgName -Location $rgLoc | Out-Null
        Write-Host ("Created RG {0} in {1}" -f $rgName, $rgLoc) -ForegroundColor Green
    } catch {
        Write-Host ("Failed to create RG: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-New-VirtualNetwork {
    $ctx = Get-AzureContextInfo
    $def = Get-AzureDefaults
    $name = Read-Host ("VNet Name [{0}]" -f $def.DefaultVNetName)
    $addr = Read-Host "Address Prefix (e.g. 10.0.0.0/16)"
    $rg   = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $loc  = Read-Host ("Location [{0}]" -f $ctx.Location)
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $rgLoc  = if ([string]::IsNullOrWhiteSpace($loc)) { $ctx.Location } else { $loc }
    $name = if ([string]::IsNullOrWhiteSpace($name)) { $def.DefaultVNetName } else { $name }
    try {
        Azure-NewVirtualNetworkCmd -Name $name -ResourceGroupName $rgName -Location $rgLoc -AddressPrefix $addr | Out-Null
        Write-Host ("Created VNet {0} in {1}" -f $name, $rgName) -ForegroundColor Green
    } catch {
        Write-Host ("Failed to create VNet: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-New-StorageAccount {
    $ctx = Get-AzureContextInfo
    $name = Read-Host "Storage Account Name"
    $rg   = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $loc  = Read-Host ("Location [{0}]" -f $ctx.Location)
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $rgLoc  = if ([string]::IsNullOrWhiteSpace($loc)) { $ctx.Location } else { $loc }
    try {
        Azure-NewStorageAccountCmd -Name $name -ResourceGroupName $rgName -Location $rgLoc | Out-Null
        Write-Host ("Created Storage Account {0}" -f $name) -ForegroundColor Green
    } catch {
        Write-Host ("Failed to create Storage Account: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-VM-CreateQuick {
    $ctx  = Get-AzureContextInfo
    $name = Read-Host "VM Name"
    $rg   = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $loc  = Read-Host ("Location [{0}]" -f $ctx.Location)
    $img  = Read-Host "Image (e.g. UbuntuLTS)"
    $size = Read-Host "Size (e.g. Standard_B2s)"
    $adminU = Read-Host "Admin Username"
    $adminP = Read-Host "Admin Password"
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $rgLoc  = if ([string]::IsNullOrWhiteSpace($loc)) { $ctx.Location } else { $loc }

    $cmd = "az vm create --resource-group `"$rgName`" --name `"$name`" --location `"$rgLoc`" --image `"$img`" --size `"$size`" --admin-username `"$adminU`" --admin-password `"$adminP`""
    try { Invoke-Expression $cmd } catch { Write-Host ("VM create failed: {0}" -f $_) -ForegroundColor Red }
    Pause-Return
}

# Identity: Service Principal creation + role assignment (wrappers)
function Azure-NewServicePrincipalCmd { param([string]$DisplayName) New-AzADServicePrincipal -DisplayName $DisplayName }
function Azure-NewRoleAssignmentCmd { param([string]$ObjectId,[string]$RoleDefinitionName,[string]$Scope) New-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $RoleDefinitionName -Scope $Scope }

function Azure-Identity-CreateServicePrincipal {
    $ctx = Get-AzureContextInfo
    $name = Read-Host "Service Principal DisplayName"
    $def = Get-AzureDefaults
    $role = Read-Host ("Role (e.g. Contributor) [{0}]" -f $def.RoleDefinitionName)
    $scopeChoice = Read-Host "Scope type [subscription|resourcegroup]"
    $scope = if ($scopeChoice -eq 'resourcegroup') { "/subscriptions/$($ctx.SubscriptionId)/resourceGroups/$($ctx.ResourceGroup)" } else { "/subscriptions/$($ctx.SubscriptionId)" }
    $role = if ([string]::IsNullOrWhiteSpace($role)) { $def.RoleDefinitionName } else { $role }
    try {
        $sp = Azure-NewServicePrincipalCmd -DisplayName $name
        Azure-NewRoleAssignmentCmd -ObjectId $sp.Id -RoleDefinitionName $role -Scope $scope | Out-Null
        Write-Host ("Created SP '{0}' and assigned role '{1}' on '{2}'" -f $name, $role, $scope) -ForegroundColor Green
    } catch {
        Write-Host ("Service principal setup failed: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

# Networking: NSG and subnet (wrappers)
function Azure-NewNSGCmd { param([string]$Name,[string]$ResourceGroupName,[string]$Location) New-AzNetworkSecurityGroup -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location }
function Azure-CreateNSGRuleConfigCmd { param([string]$Name,[string]$Protocol,[int]$Port,[string]$Direction,[string]$Access)
    New-AzNetworkSecurityRuleConfig -Name $Name -Protocol $Protocol -Direction $Direction -Access $Access -Priority 1000 -SourceAddressPrefix '*' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange $Port
}
function Azure-SetNSGRulesCmd { param($NSG,[object[]]$Rules) $NSG.SecurityRules = $Rules; Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG }

function Azure-New-NetworkSecurityGroup {
    $ctx = Get-AzureContextInfo
    $def = Get-AzureDefaults
    $name = Read-Host ("NSG Name [{0}]" -f $def.DefaultNSGName)
    $rg   = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $loc  = Read-Host ("Location [{0}]" -f $ctx.Location)
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $rgLoc  = if ([string]::IsNullOrWhiteSpace($loc)) { $ctx.Location } else { $loc }
    $name = if ([string]::IsNullOrWhiteSpace($name)) { $def.DefaultNSGName } else { $name }
    try {
        $nsg = Azure-NewNSGCmd -Name $name -ResourceGroupName $rgName -Location $rgLoc
        $rule = Azure-CreateNSGRuleConfigCmd -Name "AllowRDP" -Protocol "Tcp" -Port 3389 -Direction "Inbound" -Access "Allow"
        Azure-SetNSGRulesCmd -NSG $nsg -Rules @($rule) | Out-Null
        Write-Host ("Created NSG {0} with default RDP allow rule" -f $name) -ForegroundColor Green
    } catch {
        Write-Host ("Failed to create NSG: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-AddSubnetConfigCmd { param($VNet,[string]$Name,[string]$Prefix) Add-AzVirtualNetworkSubnetConfig -Name $Name -AddressPrefix $Prefix -VirtualNetwork $VNet }
function Azure-SetVirtualNetworkCmd { param($VNet) Set-AzVirtualNetwork -VirtualNetwork $VNet }
function Azure-GetVirtualNetworkCmd { param([string]$Name,[string]$ResourceGroupName) Get-AzVirtualNetwork -Name $Name -ResourceGroupName $ResourceGroupName }
function Azure-GetNSGCmd { param([string]$Name,[string]$ResourceGroupName) Get-AzNetworkSecurityGroup -Name $Name -ResourceGroupName $ResourceGroupName }
function Azure-SetSubnetConfigCmd { param($VNet,[string]$SubnetName,[string]$Prefix,$NSG) Set-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VNet -AddressPrefix $Prefix -NetworkSecurityGroup $NSG }

function Azure-Add-Subnet-ToVNet {
    $ctx = Get-AzureContextInfo
    $def = Get-AzureDefaults
    $vnet = Read-Host ("VNet Name [{0}]" -f $def.DefaultVNetName)
    $subnet = Read-Host ("Subnet Name [{0}]" -f $def.DefaultSubnetName)
    $prefix = Read-Host "Subnet Prefix (e.g. 10.0.1.0/24)"
    $rg   = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $vnet = if ([string]::IsNullOrWhiteSpace($vnet)) { $def.DefaultVNetName } else { $vnet }
    $subnet = if ([string]::IsNullOrWhiteSpace($subnet)) { $def.DefaultSubnetName } else { $subnet }
    try {
        $vn = Azure-GetVirtualNetworkCmd -Name $vnet -ResourceGroupName $rgName
        $vn = Azure-AddSubnetConfigCmd -VNet $vn -Name $subnet -Prefix $prefix
        Azure-SetVirtualNetworkCmd -VNet $vn | Out-Null
        Write-Host ("Added subnet {0} to VNet {1}" -f $subnet, $vnet) -ForegroundColor Green
    } catch {
        Write-Host ("Failed to add subnet: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-Associate-NSG-ToSubnet {
    $ctx = Get-AzureContextInfo
    $def = Get-AzureDefaults
    $vnet = Read-Host ("VNet Name [{0}]" -f $def.DefaultVNetName)
    $subnet = Read-Host ("Subnet Name [{0}]" -f $def.DefaultSubnetName)
    $nsgName = Read-Host ("NSG Name [{0}]" -f $def.DefaultNSGName)
    $rg   = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $vnet = if ([string]::IsNullOrWhiteSpace($vnet)) { $def.DefaultVNetName } else { $vnet }
    $subnet = if ([string]::IsNullOrWhiteSpace($subnet)) { $def.DefaultSubnetName } else { $subnet }
    $nsgName = if ([string]::IsNullOrWhiteSpace($nsgName)) { $def.DefaultNSGName } else { $nsgName }
    try {
        $vn = Azure-GetVirtualNetworkCmd -Name $vnet -ResourceGroupName $rgName
        $nsg = Azure-GetNSGCmd -Name $nsgName -ResourceGroupName $rgName
        $sub = $vn.Subnets | Where-Object { $_.Name -eq $subnet }
        if (-not $sub) { throw "Subnet not found in VNet." }
        Azure-SetSubnetConfigCmd -VNet $vn -SubnetName $subnet -Prefix $sub.AddressPrefix -NSG $nsg | Out-Null
        Azure-SetVirtualNetworkCmd -VNet $vn | Out-Null
        Write-Host ("Associated NSG {0} to subnet {1} in VNet {2}" -f $nsgName, $subnet, $vnet) -ForegroundColor Green
    } catch {
        Write-Host ("Failed to associate NSG: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

# Full VM creation via Az cmdlets (wrapper)
function Azure-NewVmCmd { param([string]$Name,[string]$ResourceGroupName,[string]$Location,[string]$Image,[string]$Size,[pscredential]$Credential)
    New-AzVM -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location -ImageName $Image -Size $Size -Credential $Credential
}

function Azure-VM-CreateFull {
    $ctx  = Get-AzureContextInfo
    $name = Read-Host "VM Name"
    $rg   = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $loc  = Read-Host ("Location [{0}]" -f $ctx.Location)
    $def = Get-AzureDefaults
    $img  = Read-Host ("Image (e.g. UbuntuLTS) [{0}]" -f $def.DefaultImage)
    $size = Read-Host ("Size (e.g. Standard_B2s) [{0}]" -f $def.DefaultVMSize)
    $user = Read-Host "Admin Username"
    $pass = Read-Host "Admin Password"
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $rgLoc  = if ([string]::IsNullOrWhiteSpace($loc)) { $ctx.Location } else { $loc }
    $img = if ([string]::IsNullOrWhiteSpace($img)) { $def.DefaultImage } else { $img }
    $size = if ([string]::IsNullOrWhiteSpace($size)) { $def.DefaultVMSize } else { $size }
    $sec = ConvertTo-SecureString $pass -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($user, $sec)
    try {
        Azure-NewVmCmd -Name $name -ResourceGroupName $rgName -Location $rgLoc -Image $img -Size $size -Credential $cred | Out-Null
        Write-Host ("Created VM {0}" -f $name) -ForegroundColor Green
    } catch {
        Write-Host ("VM creation failed: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-Export-ResourceGroupTemplate {
    $ctx = Get-AzureContextInfo
    $path = Read-Host "Export path (e.g. .\\output\\rg_template.json)"
    try {
        Azure-ExportResourceGroupCmd -ResourceGroupName $ctx.ResourceGroup -Path $path | Out-Null
        Write-Host ("Exported template for {0} to {1}" -f $ctx.ResourceGroup, $path) -ForegroundColor Green
    } catch {
        Write-Host ("Export failed: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-Get-Metric {
    $rid = Read-Host "ResourceId"
    $metric = Read-Host "MetricName (e.g. Percentage CPU)"
    try {
        Azure-GetMetricCmd -ResourceId $rid -MetricName $metric | Out-Null
        Write-Host "Queried metrics." -ForegroundColor Green
    } catch {
        Write-Host ("Metrics query failed: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

# NSG preset rule helper
function Azure-NSG-AddPresetRule {
    $ctx = Get-AzureContextInfo
    $def = Get-AzureDefaults
    $nsgName = Read-Host ("NSG Name [{0}]" -f $def.DefaultNSGName)
    $preset = Read-Host "Preset [http|ssh]"
    $rg   = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $nsgName = if ([string]::IsNullOrWhiteSpace($nsgName)) { $def.DefaultNSGName } else { $nsgName }
    try {
        $nsg = Azure-GetNSGCmd -Name $nsgName -ResourceGroupName $rgName
        if ($preset -eq 'http') { $rule = Azure-CreateNSGRuleConfigCmd -Name 'AllowHTTP' -Protocol 'Tcp' -Port 80 -Direction 'Inbound' -Access 'Allow' }
        elseif ($preset -eq 'ssh') { $rule = Azure-CreateNSGRuleConfigCmd -Name 'AllowSSH' -Protocol 'Tcp' -Port 22 -Direction 'Inbound' -Access 'Allow' }
        else { throw "Unknown preset" }
        Azure-SetNSGRulesCmd -NSG $nsg -Rules ($nsg.SecurityRules + @($rule)) | Out-Null
        Write-Host ("Added preset rule to NSG {0}" -f $nsgName) -ForegroundColor Green
    } catch {
        Write-Host ("Failed to add NSG rule: {0}" -f $_) -ForegroundColor Red
    }
    Pause-Return
}

function Azure-Bicep-Decompile {
    $inPath = Read-Host "ARM JSON path (e.g. .\\arm.json)"
    $outPath = Read-Host "Output Bicep path (e.g. .\\main.bicep)"
    $cmd = "az bicep decompile --file `"$inPath`" > `"$outPath`""
    try { Invoke-Expression $cmd } catch { Write-Host ("Decompile failed: {0}" -f $_) -ForegroundColor Red }
    Pause-Return
}

function Azure-Bicep-Build {
    $inPath = Read-Host "Bicep file path (e.g. .\\main.bicep)"
    $outPath = Read-Host "Output ARM JSON path (e.g. .\\arm.json)"
    $cmd = "az bicep build --file `"$inPath`" --outfile `"$outPath`""
    try { Invoke-Expression $cmd } catch { Write-Host ("Build failed: {0}" -f $_) -ForegroundColor Red }
    Pause-Return
}

# Per-resource export (ARM template via az CLI)
function Azure-Export-Resource {
    $ctx = Get-AzureContextInfo
    $rg  = Read-Host ("ResourceGroup [{0}]" -f $ctx.ResourceGroup)
    $name = Read-Host "Resource Name"
    $type = Read-Host "Resource Type (e.g. Microsoft.Network/virtualNetworks)"
    $path = Read-Host "Export path (e.g. .\\output\\resource.json)"
    $rgName = if ([string]::IsNullOrWhiteSpace($rg))  { $ctx.ResourceGroup } else { $rg }
    $cmd = "az resource export --resource-group `"$rgName`" --name `"$name`" --resource-type `"$type`" --output json > `"$path`""
    try { Invoke-Expression $cmd } catch { Write-Host ("Export failed: {0}" -f $_) -ForegroundColor Red }
    Pause-Return
}
