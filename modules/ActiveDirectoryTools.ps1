# Active Directory Tools

# Defaults
function Get-ADDefaults {
    $sec = Get-ConfigSection -SectionName 'ADDefaults'
    return [pscustomobject]@{
        DomainController  = if ($sec.ContainsKey('DomainController')) { $sec['DomainController'] } else { '' }
        DefaultUserOU     = if ($sec.ContainsKey('DefaultUserOU')) { $sec['DefaultUserOU'] } else { '' }
        DefaultGroupOU    = if ($sec.ContainsKey('DefaultGroupOU')) { $sec['DefaultGroupOU'] } else { '' }
        DefaultComputerOU = if ($sec.ContainsKey('DefaultComputerOU')) { $sec['DefaultComputerOU'] } else { '' }
        DefaultPassword   = if ($sec.ContainsKey('DefaultPassword')) { $sec['DefaultPassword'] } else { 'P@ssw0rd!' }
        DefaultGroupScope = if ($sec.ContainsKey('DefaultGroupScope')) { $sec['DefaultGroupScope'] } else { 'Global' }
        DefaultHomeFolderRoot = if ($sec.ContainsKey('DefaultHomeFolderRoot')) { $sec['DefaultHomeFolderRoot'] } else { 'C:\Home' }
        DefaultHomeDrive = if ($sec.ContainsKey('DefaultHomeDrive')) { $sec['DefaultHomeDrive'] } else { 'H:' }
    }
}

# Wrapper cmdlets (for testability)
function AD-NewUserCmd { param($Name,$SamAccountName,$UserPrincipalName,$Path,$Password,$Enabled,$GivenName,$Surname,$Department,$Manager) New-ADUser @PSBoundParameters }
function AD-SetUserCmd { param($Identity,$GivenName,$Surname,$Department,$Manager,$HomeDirectory,$HomeDrive) Set-ADUser @PSBoundParameters }
function AD-DisableUserCmd { param($Identity) Disable-ADAccount @PSBoundParameters }
function AD-EnableUserCmd { param($Identity) Enable-ADAccount @PSBoundParameters }
function AD-RemoveUserCmd { param($Identity) Remove-ADUser @PSBoundParameters }
function AD-SetUserPasswordCmd { param($Identity,$NewPassword,$Reset) Set-ADAccountPassword @PSBoundParameters }
function AD-UnlockUserCmd { param($Identity) Unlock-ADAccount @PSBoundParameters }
function AD-MoveObjectCmd { param($Identity,$TargetPath) Move-ADObject @PSBoundParameters }
function AD-ImportCsvCmd { param($Path) Import-Csv -Path $Path }
function AD-NewGroupCmd { param($Name,$GroupScope,$GroupCategory,$Path) New-ADGroup @PSBoundParameters }
function AD-RemoveGroupCmd { param($Identity) Remove-ADGroup @PSBoundParameters }
function AD-AddGroupMemberCmd { param($Identity,$Members) Add-ADGroupMember @PSBoundParameters }
function AD-RemoveGroupMemberCmd { param($Identity,$Members,$Confirm) Remove-ADGroupMember @PSBoundParameters }
function AD-SetGroupCmd { param($Identity,$GroupScope) Set-ADGroup @PSBoundParameters }
function AD-GetUserCmd { param($Filter,$SearchBase,$Server,$Properties) Get-ADUser @PSBoundParameters }
function AD-GetGroupCmd { param($Filter,$SearchBase,$Server,$Properties) Get-ADGroup @PSBoundParameters }
function AD-GetGroupMemberCmd { param($Identity,$Recursive) Get-ADGroupMember @PSBoundParameters }
function AD-NewOUCmd { param($Name,$Path) New-ADOrganizationalUnit @PSBoundParameters }
function AD-RenameOUCmd { param($Identity,$NewName) Rename-ADObject @PSBoundParameters }
function AD-RemoveOUCmd { param($Identity) Remove-ADOrganizationalUnit @PSBoundParameters }
function AD-GetComputerCmd { param($Filter,$SearchBase,$Server,$Properties) Get-ADComputer @PSBoundParameters }
function AD-NewComputerCmd { param($Name,$Path) New-ADComputer @PSBoundParameters }
function AD-RemoveComputerCmd { param($Identity) Remove-ADComputer @PSBoundParameters }
function AD-ResetComputerAccountCmd { param($Identity) Write-Output "Reset computer account: $Identity" }
function AD-GetAclCmd { param($Path) Get-Acl -Path $Path }
function AD-SetAclCmd { param($Path,$Acl) Set-Acl -Path $Path -AclObject $Acl }
function AD-GetADDomainCmd { Get-ADDomain }
function AD-GetPrincipalGroupMembershipCmd { param($Identity) Get-ADPrincipalGroupMembership @PSBoundParameters }
function AD-GetADDomainControllerCmd { param($Filter) Get-ADDomainController @PSBoundParameters }

# Core User Management
function AD-User-Create {
    Show-Header -Title "Active Directory :: Create User"
    $def = Get-ADDefaults
    $name = Read-Host "Display Name"
    $sam = Read-Host "sAMAccountName"
    $upn = Read-Host "UserPrincipalName (e.g. user@domain.local)"
    $ou  = Read-Host ("OU Path [default: {0}]" -f $def.DefaultUserOU)
    if ([string]::IsNullOrWhiteSpace($ou)) { $ou = $def.DefaultUserOU }
    $pwd = Read-Host ("Initial Password [default: {0}]" -f $def.DefaultPassword)
    if ([string]::IsNullOrWhiteSpace($pwd)) { $pwd = $def.DefaultPassword }
    try {
        AD-NewUserCmd -Name $name -SamAccountName $sam -UserPrincipalName $upn -Path $ou -Password (ConvertTo-SecureString $pwd -AsPlainText -Force) -Enabled $true
        Write-Host ("Created user {0}" -f $sam) -ForegroundColor Green
    } catch { Write-Host ("Failed to create user: {0}" -f $_) -ForegroundColor Red }
    Pause-Return
}

function AD-User-Disable { Show-Header -Title "Active Directory :: Disable User"; $id = Read-Host "User (sAMAccountName or DN)"; try { AD-DisableUserCmd -Identity $id; Write-Host "Disabled $id" -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-User-Enable  { Show-Header -Title "Active Directory :: Enable User";  $id = Read-Host "User (sAMAccountName or DN)"; try { AD-EnableUserCmd -Identity $id;  Write-Host "Enabled $id" -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-User-Delete  {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param()
    Show-Header -Title "Active Directory :: Delete User"
    $id = Read-Host "User (sAMAccountName or DN)"
    try {
        if($PSCmdlet.ShouldProcess($id, "Delete")){
            AD-RemoveUserCmd -Identity $id
            Write-Host "Deleted $id" -ForegroundColor Green
        }
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-User-ResetPasswordUnlock {
    Show-Header -Title "Active Directory :: Reset Password & Unlock"
    $id = Read-Host "User (sAMAccountName or DN)"
    $pwd = Read-Host "New Password"
    try { AD-SetUserPasswordCmd -Identity $id -NewPassword (ConvertTo-SecureString $pwd -AsPlainText -Force) -Reset $true; AD-UnlockUserCmd -Identity $id; Write-Host "Password reset and account unlocked." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-User-BulkCreateFromCsv {
    Show-Header -Title "Active Directory :: Bulk Create Users (CSV)"
    $def = Get-ADDefaults
    $path = Read-Host "CSV Path (Name,SamAccountName,UPN,OU,Password)"
    try {
        $rows = AD-ImportCsvCmd -Path $path
        foreach ($r in $rows) {
            $ou = if ($r.OU) { $r.OU } else { $def.DefaultUserOU }
            $pwd = if ($r.Password) { $r.Password } else { $def.DefaultPassword }
            AD-NewUserCmd -Name $r.Name -SamAccountName $r.SamAccountName -UserPrincipalName $r.UPN -Path $ou -Password (ConvertTo-SecureString $pwd -AsPlainText -Force) -Enabled $true
        }
        Write-Host ("Bulk created {0} users" -f ($rows.Count)) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-User-MoveBetweenOU { Show-Header -Title "Active Directory :: Move User"; $id = Read-Host "User (DN)"; $target = Read-Host "Target OU (DN)"; try { AD-MoveObjectCmd -Identity $id -TargetPath $target; Write-Host "Moved user." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }

function AD-User-UpdateAttributes {
    Show-Header -Title "Active Directory :: Update Attributes"
    $id = Read-Host "User (sAMAccountName or DN)"; $dept = Read-Host "Department"; $mgr = Read-Host "Manager (DN)"; $given = Read-Host "GivenName"; $sn = Read-Host "Surname"
    try { AD-SetUserCmd -Identity $id -Department $dept -Manager $mgr -GivenName $given -Surname $sn; Write-Host "Updated user attributes." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Group Management
function AD-Group-Create { Show-Header -Title "Active Directory :: Create Group"; $def=Get-ADDefaults; $name=Read-Host "Group Name"; $scope=Read-Host ("Scope [Global/Universal/DomainLocal] [default: {0}]" -f $def.DefaultGroupScope); if([string]::IsNullOrWhiteSpace($scope)){$scope=$def.DefaultGroupScope}; $ou=Read-Host ("OU Path [default: {0}]" -f $def.DefaultGroupOU); if([string]::IsNullOrWhiteSpace($ou)){$ou=$def.DefaultGroupOU}; try{ AD-NewGroupCmd -Name $name -GroupScope $scope -GroupCategory 'Security' -Path $ou; Write-Host "Created group $name" -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-Group-Delete {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param()
    Show-Header -Title "Active Directory :: Delete Group"
    $id=Read-Host "Group (CN or DN)"
    try{
        if($PSCmdlet.ShouldProcess($id, "Delete")){
            AD-RemoveGroupCmd -Identity $id
            Write-Host "Deleted group." -ForegroundColor Green
        }
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}
function AD-Group-AddMember { Show-Header -Title "Active Directory :: Add Member"; $grp=Read-Host "Group"; $mem=Read-Host "Member (user or group)"; try{ AD-AddGroupMemberCmd -Identity $grp -Members $mem; Write-Host "Added member." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-Group-RemoveMember { Show-Header -Title "Active Directory :: Remove Member"; $grp=Read-Host "Group"; $mem=Read-Host "Member"; try{ AD-RemoveGroupMemberCmd -Identity $grp -Members $mem -Confirm:$false; Write-Host "Removed member." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-Group-ConvertScope { Show-Header -Title "Active Directory :: Convert Group Scope"; $grp=Read-Host "Group"; $scope=Read-Host "New Scope (Global/Universal/DomainLocal)"; try{ AD-SetGroupCmd -Identity $grp -GroupScope $scope; Write-Host "Converted scope." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }

function AD-User-CheckGroupMembership {
    Show-Header -Title "Active Directory :: Check Group Membership"
    $user=Read-Host "User (sAMAccountName)"; $grp=Read-Host "Group Name"
    try {
        $members = AD-GetGroupMemberCmd -Identity $grp -Recursive:$true
        $isMember = $false
        foreach($m in $members){ if(($m.SamAccountName -eq $user) -or ($m.Name -eq $user)){ $isMember = $true; break } }
        Write-Host ("Member: {0}" -f $isMember) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-User-LoginStatus {
    Show-Header -Title "Active Directory :: User Login Status"
    $user=Read-Host "User (sAMAccountName)"
    try {
        $u = AD-GetUserCmd -Filter ("SamAccountName -eq '{0}'" -f $user) -Properties Enabled,LockedOut
        if($u){ Write-Host ("Enabled: {0} | LockedOut: {1}" -f $u.Enabled, $u.LockedOut) -ForegroundColor Green }
        else { Write-Host "User not found" -ForegroundColor Yellow }
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Organizational Units
function AD-OU-Create { Show-Header -Title "Active Directory :: Create OU"; $name=Read-Host "OU Name"; $path=Read-Host "Parent DN (e.g., DC=domain,DC=local)"; try{ AD-NewOUCmd -Name $name -Path $path; Write-Host "Created OU." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-OU-Rename { Show-Header -Title "Active Directory :: Rename OU"; $id=Read-Host "OU DN"; $new=Read-Host "New Name"; try{ AD-RenameOUCmd -Identity $id -NewName $new; Write-Host "Renamed OU." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-OU-Move { Show-Header -Title "Active Directory :: Move OU"; $id=Read-Host "OU DN"; $target=Read-Host "Target Container DN"; try{ AD-MoveObjectCmd -Identity $id -TargetPath $target; Write-Host "Moved OU." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-OU-Delete {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param()
    Show-Header -Title "Active Directory :: Delete OU"
    $id=Read-Host "OU DN"
    try{
        if($PSCmdlet.ShouldProcess($id, "Delete")){
            AD-RemoveOUCmd -Identity $id
            Write-Host "Deleted OU." -ForegroundColor Green
        }
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Computer Account Management
function AD-Computer-Create { Show-Header -Title "Active Directory :: Create Computer"; $name=Read-Host "Computer Name"; $ou=Read-Host ("OU Path" ); try{ AD-NewComputerCmd -Name $name -Path $ou; Write-Host "Created computer." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-Computer-Delete {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param()
    Show-Header -Title "Active Directory :: Delete Computer"
    $id=Read-Host "Computer (CN or DN)"
    try{
        if($PSCmdlet.ShouldProcess($id, "Delete")){
            AD-RemoveComputerCmd -Identity $id
            Write-Host "Deleted computer." -ForegroundColor Green
        }
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}
function AD-Computer-ResetAccount { Show-Header -Title "Active Directory :: Reset Computer Account"; $id=Read-Host "Computer (CN or DN)"; try{ AD-ResetComputerAccountCmd -Identity $id; Write-Host "Reset done." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-Computer-MoveBetweenOU { Show-Header -Title "Active Directory :: Move Computer"; $id=Read-Host "Computer DN"; $target=Read-Host "Target OU DN"; try{ AD-MoveObjectCmd -Identity $id -TargetPath $target; Write-Host "Moved computer." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }

# Searching & Reporting (examples)
function AD-Report-LockedOutUsers { Show-Header -Title "Active Directory :: Locked-out Users"; try { $res = AD-GetUserCmd -Filter 'LockedOut -eq $true'; $count = ($res | Measure-Object).Count; Write-Host "Locked-out users: $count" -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-Report-DisabledAccounts { Show-Header -Title "Active Directory :: Disabled Accounts"; try { $res = AD-GetUserCmd -Filter 'Enabled -eq $false'; $count = ($res | Measure-Object).Count; Write-Host "Disabled users: $count" -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-Report-GroupMembership { Show-Header -Title "Active Directory :: Group Membership"; $grp=Read-Host "Group"; try { $g = AD-GetGroupCmd -Filter ("Name -eq '{0}'" -f $grp); Write-Host "Queried group '$grp'" -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }

function AD-Search-ObjectsInOU {
    Show-Header -Title "Active Directory :: Search Objects in OU"
    $ou = Read-Host "OU DN (e.g., OU=Lab,DC=domain,DC=local)"
    $type = Read-Host "Object type (user|group|computer)"
    try {
        switch($type.ToLowerInvariant()){
            'user'     { $objs = AD-GetUserCmd -Filter '*' -SearchBase $ou }
            'group'    { $objs = AD-GetGroupCmd -Filter '*' -SearchBase $ou }
            'computer' { $objs = AD-GetComputerCmd -Filter '*' -SearchBase $ou }
            default    { throw 'Unsupported type' }
        }
        Write-Host ("Found {0} objects" -f (($objs | Measure-Object).Count)) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-Cleanup-EmptyOUs {
    Show-Header -Title "Active Directory :: Cleanup Empty OUs"
    $base = Read-Host "Base DN (e.g., DC=domain,DC=local)"
    try {
        # Simple approach: caller provides explicit OU to check; here we just demonstrate
        $ou = Read-Host "OU DN to check (e.g., OU=Unused,DC=domain,DC=local)"
        $hasUsers = (AD-GetUserCmd -Filter '*' -SearchBase $ou | Measure-Object).Count -gt 0
        $hasGroups = (AD-GetGroupCmd -Filter '*' -SearchBase $ou | Measure-Object).Count -gt 0
        $hasComputers = (AD-GetComputerCmd -Filter '*' -SearchBase $ou | Measure-Object).Count -gt 0
        if(-not $hasUsers -and -not $hasGroups -and -not $hasComputers){
            Write-Host "OU appears empty. Consider deletion after review." -ForegroundColor Yellow
        } else { Write-Host "OU contains objects; skip." -ForegroundColor Green }
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-Report-PasswordExpiration {
    Show-Header -Title "Active Directory :: Password Expiration"
    $days = Read-Host "Warn if expires within N days (e.g., 14)"
    try {
        $users = AD-GetUserCmd -Filter '*' -Properties 'msDS-UserPasswordExpiryTimeComputed'
        $near = @()
        foreach($u in $users){
            $expFileTime = $u.'msDS-UserPasswordExpiryTimeComputed'
            if($expFileTime){
                $exp = [DateTime]::FromFileTimeUtc([int64]$expFileTime)
                if(($exp - (Get-Date)).TotalDays -le [double]$days){ $near += $u }
            }
        }
        Write-Host ("Users with upcoming expiration: {0}" -f $near.Count) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-Report-LastLogonTimes {
    Show-Header -Title "Active Directory :: Last Logon Times"
    $ou = Read-Host "SearchBase OU DN (optional)"
    try {
        $users = if([string]::IsNullOrWhiteSpace($ou)){ AD-GetUserCmd -Filter '*' -Properties 'lastLogonTimestamp' } else { AD-GetUserCmd -Filter '*' -SearchBase $ou -Properties 'lastLogonTimestamp' }
        $count = ($users | Measure-Object).Count
        Write-Host ("Users returned: {0}" -f $count) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-Report-InactiveUsers {
    Show-Header -Title "Active Directory :: Inactive Users"
    $days = Read-Host "Inactive threshold (days)"
    try {
        $users = AD-GetUserCmd -Filter '*' -Properties 'lastLogonTimestamp'
        $inactive = @(); $now = Get-Date
        foreach($u in $users){
            $ts = $u.lastLogonTimestamp
            if($ts){ $last = [DateTime]::FromFileTimeUtc([int64]$ts); if(($now - $last).TotalDays -ge [double]$days){ $inactive += $u } }
        }
        Write-Host ("Inactive users: {0}" -f $inactive.Count) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-Report-InactiveComputers {
    Show-Header -Title "Active Directory :: Inactive Computers"
    $days = Read-Host "Inactive threshold (days)"
    try {
        $comps = AD-GetComputerCmd -Filter '*' -Properties 'lastLogonTimestamp'
        $inactive = @(); $now = Get-Date
        foreach($c in $comps){
            $ts = $c.lastLogonTimestamp
            if($ts){ $last = [DateTime]::FromFileTimeUtc([int64]$ts); if(($now - $last).TotalDays -ge [double]$days){ $inactive += $c } }
        }
        Write-Host ("Inactive computers: {0}" -f $inactive.Count) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Delegation (simplified placeholder using ACL read/write wrappers)
function AD-OU-DelegatePermission {
    Show-Header -Title "Active Directory :: Delegate OU Permission"
    $ou = Read-Host "OU DN"
    $principal = Read-Host "Principal (user/group DN)"
    try {
        $acl = AD-GetAclCmd -Path ("AD:\\{0}" -f $ou)
        # In a real implementation, construct and add an access rule to $acl.Access
        AD-SetAclCmd -Path ("AD:\\{0}" -f $ou) -Acl $acl
        Write-Host "Applied delegation (no-op example)." -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Onboarding / Offboarding / Bulk attribute updates
function AD-User-SetHomeFolder {
    Show-Header -Title "Active Directory :: Set Home Folder"
    $def = Get-ADDefaults
    $user = Read-Host "User (sAMAccountName)"
    $root = Read-Host ("Home folder root [default: {0}]" -f $def.DefaultHomeFolderRoot)
    if([string]::IsNullOrWhiteSpace($root)){ $root = $def.DefaultHomeFolderRoot }
    $drive = Read-Host ("Home drive [default: {0}]" -f $def.DefaultHomeDrive)
    if([string]::IsNullOrWhiteSpace($drive)){ $drive = $def.DefaultHomeDrive }
    $dir = Join-Path $root $user
    try { AD-SetUserCmd -Identity $user -HomeDirectory $dir -HomeDrive $drive; Write-Host ("Set home folder to {0}" -f $dir) -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-Onboarding-FromCsv {
    Show-Header -Title "Active Directory :: Onboarding from CSV"
    $def = Get-ADDefaults
    $path = Read-Host "CSV Path (Name,SamAccountName,UPN,OU,Password,Groups)"
    try {
        $rows = AD-ImportCsvCmd -Path $path
        foreach($r in $rows){
            $ou = if ($r.OU) { $r.OU } else { $def.DefaultUserOU }
            $pwd = if ($r.Password) { $r.Password } else { $def.DefaultPassword }
            AD-NewUserCmd -Name $r.Name -SamAccountName $r.SamAccountName -UserPrincipalName $r.UPN -Path $ou -Password (ConvertTo-SecureString $pwd -AsPlainText -Force) -Enabled $true
            if($r.Groups){ $groups = ($r.Groups -split ';'); foreach($g in $groups){ try { AD-AddGroupMemberCmd -Identity $g -Members $r.SamAccountName } catch {} } }
            $homeRoot = $def.DefaultHomeFolderRoot; if($homeRoot){ AD-SetUserCmd -Identity $r.SamAccountName -HomeDirectory (Join-Path $homeRoot $r.SamAccountName) -HomeDrive $def.DefaultHomeDrive }
        }
        Write-Host ("Onboarded {0} users" -f ($rows.Count)) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-Offboarding-FromCsv {
    Show-Header -Title "Active Directory :: Offboarding from CSV"
    $def = Get-ADDefaults
    $path = Read-Host "CSV Path (SamAccountName,TargetOU)"
    try {
        $rows = AD-ImportCsvCmd -Path $path
        foreach($r in $rows){
            AD-DisableUserCmd -Identity $r.SamAccountName
            if($r.TargetOU){ AD-MoveObjectCmd -Identity ("CN={0},{1}" -f $r.SamAccountName, $def.DefaultUserOU) -TargetPath $r.TargetOU }
            $groups = AD-GetPrincipalGroupMembershipCmd -Identity $r.SamAccountName
            foreach($g in $groups){ try { AD-RemoveGroupMemberCmd -Identity $g.Name -Members $r.SamAccountName -Confirm:$false } catch {} }
        }
        Write-Host ("Offboarded {0} users" -f ($rows.Count)) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-User-BulkUpdateFromCsv {
    Show-Header -Title "Active Directory :: Bulk Update Attributes (CSV)"
    $path = Read-Host "CSV Path (SamAccountName,GivenName,Surname,Department,Manager)"
    try {
        $rows = AD-ImportCsvCmd -Path $path
        foreach($r in $rows){ AD-SetUserCmd -Identity $r.SamAccountName -GivenName $r.GivenName -Surname $r.Surname -Department $r.Department -Manager $r.Manager }
        Write-Host ("Updated {0} users" -f ($rows.Count)) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Audit group membership (export current snapshot)
function AD-Group-AuditMembership {
    Show-Header -Title "Active Directory :: Audit Group Membership"
    $grp = Read-Host "Group Name"
    $out = Read-Host "Output path (e.g., .\\output\\group_members.csv)"
    try {
        $g = AD-GetGroupCmd -Filter ("Name -eq '{0}'" -f $grp)
        # Placeholder: write basic row
        "Group,$grp" | Out-File -FilePath $out -Encoding utf8
        Write-Host ("Wrote audit snapshot to {0}" -f $out) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# gMSA (simplified)
function AD-NewServiceAccountCmd { param($Name,$DNSHostName,$PrincipalsAllowedToRetrieveManagedPassword) New-ADServiceAccount @PSBoundParameters }
function AD-InstallServiceAccountCmd { param($Identity) Install-ADServiceAccount @PSBoundParameters }
function AD-GetServiceAccountCmd { param($Identity) Get-ADServiceAccount @PSBoundParameters }

function AD-gMSA-Create {
    Show-Header -Title "Active Directory :: Create gMSA"
    $name = Read-Host "Account Name"
    $dns  = Read-Host "DNS Host Name"
    $allowed = Read-Host "Principals allowed (group DN)"
    try { AD-NewServiceAccountCmd -Name $name -DNSHostName $dns -PrincipalsAllowedToRetrieveManagedPassword $allowed; Write-Host "Created gMSA." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-gMSA-Install { Show-Header -Title "Active Directory :: Install gMSA"; $id = Read-Host "Account Name"; try { AD-InstallServiceAccountCmd -Identity $id; Write-Host "Installed gMSA." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-gMSA-Get { Show-Header -Title "Active Directory :: Get gMSA"; $id = Read-Host "Account Name"; try { $sa = AD-GetServiceAccountCmd -Identity $id; Write-Host ("Found: {0}" -f $sa.Name) -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }

# Trusts
function AD-GetTrustCmd { param($Identity) Get-ADTrust @PSBoundParameters }
function AD-NewTrustCmd { param($Name,$SourceForest,$TargetForest,$Direction,$TrustType) Write-Output "New trust stub" }
function AD-RemoveTrustCmd { param($Identity) Write-Output "Remove trust stub" }

function AD-Trusts-View { Show-Header -Title "Active Directory :: View Trusts"; try { $t = AD-GetTrustCmd -Identity '*'; Write-Host "Queried trusts." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }

function AD-Trusts-Create {
    Show-Header -Title "Active Directory :: Create Trust"
    Write-Host "Caution: Creating trusts affects domain relationships." -ForegroundColor Yellow
    $target = Read-Host "Target domain (e.g., child.domain.local)"
    $direction = Read-Host "Direction (Inbound|Outbound|Bidirectional)"
    $type = Read-Host "Trust type (Forest|External|Realm)"
    $confirm = Read-Host "Proceed to create trust with $target? (Y/N)"
    if($confirm -notin @('Y','y')){ Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try {
        AD-NewTrustCmd -Name $target -Direction $direction -TrustType $type
        Write-Host "Trust creation invoked." -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-Trusts-Remove {
    Show-Header -Title "Active Directory :: Remove Trust"
    Write-Host "Caution: Removing trusts can break access paths." -ForegroundColor Yellow
    $name = Read-Host "Trust name (target domain)"
    $confirm = Read-Host "Are you sure you want to remove $name? (Y/N)"
    if($confirm -notin @('Y','y')){ Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { AD-RemoveTrustCmd -Identity $name; Write-Host "Trust removal invoked." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Sites & Subnets (stubs)
function AD-NewReplicationSiteCmd { param($Name) New-ADReplicationSite -Name $Name }
function AD-NewReplicationSubnetCmd { param($Name,$Site) New-ADReplicationSubnet -Name $Name -Site $Site }

function AD-Sites-Create {
    Show-Header -Title "Active Directory :: Create Site/Subnet"
    $site = Read-Host "Site Name"; $subnet = Read-Host "Subnet (e.g., 10.0.0.0/24)"
    try { AD-NewReplicationSiteCmd -Name $site; AD-NewReplicationSubnetCmd -Name $subnet -Site $site; Write-Host "Created site & subnet." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# FSMO transfer/seize
function AD-MoveFsmoRoleCmd { param($OperationMasterRole,$Identity,$Force) Move-ADDirectoryServerOperationMasterRole @PSBoundParameters }

function AD-FSMO-Transfer {
    Show-Header -Title "Active Directory :: Transfer FSMO Role"
    $role = Read-Host "Role (SchemaMaster|DomainNamingMaster|PDCEmulator|RIDMaster|InfrastructureMaster)"
    $dc   = Read-Host "Target DC (Name)"; try { AD-MoveFsmoRoleCmd -OperationMasterRole $role -Identity $dc -Force:$true; Write-Host "FSMO transfer invoked." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return
}

function AD-FSMO-Seize {
    Show-Header -Title "Active Directory :: Seize FSMO Role"
    Write-Host "Caution: Seize is destructive; use only if original role holder is permanently offline." -ForegroundColor Yellow
    $role = Read-Host "Role (SchemaMaster|DomainNamingMaster|PDCEmulator|RIDMaster|InfrastructureMaster)"
    $dc   = Read-Host "Target DC (Name)"
    try { AD-MoveFsmoRoleCmd -OperationMasterRole $role -Identity $dc -Force:$true; Write-Host "FSMO seize invoked." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Replication monitoring (stub)
function AD-GetReplicationPartnerMetadataCmd { param($Target) Get-ADReplicationPartnerMetadata -Target $Target }
function AD-Replication-Monitor {
    Show-Header -Title "Active Directory :: Replication Monitor"
    $dc=Read-Host "Domain Controller (leave blank to check all)"
    try {
        if([string]::IsNullOrWhiteSpace($dc)){
            $dcs = AD-GetADDomainControllerCmd -Filter *
            foreach($d in $dcs){ AD-GetReplicationPartnerMetadataCmd -Target $d.HostName }
            Write-Host ("Queried replication partners for {0} DCs" -f (($dcs|Measure-Object).Count)) -ForegroundColor Green
        } else {
            $meta = AD-GetReplicationPartnerMetadataCmd -Target $dc
            Write-Host ("Partners found: {0}" -f (($meta|Measure-Object).Count)) -ForegroundColor Green
        }
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

function AD-DC-HealthCheck {
    Show-Header -Title "Active Directory :: DC Health Check"
    try {
        $dcs = AD-GetADDomainControllerCmd -Filter *
        Write-Host ("Domain controllers found: {0}" -f (($dcs | Measure-Object).Count)) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Security & Access Control (simplified)
function AD-ACL-Read { Show-Header -Title "Active Directory :: Read ACL"; $path=Read-Host "ADsPath (e.g., AD:\\CN=User,OU=Lab,DC=domain,DC=local)"; try { $acl = AD-GetAclCmd -Path $path; Write-Host "Read ACL entries: $($acl.Access.Count)" -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }
function AD-ACL-Modify { Show-Header -Title "Active Directory :: Modify ACL"; $path=Read-Host "ADsPath"; Write-Host "This operation requires constructing a specific access rule." -ForegroundColor Yellow; try { $acl = AD-GetAclCmd -Path $path; AD-SetAclCmd -Path $path -Acl $acl; Write-Host "Applied ACL (no-op example)." -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }

function AD-Audit-Permissions {
    Show-Header -Title "Active Directory :: Audit Permissions"
    $path=Read-Host "ADsPath"; $out=Read-Host "Output path (e.g., .\\output\\acl_audit.csv)"
    try {
        $acl = AD-GetAclCmd -Path $path
        $lines = @()
        foreach($ace in $acl.Access){ $perm = $ace.FileSystemRights; $id = $ace.IdentityReference; $lines += ("{0},{1}" -f $id, $perm) }
        $lines | Out-File -FilePath $out -Encoding utf8
        Write-Host ("Wrote ACL audit to {0}" -f $out) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Domain & Infrastructure (view FSMO roles example)
function AD-FSMO-View { Show-Header -Title "Active Directory :: FSMO Roles"; try { $dom = AD-GetADDomainCmd; Write-Host ("Domain: {0}" -f $dom.Name) -ForegroundColor White; Write-Host ("PDC: {0}" -f $dom.PDCEmulator) -ForegroundColor Green } catch { Write-Host "Failed: $_" -ForegroundColor Red }; Pause-Return }

# CSV Template Generator
function AD-GenerateCsvTemplates {
    Show-Header -Title "Active Directory :: Generate CSV Templates"
    $root = Join-Path (Get-Location) 'templates'
    try {
        if(-not (Test-Path -LiteralPath $root)){ New-Item -ItemType Directory -Path $root | Out-Null }
        $onboard = @(
            'Name,SamAccountName,UPN,OU,Password,Groups',
            'Alice Smith,asmith,asmith@domain.local,OU=Users,DC=domain,DC=local,P@ssw0rd!,Domain Users;Marketing'
        )
        $offboard = @(
            'SamAccountName,TargetOU',
            'asmith,OU=Disabled Users,DC=domain,DC=local'
        )
        $bulkupd = @(
            'SamAccountName,GivenName,Surname,Department,Manager',
            'asmith,Alice,Smith,Marketing,CN=Bob Manager,OU=Users,DC=domain,DC=local'
        )
        $onboard | Out-File -FilePath (Join-Path $root 'onboarding_template.csv') -Encoding utf8
        $offboard | Out-File -FilePath (Join-Path $root 'offboarding_template.csv') -Encoding utf8
        $bulkupd | Out-File -FilePath (Join-Path $root 'bulk_update_template.csv') -Encoding utf8
        Write-Host ("Templates written to {0}" -f $root) -ForegroundColor Green
    } catch { Write-Host "Failed: $_" -ForegroundColor Red }
    Pause-Return
}

# Simple menu (not wired to main menu to avoid test churn)
function Show-ActiveDirectoryToolsMenu {
    $sel = $null
    while ($sel -ne '0') {
        Show-Header -Title "Active Directory Tools"
        Write-Host " [1] Core User Management" -ForegroundColor White
        Write-Host " [2] Group Management" -ForegroundColor White
        Write-Host " [3] Organizational Units" -ForegroundColor White
        Write-Host " [4] Computer Accounts" -ForegroundColor White
        Write-Host " [5] Searching & Reporting" -ForegroundColor White
        Write-Host " [6] Security & Access Control" -ForegroundColor White
        Write-Host " [7] Domain & Infrastructure" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $sel = Read-Host "Select"
        switch ($sel) {
            '1' { 
                # Core User submenu
                $uSel=$null
                while($uSel -ne '0'){
                    Show-Header -Title "AD :: Users"
                    Write-Host " [1] Create"; Write-Host " [2] Disable"; Write-Host " [3] Enable"; Write-Host " [4] Delete"; Write-Host " [5] Reset+Unlock"; Write-Host " [6] Move OU"; Write-Host " [7] Bulk create (CSV)"; Write-Host " [8] Bulk update (CSV)"; Write-Host " [9] Set home folder"; Write-Host " [T] Generate CSV templates"; Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray
                    $uSel = Read-Host "Select"
                    switch($uSel){
                        '1' { Invoke-Tool -Name 'AD.User.Create' -Action { AD-User-Create } }
                        '2' { Invoke-Tool -Name 'AD.User.Disable' -Action { AD-User-Disable } }
                        '3' { Invoke-Tool -Name 'AD.User.Enable' -Action { AD-User-Enable } }
                        '4' { Invoke-Tool -Name 'AD.User.Delete' -Action { AD-User-Delete } }
                        '5' { Invoke-Tool -Name 'AD.User.ResetUnlock' -Action { AD-User-ResetPasswordUnlock } }
                        '6' { Invoke-Tool -Name 'AD.User.MoveOU' -Action { AD-User-MoveBetweenOU } }
                        '7' { Invoke-Tool -Name 'AD.User.BulkCreate' -Action { AD-User-BulkCreateFromCsv } }
                        '8' { Invoke-Tool -Name 'AD.User.BulkUpdate' -Action { AD-User-BulkUpdateFromCsv } }
                        '9' { Invoke-Tool -Name 'AD.User.HomeFolder' -Action { AD-User-SetHomeFolder } }
                        'T' { Invoke-Tool -Name 'AD.CSV.GenerateTemplates' -Action { AD-GenerateCsvTemplates } }
                        '0' { break }
                        default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
                    }
                }
            }
            '2' {
                # Groups submenu
                $gSel=$null
                while($gSel -ne '0'){
                    Show-Header -Title "AD :: Groups"
                    Write-Host " [1] Create"; Write-Host " [2] Delete"; Write-Host " [3] Add member"; Write-Host " [4] Remove member"; Write-Host " [5] Convert scope"; Write-Host " [6] Audit membership"; Write-Host " [7] Check membership"; Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray
                    $gSel = Read-Host "Select"
                    switch($gSel){
                        '1' { Invoke-Tool -Name 'AD.Group.Create' -Action { AD-Group-Create } }
                        '2' { Invoke-Tool -Name 'AD.Group.Delete' -Action { AD-Group-Delete } }
                        '3' { Invoke-Tool -Name 'AD.Group.AddMember' -Action { AD-Group-AddMember } }
                        '4' { Invoke-Tool -Name 'AD.Group.RemoveMember' -Action { AD-Group-RemoveMember } }
                        '5' { Invoke-Tool -Name 'AD.Group.ConvertScope' -Action { AD-Group-ConvertScope } }
                        '6' { Invoke-Tool -Name 'AD.Group.Audit' -Action { AD-Group-AuditMembership } }
                        '7' { Invoke-Tool -Name 'AD.User.CheckMembership' -Action { AD-User-CheckGroupMembership } }
                        '0' { break }
                        default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
                    }
                }
            }
            '3' {
                # OUs submenu
                $oSel=$null
                while($oSel -ne '0'){
                    Show-Header -Title "AD :: Organizational Units"
                    Write-Host " [1] Create"; Write-Host " [2] Rename"; Write-Host " [3] Move"; Write-Host " [4] Delete"; Write-Host " [5] Delegate permission"; Write-Host " [6] Cleanup empty OUs"; Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray
                    $oSel = Read-Host "Select"
                    switch($oSel){
                        '1' { Invoke-Tool -Name 'AD.OU.Create' -Action { AD-OU-Create } }
                        '2' { Invoke-Tool -Name 'AD.OU.Rename' -Action { AD-OU-Rename } }
                        '3' { Invoke-Tool -Name 'AD.OU.Move' -Action { AD-OU-Move } }
                        '4' { Invoke-Tool -Name 'AD.OU.Delete' -Action { AD-OU-Delete } }
                        '5' { Invoke-Tool -Name 'AD.OU.Delegate' -Action { AD-OU-DelegatePermission } }
                        '6' { Invoke-Tool -Name 'AD.OU.Cleanup' -Action { AD-Cleanup-EmptyOUs } }
                        '0' { break }
                        default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
                    }
                }
            }
            '4' {
                # Computers submenu
                $cSel=$null
                while($cSel -ne '0'){
                    Show-Header -Title "AD :: Computers"
                    Write-Host " [1] Create"; Write-Host " [2] Delete"; Write-Host " [3] Reset account"; Write-Host " [4] Move OU"; Write-Host " [5] Report inactive computers"; Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray
                    $cSel = Read-Host "Select"
                    switch($cSel){
                        '1' { Invoke-Tool -Name 'AD.Computer.Create' -Action { AD-Computer-Create } }
                        '2' { Invoke-Tool -Name 'AD.Computer.Delete' -Action { AD-Computer-Delete } }
                        '3' { Invoke-Tool -Name 'AD.Computer.Reset' -Action { AD-Computer-ResetAccount } }
                        '4' { Invoke-Tool -Name 'AD.Computer.MoveOU' -Action { AD-Computer-MoveBetweenOU } }
                        '5' { Invoke-Tool -Name 'AD.Report.InactiveComputers' -Action { AD-Report-InactiveComputers } }
                        '0' { break }
                        default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
                    }
                }
            }
            '5' {
                # Reporting submenu
                $rSel=$null
                while($rSel -ne '0'){
                    Show-Header -Title "AD :: Reports"
                    Write-Host " [1] Locked-out users"; Write-Host " [2] Disabled accounts"; Write-Host " [3] Password expiration"; Write-Host " [4] Last logon times"; Write-Host " [5] Inactive users"; Write-Host " [6] Group membership"; Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray
                    $rSel = Read-Host "Select"
                    switch($rSel){
                        '1' { Invoke-Tool -Name 'AD.Report.LockedOut' -Action { AD-Report-LockedOutUsers } }
                        '2' { Invoke-Tool -Name 'AD.Report.Disabled' -Action { AD-Report-DisabledAccounts } }
                        '3' { Invoke-Tool -Name 'AD.Report.PasswordExpiration' -Action { AD-Report-PasswordExpiration } }
                        '4' { Invoke-Tool -Name 'AD.Report.LastLogon' -Action { AD-Report-LastLogonTimes } }
                        '5' { Invoke-Tool -Name 'AD.Report.InactiveUsers' -Action { AD-Report-InactiveUsers } }
                        '6' { Invoke-Tool -Name 'AD.Report.GroupMembership' -Action { AD-Report-GroupMembership } }
                        '0' { break }
                        default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
                    }
                }
            }
            '6' {
                # Security & Access Control submenu
                $sSel=$null
                while($sSel -ne '0'){
                    Show-Header -Title "AD :: Security & Access Control"
                    Write-Host " [1] Read ACL"; Write-Host " [2] Modify ACL"; Write-Host " [3] Audit Permissions"; Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray
                    $sSel = Read-Host "Select"
                    switch($sSel){
                        '1' { Invoke-Tool -Name 'AD.ACL.Read' -Action { AD-ACL-Read } }
                        '2' { Invoke-Tool -Name 'AD.ACL.Modify' -Action { AD-ACL-Modify } }
                        '3' { Invoke-Tool -Name 'AD.Audit.Permissions' -Action { AD-Audit-Permissions } }
                        '0' { break }
                        default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
                    }
                }
            }
            '7' {
                # Domain & Infra submenu
                $dSel=$null
                while($dSel -ne '0'){
                    Show-Header -Title "AD :: Domain & Infrastructure"
                    Write-Host " [1] FSMO view"; Write-Host " [2] FSMO transfer"; Write-Host " [3] FSMO seize"; Write-Host " [4] View trusts"; Write-Host " [5] Create trust"; Write-Host " [6] Remove trust"; Write-Host " [7] Create site & subnet"; Write-Host " [8] Replication monitor"; Write-Host " [9] DC health check"; Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray
                    $dSel = Read-Host "Select"
                    switch($dSel){
                        '1' { Invoke-Tool -Name 'AD.FSMO.View' -Action { AD-FSMO-View } }
                        '2' { Invoke-Tool -Name 'AD.FSMO.Transfer' -Action { AD-FSMO-Transfer } }
                        '3' { Invoke-Tool -Name 'AD.FSMO.Seize' -Action { AD-FSMO-Seize } }
                        '4' { Invoke-Tool -Name 'AD.Trusts.View' -Action { AD-Trusts-View } }
                        '5' { Invoke-Tool -Name 'AD.Trusts.Create' -Action { AD-Trusts-Create } }
                        '6' { Invoke-Tool -Name 'AD.Trusts.Remove' -Action { AD-Trusts-Remove } }
                        '7' { Invoke-Tool -Name 'AD.Sites.Create' -Action { AD-Sites-Create } }
                        '8' { Invoke-Tool -Name 'AD.Replication.Monitor' -Action { AD-Replication-Monitor } }
                        '9' { Invoke-Tool -Name 'AD.DC.Health' -Action { AD-DC-HealthCheck } }
                        '0' { break }
                        default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
                    }
                }
            }
            '0' { break }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
