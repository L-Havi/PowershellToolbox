# Pester tests for ActiveDirectoryTools.ps1
$ErrorActionPreference = 'Stop'

Describe 'ActiveDirectoryTools' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        . (Join-Path $root 'modules\Common.ps1')
        . (Join-Path $root 'modules\ActiveDirectoryTools.ps1')
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }

    It 'creates a user with defaults' {
        Mock -CommandName AD-NewUserCmd -MockWith {}
        Mock -CommandName Get-ADDefaults -MockWith { [pscustomobject]@{ DefaultUserOU='OU=Users,DC=domain,DC=local'; DefaultPassword='P@ssw0rd!' } }
        $answers = @('John Doe','jdoe','jdoe@domain.local','','')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-User-Create } | Should -Not -Throw
        Assert-MockCalled AD-NewUserCmd -Times 1 -ParameterFilter { $SamAccountName -eq 'jdoe' -and $Path -eq 'OU=Users,DC=domain,DC=local' }
    }

    It 'disables and enables a user' {
        Mock -CommandName AD-DisableUserCmd -MockWith {}
        Mock -CommandName AD-EnableUserCmd -MockWith {}
        $answers = @('jdoe','jdoe')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-User-Disable } | Should -Not -Throw
        { AD-User-Enable }  | Should -Not -Throw
        Assert-MockCalled AD-DisableUserCmd -Times 1 -ParameterFilter { $Identity -eq 'jdoe' }
        Assert-MockCalled AD-EnableUserCmd  -Times 1 -ParameterFilter { $Identity -eq 'jdoe' }
    }

    It 'bulk creates users from CSV' {
        Mock -CommandName AD-ImportCsvCmd -MockWith { @(@{Name='A';SamAccountName='a';UPN='a@domain.local';OU='';Password=''}, @{Name='B';SamAccountName='b';UPN='b@domain.local';OU='';Password=''}) }
        Mock -CommandName AD-NewUserCmd -MockWith {}
        Mock -CommandName Get-ADDefaults -MockWith { [pscustomobject]@{ DefaultUserOU='OU=Users,DC=domain,DC=local'; DefaultPassword='P@ssw0rd!' } }
        $answers = @('C:\list.csv')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-User-BulkCreateFromCsv } | Should -Not -Throw
        Assert-MockCalled AD-NewUserCmd -Times 2
    }

    It 'creates a group and adds a member' {
        Mock -CommandName AD-NewGroupCmd -MockWith {}
        Mock -CommandName AD-AddGroupMemberCmd -MockWith {}
        Mock -CommandName Get-ADDefaults -MockWith { [pscustomobject]@{ DefaultGroupOU='OU=Groups,DC=domain,DC=local'; DefaultGroupScope='Global' } }
        $answers = @('grp1','','','user1')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-Group-Create } | Should -Not -Throw
        Assert-MockCalled AD-NewGroupCmd -Times 1 -ParameterFilter { $Name -eq 'grp1' -and $Path -eq 'OU=Groups,DC=domain,DC=local' -and $GroupScope -eq 'Global' }
    }

    It 'creates an OU' {
        Mock -CommandName AD-NewOUCmd -MockWith {}
        $answers = @('OU=Lab','DC=domain,DC=local')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-OU-Create } | Should -Not -Throw
        Assert-MockCalled AD-NewOUCmd -Times 1
    }

    It 'reads ACL for an ADsPath' {
        Mock -CommandName AD-GetAclCmd -MockWith { [pscustomobject]@{ Access = @(1,2,3) } }
        $answers = @('AD:\\CN=User,OU=Lab,DC=domain,DC=local')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-ACL-Read } | Should -Not -Throw
        Assert-MockCalled AD-GetAclCmd -Times 1
    }

    It 'views FSMO roles' {
        Mock -CommandName AD-GetADDomainCmd -MockWith { [pscustomobject]@{ Name='domain.local'; PDCEmulator='dc1.domain.local' } }
        { AD-FSMO-View } | Should -Not -Throw
        Assert-MockCalled AD-GetADDomainCmd -Times 1
    }

    It 'checks group membership' {
        Mock -CommandName AD-GetGroupMemberCmd -MockWith { @(@{ SamAccountName='jdoe' }) }
        $answers = @('jdoe','Domain Admins')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-User-CheckGroupMembership } | Should -Not -Throw
        Assert-MockCalled AD-GetGroupMemberCmd -Times 1 -ParameterFilter { $Identity -eq 'Domain Admins' -and $Recursive -eq $true }
    }

    It 'shows user login status' {
        Mock -CommandName AD-GetUserCmd -MockWith { [pscustomobject]@{ Enabled=$true; LockedOut=$false } }
        $answers = @('jdoe')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-User-LoginStatus } | Should -Not -Throw
        Assert-MockCalled AD-GetUserCmd -Times 1
    }

    It 'audits permissions and writes CSV' {
        Mock -CommandName AD-GetAclCmd -MockWith { [pscustomobject]@{ Access = @(@{ IdentityReference='DOMAIN\\Admin'; FileSystemRights='FullControl' }) } }
        Mock -CommandName Out-File -MockWith {}
        $answers = @('AD:\\CN=User,OU=Lab,DC=domain,DC=local','.\\output\\acl.csv')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-Audit-Permissions } | Should -Not -Throw
        Assert-MockCalled AD-GetAclCmd -Times 1
    }

    It 'installs and gets gMSA' {
        Mock -CommandName AD-InstallServiceAccountCmd -MockWith {}
        Mock -CommandName AD-GetServiceAccountCmd -MockWith { [pscustomobject]@{ Name='svc1$' } }
        $answers = @('svc1$','svc1$')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-gMSA-Install } | Should -Not -Throw
        { AD-gMSA-Get } | Should -Not -Throw
        Assert-MockCalled AD-InstallServiceAccountCmd -Times 1
        Assert-MockCalled AD-GetServiceAccountCmd -Times 1
    }

    It 'seizes FSMO role' {
        Mock -CommandName AD-MoveFsmoRoleCmd -MockWith {}
        $answers = @('RIDMaster','dc2.domain.local')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-FSMO-Seize } | Should -Not -Throw
        Assert-MockCalled AD-MoveFsmoRoleCmd -Times 1 -ParameterFilter { $OperationMasterRole -eq 'RIDMaster' -and $Identity -eq 'dc2.domain.local' }
    }

    It 'runs DC health check' {
        Mock -CommandName AD-GetADDomainControllerCmd -MockWith { @(1,2,3) }
        { AD-DC-HealthCheck } | Should -Not -Throw
        Assert-MockCalled AD-GetADDomainControllerCmd -Times 1
    }

    It 'onboards users from CSV and sets home folder' {
        Mock -CommandName AD-ImportCsvCmd -MockWith { @(@{ Name='A'; SamAccountName='a'; UPN='a@domain.local'; OU=''; Password=''; Groups='grp1;grp2' }) }
        Mock -CommandName AD-NewUserCmd -MockWith {}
        Mock -CommandName AD-AddGroupMemberCmd -MockWith {}
        Mock -CommandName AD-SetUserCmd -MockWith {}
        Mock -CommandName Get-ADDefaults -MockWith { [pscustomobject]@{ DefaultUserOU='OU=Users,DC=domain,DC=local'; DefaultPassword='P@ssw0rd!'; DefaultHomeFolderRoot='\\\\fileserver\\homes'; DefaultHomeDrive='H:' } }
        $answers = @('C:\onboard.csv')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-Onboarding-FromCsv } | Should -Not -Throw
        Assert-MockCalled AD-NewUserCmd -Times 1
        Assert-MockCalled AD-AddGroupMemberCmd -Times 2
        Assert-MockCalled AD-SetUserCmd -Times 1 -ParameterFilter { $HomeDrive -eq 'H:' }
    }

    It 'offboards users from CSV (disables, moves, removes groups)' {
        Mock -CommandName AD-ImportCsvCmd -MockWith { @(@{ SamAccountName='a'; TargetOU='OU=Disabled,DC=domain,DC=local' }) }
        Mock -CommandName AD-DisableUserCmd -MockWith {}
        Mock -CommandName AD-MoveObjectCmd -MockWith {}
        Mock -CommandName AD-GetPrincipalGroupMembershipCmd -MockWith { @(@{ Name='grp1' }, @{ Name='grp2' }) }
        Mock -CommandName AD-RemoveGroupMemberCmd -MockWith {}
        Mock -CommandName Get-ADDefaults -MockWith { [pscustomobject]@{ DefaultUserOU='OU=Users,DC=domain,DC=local' } }
        $answers = @('C:\offboard.csv')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-Offboarding-FromCsv } | Should -Not -Throw
        Assert-MockCalled AD-DisableUserCmd -Times 1
        Assert-MockCalled AD-MoveObjectCmd -Times 1
        Assert-MockCalled AD-RemoveGroupMemberCmd -Times 2
    }

    It 'bulk updates user attributes from CSV' {
        Mock -CommandName AD-ImportCsvCmd -MockWith { @(@{ SamAccountName='a'; GivenName='A'; Surname='One'; Department='IT'; Manager='CN=Mgr,DC=domain,DC=local' }, @{ SamAccountName='b'; GivenName='B'; Surname='Two'; Department='HR'; Manager='CN=Mgr2,DC=domain,DC=local' }) }
        Mock -CommandName AD-SetUserCmd -MockWith {}
        $answers = @('C:\update.csv')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-User-BulkUpdateFromCsv } | Should -Not -Throw
        Assert-MockCalled AD-SetUserCmd -Times 2
    }

    It 'searches objects in OU (users)' {
        Mock -CommandName AD-GetUserCmd -MockWith { @(1,2) }
        $answers = @('OU=Lab,DC=domain,DC=local','user')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-Search-ObjectsInOU } | Should -Not -Throw
        Assert-MockCalled AD-GetUserCmd -Times 1 -ParameterFilter { $SearchBase -eq 'OU=Lab,DC=domain,DC=local' }
    }

    It 'reports upcoming password expirations' {
        Mock -CommandName AD-GetUserCmd -MockWith { @(@{ 'msDS-UserPasswordExpiryTimeComputed' = ([DateTime]::UtcNow.AddDays(3).ToFileTimeUtc()) }) }
        $answers = @('7')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-Report-PasswordExpiration } | Should -Not -Throw
        Assert-MockCalled AD-GetUserCmd -Times 1 -ParameterFilter { $Properties -eq 'msDS-UserPasswordExpiryTimeComputed' }
    }

    It 'reports inactive computers' {
        Mock -CommandName AD-GetComputerCmd -MockWith { @(@{ lastLogonTimestamp = ([DateTime]::UtcNow.AddDays(-90).ToFileTimeUtc()) }) }
        $answers = @('60')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-Report-InactiveComputers } | Should -Not -Throw
        Assert-MockCalled AD-GetComputerCmd -Times 1 -ParameterFilter { $Properties -eq 'lastLogonTimestamp' }
    }

    It 'delegates OU permission (no-op)' {
        Mock -CommandName AD-GetAclCmd -MockWith { [pscustomobject]@{ Access = @(1,2) } }
        Mock -CommandName AD-SetAclCmd -MockWith {}
        $answers = @('OU=Lab,DC=domain,DC=local','CN=Admins,DC=domain,DC=local')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-OU-DelegatePermission } | Should -Not -Throw
        Assert-MockCalled AD-SetAclCmd -Times 1
    }

    It 'transfers FSMO role (wrapper call)' {
        Mock -CommandName AD-MoveFsmoRoleCmd -MockWith {}
        $answers = @('RIDMaster','dc1.domain.local')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-FSMO-Transfer } | Should -Not -Throw
        Assert-MockCalled AD-MoveFsmoRoleCmd -Times 1 -ParameterFilter { $OperationMasterRole -eq 'RIDMaster' -and $Identity -eq 'dc1.domain.local' }
    }

    It 'monitors replication (stub wrapper)' {
        Mock -CommandName AD-GetReplicationPartnerMetadataCmd -MockWith {}
        $answers = @('dc1.domain.local')
        $q = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$q.Enqueue($_) }
        Mock -CommandName Read-Host -MockWith { $q.Dequeue() } | Out-Null
        { AD-Replication-Monitor } | Should -Not -Throw
        Assert-MockCalled AD-GetReplicationPartnerMetadataCmd -Times 1 -ParameterFilter { $Target -eq 'dc1.domain.local' }
    }
}
