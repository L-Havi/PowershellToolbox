# Pester tests for SecurityTools.ps1
$ErrorActionPreference = 'Stop'

Describe 'SecurityTools' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $secPath = Join-Path $root 'modules\SecurityTools.ps1'
        . "$commonPath"
        . "$secPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }

    It 'lists local admins via Get-LocalGroupMember without throwing' {
        Mock -CommandName Get-LocalGroupMember -MockWith { @([pscustomobject]@{ Name='User1'; ObjectClass='User'; PrincipalSource='Local' }) }
        { List-LocalAdmins } | Should -Not -Throw
        Assert-MockCalled Get-LocalGroupMember -Times 1
    }

    It 'checks Defender status using Mp cmdlets' {
        Mock -CommandName Get-MpPreference -MockWith { @{ Dummy=1 } }
        Mock -CommandName Get-MpComputerStatus -MockWith { [pscustomobject]@{ RealTimeProtectionEnabled=$true; BehaviorMonitorEnabled=$true; IOAVProtectionEnabled=$true; IsTamperProtected=$true; AntivirusEnabled=$true; AntispywareEnabled=$true; LastQuickScanEndTime=(Get-Date); LastFullScanEndTime=(Get-Date).AddDays(-1); AMEngineVersion='1.2.3'; AVSignatureVersion='4.5.6' } }
        { Check-DefenderStatus } | Should -Not -Throw
        Assert-MockCalled Get-MpPreference -Times 1
        Assert-MockCalled Get-MpComputerStatus -Times 1
    }

    It 'checks firewall status using Get-NetFirewallProfile' {
        Mock -CommandName Get-NetFirewallProfile -MockWith { @([pscustomobject]@{ Name='Domain'; Enabled=$true; DefaultInboundAction='Block'; DefaultOutboundAction='Allow' }) }
        { Check-FirewallStatus } | Should -Not -Throw
        Assert-MockCalled Get-NetFirewallProfile -Times 1
    }
}
