# PowerShell Toolbox

Last updated: 2026-01-11

A modular, menu-driven toolbox for common Windows admin tasks: file management, networking, system/services (including Active Directory), security, hypervisors (Proxmox/VMware), and Cloud Environments (Azure). Includes Pester tests and YAML-based defaults. Output and logging are configurable and enabled by default.

## Quick Start

```powershell
Set-Location -LiteralPath "C:\Path\To\Project\Folder"
# Optional: edit config first
notepad .\config.yaml
# Launch toolbox
.\PowershellToolbox.ps1
```

- Directories with spaces are handled; use `-LiteralPath` when changing locations.
- Many network/system actions require an elevated PowerShell.

## Configuration (config.yaml)

The toolbox reads defaults from `config.yaml` in the repo root. All prompts accept Enter to use these defaults.

Sections:

- SystemSettings (currently informational)
- NetworkDefaults
  - InterfaceAlias
  - IPv4Address
  - PrefixLength or SubnetMask
  - DefaultGateway
  - DnsServers (comma-separated)
  - DnsSuffix
  - ShareName, SharePath
  - DriveLetter, UNCPath
  - Optional route defaults (uncomment/add as needed):
    - RouteDestinationPrefix, RouteNextHop, RouteInterfaceAlias, RouteMetric
- RemoteDefaults
  - SSHHost, SSHUser, SSHPort
  - TelnetHost, TelnetPort
  - RDPHost, RDPPort
- ListenerDefaults
  - BindAddress, Port, AutoStopSeconds (0 = wait for Enter)
- TransferDefaults
  - SFTPHost, SFTPUser, SFTPPort, SFTPRemotePath
  - PSFTPPath (optional fallback when `psftp` is not in PATH)
  - FTPHost, FTPPort, FTPRemotePath
  - VerificationAlgorithm (currently SHA256)
 - ProcessDefaults
   - Executable, Arguments, NameToStop
 - RegistryDefaults
   - Hive (HKLM/HKCU), Path, ValueName
- ProxmoxDefaults
  - Host, User, SshMethod (ssh|plink), PlinkPath
- VmwareDefaults
  - Host, User, SshMethod (ssh|plink), PlinkPath
  - Optional: VCenterHost, VCenterUser, GovcPath
  - Optional datastore defaults: DefaultDatastore, IsoFolder
- AzureDefaults
  - SubscriptionId, TenantId, ResourceGroup, Location
  - RoleDefinitionName (default RBAC role for SP creation)
  - DefaultVNetName, DefaultSubnetName, DefaultNSGName
  - DefaultImage, DefaultVMSize
- ADDefaults
  - DomainController (optional)
  - DefaultUserOU, DefaultGroupOU, DefaultComputerOU
  - DefaultPassword, DefaultGroupScope
  - DefaultHomeFolderRoot, DefaultHomeDrive

Output and logging:
- OutputSettings: `Enabled`, `Folder` (default: `output`), `WriteHashManifest`
- LoggingSettings: `Enabled`, `Folder` (default: `logs`), `FileName` (default: `toolbox.log`)

See example values in [config.yaml](config.yaml).

## Menus & Features

Menu Overview
- Main Menu
  - File Management Tools
    - Comparisons & Listings
      - Compare folders (basic)
      - Compare folders (hash)
      - Find duplicate files
      - Directory listing
      - Tree view of folder
    - Create & Delete
      - Create new file
      - Delete a file
      - Delete files older than X days
    - Copy, Move & Compress
      - Copy item (file/folder)
      - Move item (file/folder)
      - Compress folder (ZIP/7Z/TAR)
    - Hashing
      - Compute hash (MD5/SHA1/SHA256/SHA384/SHA512)
  - Network Tools
    - Diagnostics (Ping, IP, Port)
      - Ping host
      - Show IP configuration
      - Test TCP port
    - Adapter & IP
      - Show adapter properties
      - Set IPv4 static address
    - DNS & DHCP
      - Set DNS servers
      - Set DNS connection suffix
      - DHCP: show/enable/release/renew
    - Shares & Drives
      - Create SMB share
      - Remove SMB share
      - Map network drive
    - Routing
      - Show table
      - Add route
      - Remove route
    - Remote Connections
      - SSH 
      - Telnet 
      - RDP
    - Listeners
      - Start TCP listener
    - Transfers (SFTP/FTP)
      - SFTP: session/upload/download (with hash verification)
      - FTP: session/upload/download (with hash verification)
  - System Tools
    - Diagnostics
      - Disk usage
      - System info summary
      - Top processes by memory
    - Services
      - List all
      - Start / Restart
      - Disable / Enable startup
    - Processes
      - List (filter/sort)
      - Start process
      - Stop process
    - Registry
      - Read value (HKLM/HKCU)
      - Set value (HKLM/HKCU)
    - Active Directory
      - Core User Management:
        - Create user: `AD-User-Create`
        - Disable/Enable: `AD-User-Disable`, `AD-User-Enable`
        - Delete (confirmation-aware): `AD-User-Delete`
        - Reset password + unlock: `AD-User-ResetPasswordUnlock`
        - Move between OUs: `AD-User-MoveBetweenOU`
        - Bulk create (CSV): `AD-User-BulkCreateFromCsv`
        - Bulk update (CSV): `AD-User-BulkUpdateFromCsv`
        - Set home folder: `AD-User-SetHomeFolder`
        - Generate CSV templates: `AD-GenerateCsvTemplates`
      - Group Management:
        - Create/Delete (confirmation-aware): `AD-Group-Create`, `AD-Group-Delete`
        - Add/Remove member: `AD-Group-AddMember`, `AD-Group-RemoveMember`
        - Convert scope: `AD-Group-ConvertScope`
        - Audit membership snapshot: `AD-Group-AuditMembership`
        - Check user membership: `AD-User-CheckGroupMembership`
      - Organizational Units:
        - Create/Rename/Move/Delete (confirmation-aware): `AD-OU-Create`, `AD-OU-Rename`, `AD-OU-Move`, `AD-OU-Delete`
        - Delegate permission (simplified): `AD-OU-DelegatePermission`
        - Cleanup empty OUs (advisory): `AD-Cleanup-EmptyOUs`
      - Computer Accounts:
        - Create/Delete (confirmation-aware): `AD-Computer-Create`, `AD-Computer-Delete`
        - Reset account: `AD-Computer-ResetAccount`
        - Move between OUs: `AD-Computer-MoveBetweenOU`
        - Report inactive computers: `AD-Report-InactiveComputers`
      - Searching & Reporting:
        - Locked-out users: `AD-Report-LockedOutUsers`
        - Disabled accounts: `AD-Report-DisabledAccounts`
        - Password expiration: `AD-Report-PasswordExpiration`
        - Last logon times: `AD-Report-LastLogonTimes`
        - Inactive users: `AD-Report-InactiveUsers`
        - Group membership report: `AD-Report-GroupMembership`
      - Security & Access Control:
        - Read/Modify ACL (simplified): `AD-ACL-Read`, `AD-ACL-Modify`
        - Permissions audit (CSV): `AD-Audit-Permissions`
      - Domain & Infrastructure:
        - FSMO roles view/transfer/seize: `AD-FSMO-View`, `AD-FSMO-Transfer`, `AD-FSMO-Seize`
        - Trusts view/create/remove (guarded): `AD-Trusts-View`, `AD-Trusts-Create`, `AD-Trusts-Remove`
        - Sites & Subnets: `AD-Sites-Create`
        - Replication monitor: `AD-Replication-Monitor`
        - DC health check: `AD-DC-HealthCheck`
      - Service Accounts (gMSA):
        - Create/Install/Get: `AD-gMSA-Create`, `AD-gMSA-Install`, `AD-gMSA-Get`
  - Security Tools
    - Local Administrators members
    - Windows Defender status
    - Windows Firewall profile status
  - Hypervisor Tools
    - Proxmox Tools
      - Connection & Basics:
        - SSH connectivity test 
        - qm list 
        - storage usage (pvesm status, df -h)
      - VM & Container Management
        - VM power: start/stop/restart/delete (qm start/stop/reboot/destroy)
        - CT power: start/stop/shutdown/delete (pct start/stop/shutdown/destroy)
        - Clone VM (full or linked): qm clone
        - Modify VM hardware: qm set (cores/memory/NIC), qm resize (disk)
        - Snapshots: create/restore (qm snapshot / qm rollback)
        - Migrate VM between nodes: qm migrate
        - Query VM status/config: qm status / qm config
        - Create VM: qm create with optional --ide2 iso,media=cdrom, --net0
        - Create CT (LXC): pct create with -hostname, -cores, -memory, -rootfs
      - Storage & Backup Automation
        - Trigger backup: vzdump with mode, storage, vmid list
        - Monitor backup jobs: journalctl -u vzdump
        - Storage pools list: pvesm status
        - Upload ISO via scp to /var/lib/vz/template/iso
        - Resize VM disk: qm resize
        - Backup jobs: list/create/delete via pvesh (/cluster/backup)
        - Add/Remove storage: pvesm add dir|nfs|cifs / pvesm remove
      - Cluster & Node Operations
        - Cluster health/quorum: pvecm status
        - Manage nodes: add/remove (pvecm add / pvecm delnode)
        - Ceph status: ceph -s
        - Node monitor (CPU/mem/disk): shell commands
        - Node power: reboot/shutdown
        - HA status: ha-manager status
      - User & Permission Management
        - Create/modify user: pveum user add (+ optional pveum passwd)
        - Create role with privileges: pveum role add -privs ...
        - Assign permissions (ACL): pveum aclmod
        - Delete user: pveum user delete
        - Create user API token: pveum usertoken add
    - VMware Tools
      - Connection & Basics: 
        - SSH connectivity test 
        - vim-cmd vmsvc/getallvms 
        - datastore usage (esxcli storage filesystem list, df -h)
      - VM Lifecycle Management:
        - Power: start/stop/reset/suspend (vim-cmd vmsvc/power.*)
        - Delete VM: vim-cmd vmsvc/destroy
        - Snapshots: create/revert/remove (vim-cmd vmsvc/snapshot.*)
        - Migrate VM: vMotion/Storage vMotion via govc vm.migrate (requires vCenter/govc)
        - Create dummy VM: vim-cmd vmsvc/createdummyvm
        - Clone locally: copy VM folder + register (cp -r, vim-cmd solo/registervm)
        - Deploy from template: govc vm.clone (requires vCenter/govc)
        - Modify hardware: CPU/RAM via govc vm.change
      - Storage & Datastore Operations
        - Datastore list: esxcli storage filesystem list
        - Expand VM disk: vmkfstools -X
        - Upload ISOs: scp to /vmfs/volumes/<datastore>/<folder>
        - Create VMFS datastore: esxcli storage vmfs create
        - Apply storage policy: govc vm.storage.policy.apply (requires vCenter/govc)
      - Host & Cluster Management
        - Add/remove host: govc host.add / govc host.remove
        - Configure networking: esxcli network vswitch standard ... (vSwitch, portgroup, VLAN)
        - Rescan storage adapter: esxcli storage core adapter rescan
        - Cluster settings (DRS/HA): govc cluster.change (requires vCenter/govc)
        - Patch/update host: esxcli software profile update
        - Maintenance mode: vim-cmd hostsvc/maintenance_mode_enter|exit      
      - User, Role & Permission Management
        - ESXi user: esxcli system account add
        - vCenter role: govc role.create
        - Assign permissions: govc permissions.set
        - Create SSO user: govc sso.user.create
      - Monitoring, Reporting & Compliance
        - Inventory report: govc find (fallback to vim-cmd vmsvc/getallvms)
        - Performance metrics: govc metric.sample
        - Host profile compliance: govc host.profile.check
  - Cloud Environment Tools
    - Azure Tools
      - Auth & Identity:
        - Login and set subscription context: Connect-AzAccount, Set-AzContext
        - Create Service Principal and assign role: New-AzADServicePrincipal, New-AzRoleAssignment
      - Resource Provisioning:
        - Resource Group: New-AzResourceGroup
        - Quick VM create (az CLI): az vm create
        - Full VM create (Az cmdlets): New-AzVM
      - Networking:
        - Virtual Network: New-AzVirtualNetwork
        - Network Security Group: New-AzNetworkSecurityGroup, rules via New-AzNetworkSecurityRuleConfig + Set-AzNetworkSecurityGroup
        - Subnets: Get-AzVirtualNetwork, Add-AzVirtualNetworkSubnetConfig, Set-AzVirtualNetwork
        - Associate NSG to Subnet: Set-AzVirtualNetworkSubnetConfig + Set-AzVirtualNetwork
        - NSG preset rules (HTTP/SSH): New-AzNetworkSecurityRuleConfig + Set-AzNetworkSecurityGroup
      - Storage:
        - Storage Account: New-AzStorageAccount
      - IaC:
        - Export Resource Group template: Export-AzResourceGroup
        - Export single resource (az CLI): az resource export
        - Bicep helpers: az bicep decompile (ARM → Bicep), az bicep build (Bicep → ARM)
      - Monitoring:
        - Query metrics: Get-AzMetric

## Testing

Requires Pester v5 (installed in CurrentUser scope). Run from repository root:

```powershell
# Ensure Pester v5
if (-not (Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [version]'5.0.0' })) {
  Set-PSRepository PSGallery -InstallationPolicy Trusted
  Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module Pester -MinimumVersion 5.0.0

# Run all tests
Invoke-Pester -Path .\tests -CI
```

## Project Structure

- Root script: [PowershellToolbox.ps1](PowershellToolbox.ps1) — launches the menu-driven toolbox.
- Configuration: [config.yaml](config.yaml) — default values for prompts and operations.
- Modules: [modules/Common.ps1](modules/Common.ps1), [modules/FileTools.ps1](modules/FileTools.ps1), [modules/NetworkTools.ps1](modules/NetworkTools.ps1), [modules/SystemTools.ps1](modules/SystemTools.ps1), [modules/SecurityTools.ps1](modules/SecurityTools.ps1), [modules/HypervisorTools.ps1](modules/HypervisorTools.ps1), [modules/ProxmoxTools.ps1](modules/ProxmoxTools.ps1), [modules/VMwareTools.ps1](modules/VMwareTools.ps1), [modules/CloudTools.ps1](modules/CloudTools.ps1), [modules/AzureTools.ps1](modules/AzureTools.ps1).
 - Modules (continued): [modules/ActiveDirectoryTools.ps1](modules/ActiveDirectoryTools.ps1) — AD user/group/OU/computer management, reporting, ACL, FSMO.
- Tests: [tests](tests) — Pester v5 test suites for modules and menu dispatch.
- Logs: [logs](logs) — transcript and operational logs (ignored by Git).
- Output: [output](output) — generated manifests and exports (ignored by Git).
 - Templates: [templates](templates) — CSV examples for onboarding, offboarding, and bulk updates.

## Examples

### Active Directory
- Create user
  - Function: `AD-User-Create`
  - Inputs: Display Name, sAMAccountName, UPN, OU (defaults from `ADDefaults`), initial password
  - Under the hood: `New-ADUser` (via wrapper `AD-NewUserCmd`)

- Disable/Enable user
  - Functions: `AD-User-Disable`, `AD-User-Enable`
  - Under the hood: `Disable-ADAccount` / `Enable-ADAccount`

- Bulk-create users from CSV
  - Function: `AD-User-BulkCreateFromCsv`
  - CSV columns: `Name,SamAccountName,UPN,OU,Password`
  - Under the hood: `Import-Csv` + `New-ADUser`

- Create group and add member
  - Functions: `AD-Group-Create`, `AD-Group-AddMember`
  - Defaults: `DefaultGroupOU`, `DefaultGroupScope` from `ADDefaults`
  - Under the hood: `New-ADGroup`, `Add-ADGroupMember`

- Create OU
  - Function: `AD-OU-Create`
  - Under the hood: `New-ADOrganizationalUnit`

- Read/Modify ACL (example no-op)
  - Functions: `AD-ACL-Read`, `AD-ACL-Modify`
  - Under the hood: `Get-Acl`, `Set-Acl`

- View FSMO roles
  - Function: `AD-FSMO-View`
  - Under the hood: `Get-ADDomain`

Access: System Tools → Active Directory

#### Expanded Tools
- Search & Reporting
  - Search objects in OU: `AD-Search-ObjectsInOU` (users/groups/computers)
  - Password expiration (within N days): `AD-Report-PasswordExpiration`
  - Last logon times: `AD-Report-LastLogonTimes`
  - Inactive users/computers: `AD-Report-InactiveUsers`, `AD-Report-InactiveComputers`
- Organizational Units
  - Cleanup empty OUs (advisory): `AD-Cleanup-EmptyOUs`
  - Delegate permissions (simplified): `AD-OU-DelegatePermission`
- Groups
  - Audit membership snapshot: `AD-Group-AuditMembership`
- Service Accounts
  - Create gMSA (simplified): `AD-gMSA-Create`
  - Install/get gMSA: `AD-gMSA-Install`, `AD-gMSA-Get`
- Domain & Infrastructure
  - View trusts: `AD-Trusts-View`
  - Sites & Subnets (stubs): `AD-Sites-Create`
  - FSMO transfer: `AD-FSMO-Transfer`
  - FSMO seize: `AD-FSMO-Seize`
  - Replication monitoring (stub): `AD-Replication-Monitor`
  - DC health check: `AD-DC-HealthCheck`

- Automation & Bulk Operations
  - Onboarding from CSV (create, groups, home folder): `AD-Onboarding-FromCsv`
  - Offboarding from CSV (disable, move, remove groups): `AD-Offboarding-FromCsv`
  - Bulk update attributes from CSV: `AD-User-BulkUpdateFromCsv`
  - Set home folder: `AD-User-SetHomeFolder` (uses `ADDefaults.DefaultHomeFolderRoot`, `DefaultHomeDrive`)
  - Generate CSV templates: `AD-GenerateCsvTemplates` (writes to `templates/`)

Below are quick “recipes” showing typical workflows. Most tasks are interactive; the examples show the menu path and the command that gets executed under the hood.

### VMware
- vMotion a VM (host migration)
  - Menu: Hypervisor Tools → VMware Tools → VM Lifecycle Management → Migrate VM
  - Inputs: VM name `vm01`, Mode `host`, Target host `esxi02`
  - Command constructed:
    ```powershell
    govc vm.migrate -host esxi02 vm01
    ```

- Deploy VM from template
  - Menu: Hypervisor Tools → VMware Tools → VM Lifecycle Management → Deploy VM from template
  - Inputs: Template `tmpl01`, New name `web01`
  - Command constructed:
    ```powershell
    govc vm.clone -vm tmpl01 -on=false web01
    ```

- Expand a VM disk
  - Menu: Hypervisor Tools → VMware Tools → Storage & Datastore → Expand VM disk
  - Inputs: VMDK `/vmfs/volumes/datastore1/vms/web01/web01.vmdk`, New size `60G`
  - Command constructed:
    ```powershell
    vmkfstools -X 60G /vmfs/volumes/datastore1/vms/web01/web01.vmdk
    ```

- Enter maintenance mode
  - Menu: Hypervisor Tools → VMware Tools → Host & Cluster → Maintenance mode enter/exit
  - Command constructed (enter):
    ```powershell
    vim-cmd hostsvc/maintenance_mode_enter
    ```

- Modify VM hardware (CPU/RAM)
  - Menu: Hypervisor Tools → VMware Tools → VM Lifecycle Management → Modify VM hardware
  - Inputs: VM `web01`, Cores `4`, Memory MB `8192`
  - Command constructed:
    ```powershell
    govc vm.change -vm "web01" -c 4 -m 8192
    ```

#### vCenter/govc Setup
- Requirements:
  - vCenter accessible and `govc` installed on the SSH target or configured where commands execute.
  - `VmwareDefaults.GovcPath` set (e.g., `govc`).
- Typical PowerShell environment setup before running govc operations:
  ```powershell
  $env:GOVC_URL = "https://vc.example.local"
  $env:GOVC_USERNAME = "administrator@vsphere.local"
  $env:GOVC_PASSWORD = "<your_password>"
  # Optional:
  $env:GOVC_DATACENTER = "Datacenter"
  $env:GOVC_INSECURE = "1"   # allow self-signed TLS
  ```
- Notes:
  - Some VMware functions (migrate, deploy, roles/permissions, storage policies, SSO users, cluster settings, compliance) require vCenter and valid govc credentials.
  - ESXi-only operations (vim-cmd/esxcli/vmkfstools) do not require vCenter.

### Proxmox
- Create a new VM
  - Menu: Hypervisor Tools → Proxmox Tools → VM & Container Management → Create VM
  - Inputs: VMID `120`, Name `vm120`, ISO `local:iso/debian.iso`, NET `virtio,bridge=vmbr0`
  - Command constructed:
    ```powershell
    qm create 120 --name vm120 --ide2 local:iso/debian.iso,media=cdrom --net0 virtio,bridge=vmbr0
    ```

- Create a scheduled backup job
  - Menu: Hypervisor Tools → Proxmox Tools → Storage & Backup → Backup jobs → Create backup job
  - Inputs: ID `daily`, Start `01:00`, DOW `mon,tue,wed,thu,fri`, Storage `local`, Mode `snapshot`, VMIDs `100,101`
  - Command constructed:
    ```powershell
    pvesh create /cluster/backup --id daily --starttime 01:00 --storage local --mode snapshot --compress zstd --enabled 1 --node $(hostname) --vmid 100,101 --dow mon,tue,wed,thu,fri
    ```

- Add NFS storage
  - Menu: Hypervisor Tools → Proxmox Tools → Storage & Backup → Add storage
  - Inputs: Type `nfs`, ID `nfs1`, Server `nfs.example`, Export `/srv/nfs`
  - Command constructed:
    ```powershell
    pvesm add nfs nfs1 --server nfs.example --export /srv/nfs
    ```

### Azure
- Log in and set context
  - Menu: Cloud Environments → Azure Tools → Auth & Identity → Login
  - Uses defaults from `AzureDefaults` when pressing Enter.

- Create Service Principal + assign role
  - Menu: Cloud Environments → Azure Tools → Resource Provisioning → Create Service Principal
  - Inputs: DisplayName `sp-display`, Role `Contributor`, Scope `subscription|resourcegroup`
  - Commands:
    ```powershell
    New-AzADServicePrincipal -DisplayName sp-display
    New-AzRoleAssignment -ObjectId <sp.Id> -RoleDefinitionName Contributor -Scope /subscriptions/<subId>
    ```

- Create Resource Group
  - Menu: Cloud Environments → Azure Tools → Resource Provisioning → Create Resource Group
  - Command constructed:
    ```powershell
    New-AzResourceGroup -Name rg-lab -Location eastus
    ```

- Create a quick VM (az CLI)
  - Menu: Cloud Environments → Azure Tools → Resource Provisioning → Create Virtual Machine (quick)
  - Inputs: RG `rg-lab`, Name `vm01`, Image `UbuntuLTS`, Size `Standard_B2s`, Admin creds
  - Command constructed:
    ```powershell
    az vm create --resource-group "rg-lab" --name "vm01" --location "eastus" --image "UbuntuLTS" --size "Standard_B2s" --admin-username "adminuser" --admin-password "Adm1nPass!"
    ```

- Create Virtual Network
  - Menu: Cloud Environments → Azure Tools → Networking → Create Virtual Network
  - Command constructed:
    ```powershell
    New-AzVirtualNetwork -Name vnet1 -ResourceGroupName rg-lab -Location eastus -AddressPrefix 10.0.0.0/16
    ```

- Create Network Security Group (with a sample rule)
  - Menu: Cloud Environments → Azure Tools → Networking → Create Network Security Group
  - Commands executed:
    ```powershell
    New-AzNetworkSecurityGroup -Name nsg1 -ResourceGroupName rg-lab -Location eastus
    New-AzNetworkSecurityRuleConfig -Name AllowRDP -Protocol Tcp -Direction Inbound -Access Allow -Priority 1000 -SourceAddressPrefix '*' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange 3389
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup <nsg>
    ```

- Add Subnet to VNet
  - Menu: Cloud Environments → Azure Tools → Networking → Add Subnet to VNet
  - Commands executed:
    ```powershell
    Get-AzVirtualNetwork -Name vnet1 -ResourceGroupName rg-lab
    Add-AzVirtualNetworkSubnetConfig -Name subnet1 -AddressPrefix 10.0.1.0/24 -VirtualNetwork <vnet>
    Set-AzVirtualNetwork -VirtualNetwork <vnet>
    ```

- Associate NSG to Subnet
  - Menu: Cloud Environments → Azure Tools → Networking → Associate NSG to Subnet
  - Commands executed:
    ```powershell
    $vnet = Get-AzVirtualNetwork -Name vnet1 -ResourceGroupName rg-lab
    $nsg  = Get-AzNetworkSecurityGroup -Name nsg1 -ResourceGroupName rg-lab
    Set-AzVirtualNetworkSubnetConfig -Name subnet1 -VirtualNetwork $vnet -AddressPrefix 10.0.1.0/24 -NetworkSecurityGroup $nsg
    Set-AzVirtualNetwork -VirtualNetwork $vnet
    ```

- Add NSG preset rule (SSH)
  - Menu: Cloud Environments → Azure Tools → Networking → Add NSG preset rule (HTTP/SSH)
  - Commands executed:
    ```powershell
    $nsg = Get-AzNetworkSecurityGroup -Name nsg1 -ResourceGroupName rg-lab
    $rule = New-AzNetworkSecurityRuleConfig -Name AllowSSH -Protocol Tcp -Direction Inbound -Access Allow -Priority 1000 -SourceAddressPrefix '*' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange 22
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
    ```

- Add NSG preset rule (HTTP)
  - Menu: Cloud Environments → Azure Tools → Networking → Add NSG preset rule (HTTP/SSH)
  - Commands executed:
    ```powershell
    $nsg = Get-AzNetworkSecurityGroup -Name nsg1 -ResourceGroupName rg-lab
    $rule = New-AzNetworkSecurityRuleConfig -Name AllowHTTP -Protocol Tcp -Direction Inbound -Access Allow -Priority 1000 -SourceAddressPrefix '*' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange 80
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
    ```

- Create Storage Account
  - Menu: Cloud Environments → Azure Tools → Storage → Create Storage Account
  - Command constructed:
    ```powershell
    New-AzStorageAccount -Name stlab -ResourceGroupName rg-lab -Location eastus -SkuName Standard_LRS -Kind StorageV2
    ```

- Export Resource Group template
  - Menu: Cloud Environments → Azure Tools → IaC (Export Template)
  - Command constructed:
    ```powershell
    Export-AzResourceGroup -ResourceGroupName rg-lab -Path .\output\rg_template.json
    ```

- Export single resource (az CLI)
  - Menu: Cloud Environments → Azure Tools → IaC → Export single resource
  - Command constructed:
    ```powershell
    az resource export --resource-group "rg-lab" --name "vnet1" --resource-type "Microsoft.Network/virtualNetworks" --output json > .\output\vnet1.json
    ```

- Bicep: Decompile ARM JSON → Bicep
  - Menu: Cloud Environments → Azure Tools → IaC → Bicep: Decompile ARM JSON → Bicep
  - Command constructed:
    ```powershell
    az bicep decompile --file .\arm.json > .\main.bicep
    ```

- Bicep: Build Bicep → ARM JSON
  - Menu: Cloud Environments → Azure Tools → IaC → Bicep: Build Bicep → ARM JSON
  - Command constructed:
    ```powershell
    az bicep build --file .\main.bicep --outfile .\arm.json
    ```

- Create Virtual Machine (full via Az)
  - Menu: Cloud Environments → Azure Tools → Full VM Creation (Az)
  - Command constructed:
    ```powershell
    New-AzVM -Name vm02 -ResourceGroupName rg-lab -Location eastus -ImageName UbuntuLTS -Size Standard_B2s -Credential (Get-Credential)
    ```
- Create a new VM
  - Menu: Hypervisor Tools → Proxmox Tools → VM & Container Management → Create VM
  - Inputs: VMID `120`, Name `vm120`, ISO `local:iso/debian.iso`, NET `virtio,bridge=vmbr0`
  - Command constructed:
    ```powershell
    qm create 120 --name vm120 --ide2 local:iso/debian.iso,media=cdrom --net0 virtio,bridge=vmbr0
    ```

- Create a scheduled backup job
  - Menu: Hypervisor Tools → Proxmox Tools → Storage & Backup → Backup jobs → Create backup job
  - Inputs: ID `daily`, Start `01:00`, DOW `mon,tue,wed,thu,fri`, Storage `local`, Mode `snapshot`, VMIDs `100,101`
  - Command constructed:
    ```powershell
    pvesh create /cluster/backup --id daily --starttime 01:00 --storage local --mode snapshot --compress zstd --enabled 1 --node $(hostname) --vmid 100,101 --dow mon,tue,wed,thu,fri
    ```

- Add NFS storage
  - Menu: Hypervisor Tools → Proxmox Tools → Storage & Backup → Add storage
  - Inputs: Type `nfs`, ID `nfs1`, Server `nfs.example`, Export `/srv/nfs`
  - Command constructed:
    ```powershell
    pvesm add nfs nfs1 --server nfs.example --export /srv/nfs
    ```

### Network
- Set a static IPv4 address
  - Menu: Network Tools → Adapter & IP → Set IPv4 static address
  - Example values: Interface `Ethernet`, IP `192.168.1.20`, Prefix `24`, Gateway `192.168.1.1`

- Map a network drive
  - Menu: Network Tools → Shares & Drives → Map network drive
  - Example values: Drive `Z`, UNC `\\server\share`

- Start a TCP listener
  - Menu: Network Tools → Listeners → Start TCP listener
  - Example values: Bind `127.0.0.1`, Port `9001`

- Upload a file via SFTP
  - Menu: Network Tools → Transfers → SFTP upload
  - Example values: Local `C:\data\a.txt`, Remote `sftp.host:/upload`

### File Management
- Move a file/folder
  - Menu: File Management Tools → Copy, Move & Compress → Move file/folder
  - Example values: Source `C:\data\a.txt`, Destination `C:\dest\a.txt`

- Compute folder hashes and manifest
  - Menu: File Management Tools → Hashing → Compute hash
  - Notes: When `OutputSettings.WriteHashManifest` is enabled, per-file hashes are written under `output/`.

### System
- Restart a service
  - Menu: System Tools → Services → Restart a service
  - Example values: Service name `Spooler`

- Set a registry value
  - Menu: System Tools → Registry → Set value
  - Example values: Hive `HKCU`, Path `SOFTWARE\MyApp`, Name `Setting`, Value `456`

### Security
- List local Administrators
  - Menu: Security Tools → List local Administrators group members

- Check Windows Defender & Firewall
  - Menu: Security Tools → Defender status / Firewall status

## Notes

- Elevation: Network changes (IP/DNS/DHCP/routes), shares, and some service actions may require Administrator.
- External tools:
  - `ssh`, `plink` used for hypervisors; ensure they are in PATH or set `PlinkPath`.
  - `tar`, `7z` optional for compression; ZIP uses built-in `Compress-Archive`.
  - `psftp.exe` (PuTTY) and `ftp.exe` for transfers; set `PSFTPPath` if psftp is not in PATH.
- Safety: Interactive functions ask for confirmation before making changes.

### UI
- The toolbox shows a stylized ASCII PowerShell start screen on launch.

### Logging and Output Behavior
- When enabled, actions run under a transcript and write logs to `logs/toolbox.log`.
- Selected outputs are saved to `output/` for easier auditing.
 - Destructive operations (delete trust/group/OU/computer/user) prompt for confirmation and support `-WhatIf`/`-Confirm` where applicable.
