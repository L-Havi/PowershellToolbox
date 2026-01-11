# Pester tests for Common.ps1
$ErrorActionPreference = 'Stop'

describe 'Get-ConfigSection' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        . "$commonPath"
    }
    It 'parses arbitrary key/value pairs from a section' {
        $temp = New-TemporaryFile
        Remove-Item $temp -Force
        $tempPath = [System.IO.Path]::ChangeExtension($temp.FullName, '.yaml')
        @(
            'NetworkDefaults:',
            '  InterfaceAlias: Ethernet',
            '  IPv4Address: 192.168.1.10',
            '  PrefixLength: 24',
            '  DefaultGateway: 192.168.1.1',
            '  DnsServers: 1.1.1.1,8.8.8.8',
            '  DnsSuffix: example.local',
            '',
            'ProxmoxDefaults:',
            '  Host: 10.0.0.1',
            '  User: root',
            '  SshMethod: plink',
            '  PlinkPath: C:\\plink.exe'
        ) | Set-Content -Path $tempPath -Encoding utf8

        $Global:LabConfigFile = $tempPath
        $sec = Get-ConfigSection -SectionName 'NetworkDefaults'
        $sec['InterfaceAlias'] | Should -Be 'Ethernet'
        $sec['IPv4Address'] | Should -Be '192.168.1.10'
        $sec['PrefixLength'] | Should -Be '24'
        $sec['DefaultGateway'] | Should -Be '192.168.1.1'
        $sec['DnsServers'] | Should -Be '1.1.1.1,8.8.8.8'
        $sec['DnsSuffix'] | Should -Be 'example.local'

        Remove-Item $tempPath -Force
    }
}
