# Pester tests for NetworkTools.ps1 (mocking system changes)
$ErrorActionPreference = 'Stop'

describe 'ConvertTo-PrefixLength' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
    }
    It 'converts subnet masks to prefix lengths' {
        ConvertTo-PrefixLength -SubnetMask '255.255.255.0' | Should -Be 24
        ConvertTo-PrefixLength -SubnetMask '255.255.0.0' | Should -Be 16
        ConvertTo-PrefixLength -SubnetMask '255.255.255.248' | Should -Be 29
    }
}

describe 'Basic network viewers' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'pings a host using Test-Connection' {
        $answers = @('example.com','2')
        Mock -CommandName Read-Host -MockWith { $script:ansPing.Dequeue() } | Out-Null
        $script:ansPing = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansPing.Enqueue($_) }
        Mock -CommandName Test-Connection -MockWith { @([pscustomobject]@{ Address='example.com'; ResponseTime=10; Status='Success' }) }
        { Test-HostReachability } | Should -Not -Throw
        Assert-MockCalled Test-Connection -Times 1
    }
    It 'shows IP config using Get-NetIPConfiguration' {
        Mock -CommandName Get-NetIPConfiguration -MockWith { @([pscustomobject]@{ InterfaceAlias='Ethernet'; IPv4Address='192.168.1.10'; IPv4DefaultGateway='192.168.1.1'; DNSServer='1.1.1.1' }) }
        { Show-IPConfig } | Should -Not -Throw
        Assert-MockCalled Get-NetIPConfiguration -Times 1
    }
    It 'tests TCP port and displays status' {
        $answers = @('example.com','443')
        Mock -CommandName Read-Host -MockWith { $script:ansPort.Dequeue() } | Out-Null
        $script:ansPort = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansPort.Enqueue($_) }
        Mock -CommandName Test-NetConnection -MockWith { [pscustomobject]@{ TcpTestSucceeded=$true } }
        { Simple-PortCheck } | Should -Not -Throw
        Assert-MockCalled Test-NetConnection -Times 1 -ParameterFilter { $Port -eq 443 }
    }
}

describe 'Set-DnsServersInteractive' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Test-IsAdmin -MockWith { $true }
        Mock -CommandName Set-DnsClientServerAddress -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
        Mock -CommandName Show-Header -MockWith {}
    }
    It 'prompts for alias and servers, then sets DNS' {
        $answers = @('Ethernet','1.1.1.1,8.8.8.8','y')
        Mock -CommandName Read-Host -MockWith { $script:answersQueue.Dequeue() } | Out-Null
        $script:answersQueue = [System.Collections.Queue]::new()
        $answers | ForEach-Object { [void]$script:answersQueue.Enqueue($_) }

        Set-DnsServersInteractive
        Assert-MockCalled Set-DnsClientServerAddress -Times 1 -ParameterFilter { $InterfaceAlias -eq 'Ethernet' -and $ServerAddresses -contains '1.1.1.1' }
    }
}

describe 'Enable-DHCPInteractive' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Test-IsAdmin -MockWith { $true }
        Mock -CommandName Set-NetIPInterface -MockWith {}
        Mock -CommandName Remove-NetIPAddress -MockWith {}
        Mock -CommandName Set-DnsClientServerAddress -MockWith {}
        Mock -CommandName Get-NetIPAddress -MockWith { @() }
        Mock -CommandName Pause-Return -MockWith {}
        Mock -CommandName Show-Header -MockWith {}
    }
    It 'enables DHCP and clears manual addresses' {
        $answers = @('Ethernet','y')
        Mock -CommandName Read-Host -MockWith { $script:answersQueue2.Dequeue() } | Out-Null
        $script:answersQueue2 = [System.Collections.Queue]::new()
        $answers | ForEach-Object { [void]$script:answersQueue2.Enqueue($_) }

        Enable-DHCPInteractive
        Assert-MockCalled Set-NetIPInterface -Times 1 -ParameterFilter { $Dhcp -eq 'Enabled' -and $InterfaceAlias -eq 'Ethernet' }
    }
}

describe 'Map-NetworkDriveInteractive' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Get-PSDrive -MockWith { $null } -ParameterFilter { $Name -eq 'Z' }
        Mock -CommandName New-PSDrive -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
        Mock -CommandName Show-Header -MockWith {}
    }
    It 'maps drive without credentials' {
        $answers = @('Z','\\\\server\\share','n')
        Mock -CommandName Read-Host -MockWith { $script:answersQueue3.Dequeue() } | Out-Null
        $script:answersQueue3 = [System.Collections.Queue]::new()
        $answers | ForEach-Object { [void]$script:answersQueue3.Enqueue($_) }

        Mock -CommandName Get-Credential -MockWith { $null }
        Map-NetworkDriveInteractive
        Assert-MockCalled New-PSDrive -Times 1 -ParameterFilter { $Name -eq 'Z' -and $Root -eq '\\\\server\\share' }
    }
}

describe 'Routing management' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Test-IsAdmin -MockWith { $true }
        Mock -CommandName Pause-Return -MockWith {}
        Mock -CommandName Show-Header -MockWith {}
    }
    It 'shows routing table' {
        Mock -CommandName Get-NetRoute -MockWith { @([pscustomobject]@{ DestinationPrefix='0.0.0.0/0'; NextHop='192.168.1.1'; InterfaceAlias='Ethernet'; RouteMetric=10; Protocol='Local' }) }
        { Show-RoutingTable } | Should -Not -Throw
        Assert-MockCalled Get-NetRoute -Times 1
    }
    It 'adds a route using New-NetRoute' {
        $answers = @('10.20.0.0/16','192.168.1.1','Ethernet','10','y')
        Mock -CommandName Read-Host -MockWith { $script:ansAddRt.Dequeue() } | Out-Null
        $script:ansAddRt = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansAddRt.Enqueue($_) }
        Mock -CommandName New-NetRoute -MockWith {}
        { Add-RouteInteractive } | Should -Not -Throw
        Assert-MockCalled New-NetRoute -Times 1 -ParameterFilter { $DestinationPrefix -eq '10.20.0.0/16' -and $NextHop -eq '192.168.1.1' -and $InterfaceAlias -eq 'Ethernet' -and $RouteMetric -eq 10 }
    }
    It 'removes a route using Remove-NetRoute' {
        $answers = @('10.20.0.0/16','192.168.1.1','Ethernet','y')
        Mock -CommandName Read-Host -MockWith { $script:ansRemRt.Dequeue() } | Out-Null
        $script:ansRemRt = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRemRt.Enqueue($_) }
        Mock -CommandName Remove-NetRoute -MockWith {}
        { Remove-RouteInteractive } | Should -Not -Throw
        Assert-MockCalled Remove-NetRoute -Times 1 -ParameterFilter { $DestinationPrefix -eq '10.20.0.0/16' -and $NextHop -eq '192.168.1.1' -and $InterfaceAlias -eq 'Ethernet' }
    }
}

describe 'Remote connection launchers' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Pause-Return -MockWith {}
        Mock -CommandName Show-Header -MockWith {}
    }
    It 'starts SSH session via Start-Process' {
        $answers = @('host.example','user','2222')
        Mock -CommandName Read-Host -MockWith { $script:ansSSH.Dequeue() } | Out-Null
        $script:ansSSH = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSSH.Enqueue($_) }
        Mock -CommandName Start-Process -MockWith {}
        { Start-SSHSessionInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'ssh' -and $ArgumentList -contains '-p' -and $ArgumentList -contains '2222' -and ($ArgumentList -contains 'user@host.example') }
    }
    It 'starts Telnet session via Start-Process' {
        $answers = @('legacy.example','2323')
        Mock -CommandName Read-Host -MockWith { $script:ansTelnet.Dequeue() } | Out-Null
        $script:ansTelnet = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansTelnet.Enqueue($_) }
        Mock -CommandName Start-Process -MockWith {}
        { Start-TelnetSessionInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'telnet' -and $ArgumentList[0] -eq 'legacy.example' -and $ArgumentList[1] -eq '2323' }
    }
    It 'starts RDP session via Start-Process' {
        $answers = @('winhost','3390')
        Mock -CommandName Read-Host -MockWith { $script:ansRDP.Dequeue() } | Out-Null
        $script:ansRDP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRDP.Enqueue($_) }
        Mock -CommandName Start-Process -MockWith {}
        { Start-RDPSessionInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'mstsc.exe' -and ($ArgumentList -contains '/v:winhost:3390') }
    }
    It 'starts SFTP session via psftp with defaults' {
        $answers = @('sftp.host','user','2022')
        Mock -CommandName Read-Host -MockWith { $script:ansSFTP.Dequeue() } | Out-Null
        $script:ansSFTP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSFTP.Enqueue($_) }
        $cmdObj = [pscustomobject]@{ Source='psftp.exe' }
        Mock -CommandName Get-Command -MockWith { $cmdObj } -ParameterFilter { $Name -eq 'psftp' }
        Mock -CommandName Start-Process -MockWith {}
        { Start-SFTPSessionInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'psftp.exe' -and $ArgumentList -contains '-P' -and $ArgumentList -contains '2022' -and ($ArgumentList -contains 'user@sftp.host') }
    }
    It 'starts FTP session via ftp.exe' {
        $answers = @('ftp.host','2121')
        Mock -CommandName Read-Host -MockWith { $script:ansFTP.Dequeue() } | Out-Null
        $script:ansFTP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansFTP.Enqueue($_) }
        Mock -CommandName Start-Process -MockWith {}
        { Start-FTPSessionInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'ftp' }
    }
}

describe 'Scripted SFTP/FTP transfers' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Pause-Return -MockWith {}
        Mock -CommandName Show-Header -MockWith {}
    }
    It 'invokes psftp for SFTP upload with batch file' {
        $answers = @('sftp.host','user','22','C:\data\a.txt','/upload')
        Mock -CommandName Read-Host -MockWith { $script:ansSFTPU.Dequeue() } | Out-Null
        $script:ansSFTPU = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSFTPU.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' -and $PathType -eq 'Leaf' }
        $cmdObj = [pscustomobject]@{ Source='psftp.exe' }
        Mock -CommandName Get-Command -MockWith { $cmdObj } -ParameterFilter { $Name -eq 'psftp' }
        $sec = ConvertTo-SecureString 'pass' -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ('user',$sec)
        Mock -CommandName Get-Credential -MockWith { $cred }
        Mock -CommandName Set-Content -MockWith {}
            Mock -CommandName Start-Process -MockWith { $p = New-Object psobject; $p | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { return $null }; return $p }
        { Start-SFTPUploadInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'psftp.exe' -and ($ArgumentList -contains 'user@sftp.host') -and ($ArgumentList -contains '-b') }
    }
    It 'invokes psftp for SFTP download with batch file' {
        $answers = @('sftp.host','user','22','/upload','a.txt','C:\out\a.txt')
        Mock -CommandName Read-Host -MockWith { $script:ansSFTPD.Dequeue() } | Out-Null
        $script:ansSFTPD = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSFTPD.Enqueue($_) }
        $cmdObj = [pscustomobject]@{ Source='psftp.exe' }
        Mock -CommandName Get-Command -MockWith { $cmdObj } -ParameterFilter { $Name -eq 'psftp' }
        $sec = ConvertTo-SecureString 'pass' -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ('user',$sec)
        Mock -CommandName Get-Credential -MockWith { $cred }
        Mock -CommandName Set-Content -MockWith {}
        Mock -CommandName Start-Process -MockWith { $p = New-Object psobject; $p | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { return $null }; return $p }
        { Start-SFTPDownloadInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'psftp.exe' -and ($ArgumentList -contains 'user@sftp.host') -and ($ArgumentList -contains '-b') }
    }
    It 'invokes ftp.exe upload with script' {
        $answers = @('ftp.host','21','user','C:\data\a.txt','/upload')
        Mock -CommandName Read-Host -MockWith { $script:ansFTPU.Dequeue() } | Out-Null
        $script:ansFTPU = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansFTPU.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' -and $PathType -eq 'Leaf' }
        $sec = ConvertTo-SecureString 'pass' -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ('user',$sec)
        Mock -CommandName Get-Credential -MockWith { $cred }
        Mock -CommandName Set-Content -MockWith {}
            Mock -CommandName Start-Process -MockWith { $p = New-Object psobject; $p | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { return $null }; return $p }
        { Start-FTPUploadInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'ftp' -and ($ArgumentList[0] -like '-s:*') }
    }
    It 'invokes ftp.exe download with script' {
        $answers = @('ftp.host','21','user','/upload','a.txt','C:\out\a.txt')
        Mock -CommandName Read-Host -MockWith { $script:ansFTPD.Dequeue() } | Out-Null
        $script:ansFTPD = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansFTPD.Enqueue($_) }
        $sec = ConvertTo-SecureString 'pass' -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ('user',$sec)
        Mock -CommandName Get-Credential -MockWith { $cred }
        Mock -CommandName Set-Content -MockWith {}
        Mock -CommandName Start-Process -MockWith { $p = New-Object psobject; $p | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { return $null }; return $p }
        { Start-FTPDownloadInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'ftp' -and ($ArgumentList[0] -like '-s:*') }
    }
    It 'verifies SFTP upload by comparing SHA256 hashes' {
            $answers = @('sftp.host','user','22','C:\data\a.txt','/upload')
            Mock -CommandName Read-Host -MockWith { $script:ansSFTPU2.Dequeue() } | Out-Null
            $script:ansSFTPU2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSFTPU2.Enqueue($_) }
            Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' -and $PathType -eq 'Leaf' }
            $cmdObj = [pscustomobject]@{ Source='psftp.exe' }
            Mock -CommandName Get-Command -MockWith { $cmdObj } -ParameterFilter { $Name -eq 'psftp' }
            $sec = ConvertTo-SecureString 'pass' -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential ('user',$sec)
            Mock -CommandName Get-Credential -MockWith { $cred }
            Mock -CommandName Set-Content -MockWith {}
            Mock -CommandName Start-Process -MockWith { $p = New-Object psobject; $p | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { return $null }; return $p }
            Mock -CommandName Get-FileHash -MockWith { [pscustomobject]@{ Hash='ABC123' } }
            { Start-SFTPUploadInteractive } | Should -Not -Throw
            Assert-MockCalled Get-FileHash -Times 2
    }
    It 'verifies FTP upload by comparing SHA256 hashes' {
            $answers = @('ftp.host','21','user','C:\data\a.txt','/upload')
            Mock -CommandName Read-Host -MockWith { $script:ansFTPU2.Dequeue() } | Out-Null
            $script:ansFTPU2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansFTPU2.Enqueue($_) }
            Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' -and $PathType -eq 'Leaf' }
            $sec = ConvertTo-SecureString 'pass' -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential ('user',$sec)
            Mock -CommandName Get-Credential -MockWith { $cred }
            Mock -CommandName Set-Content -MockWith {}
            Mock -CommandName Start-Process -MockWith { $p = New-Object psobject; $p | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { return $null }; return $p }
            Mock -CommandName Get-FileHash -MockWith { [pscustomobject]@{ Hash='ABC123' } }
            { Start-FTPUploadInteractive } | Should -Not -Throw
            Assert-MockCalled Get-FileHash -Times 2
    }
}

describe 'TCP listener' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Pause-Return -MockWith {}
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Start-Sleep -MockWith {}
    }
    It 'creates a TcpListener and stops immediately with 0 seconds' {
        $answers = @('127.0.0.1','9001','0')
        Mock -CommandName Read-Host -MockWith { $script:ansListen.Dequeue() } | Out-Null
        $script:ansListen = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansListen.Enqueue($_) }
        $fake = New-Object psobject; $fake | Add-Member -MemberType ScriptMethod -Name Start -Value { return $null }; $fake | Add-Member -MemberType ScriptMethod -Name Stop -Value { return $null }
        Mock -CommandName New-TcpListenerWrapper -MockWith { $fake }
        { Start-TcpListenerInteractive } | Should -Not -Throw
        Assert-MockCalled New-TcpListenerWrapper -Times 1 -ParameterFilter { $BindAddress -eq '127.0.0.1' -and $Port -eq 9001 }
    }
}
describe 'Other network configuration' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"
        . "$networkPath"
        Mock -CommandName Test-IsAdmin -MockWith { $true }
        Mock -CommandName Pause-Return -MockWith {}
        Mock -CommandName Show-Header -MockWith {}
    }
    It 'sets IPv4 static with gateway' {
        $answers = @('Ethernet','192.168.1.20','255.255.255.0','192.168.1.1','y')
        Mock -CommandName Read-Host -MockWith { $script:ansIP.Dequeue() } | Out-Null
        $script:ansIP = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansIP.Enqueue($_) }
        Mock -CommandName Get-NetIPAddress -MockWith { @() }
        Mock -CommandName Remove-NetIPAddress -MockWith {}
        Mock -CommandName New-NetIPAddress -MockWith {}
        { Set-IPv4StaticInteractive } | Should -Not -Throw
        Assert-MockCalled New-NetIPAddress -Times 1 -ParameterFilter { $InterfaceAlias -eq 'Ethernet' -and $IPAddress -eq '192.168.1.20' -and $PrefixLength -eq 24 -and $DefaultGateway -eq '192.168.1.1' }
    }
    It 'sets DNS suffix' {
        $answers = @('Ethernet','example.local','y')
        Mock -CommandName Read-Host -MockWith { $script:ansSuf.Dequeue() } | Out-Null
        $script:ansSuf = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSuf.Enqueue($_) }
        Mock -CommandName Set-DnsClient -MockWith {}
        { Set-DnsSuffixInteractive } | Should -Not -Throw
        Assert-MockCalled Set-DnsClient -Times 1 -ParameterFilter { $InterfaceAlias -eq 'Ethernet' -and $ConnectionSpecificSuffix -eq 'example.local' }
    }
    It 'shows DHCP status' {
        Mock -CommandName Get-NetIPInterface -MockWith { @([pscustomobject]@{ InterfaceAlias='Ethernet'; Dhcp='Enabled'; ConnectionState='Connected' }) }
        Mock -CommandName Get-NetIPAddress -MockWith { @([pscustomobject]@{ InterfaceAlias='Ethernet'; IPAddress='192.168.1.10'; PrefixLength=24; PrefixOrigin='Dhcp' }) }
        { Show-DHCPStatus } | Should -Not -Throw
        Assert-MockCalled Get-NetIPInterface -Times 1
        Assert-MockCalled Get-NetIPAddress -Times 1
    }
    It 'cancels DHCP release and renew without executing' {
        $answers1 = @('Ethernet','n')
        Mock -CommandName Read-Host -MockWith { $script:ansRel.Dequeue() } | Out-Null
        $script:ansRel = [System.Collections.Queue]::new(); $answers1 | ForEach-Object { [void]$script:ansRel.Enqueue($_) }
        { Release-DHCPInteractive } | Should -Not -Throw

        $answers2 = @('Ethernet','n')
        Mock -CommandName Read-Host -MockWith { $script:ansRen.Dequeue() } | Out-Null
        $script:ansRen = [System.Collections.Queue]::new(); $answers2 | ForEach-Object { [void]$script:ansRen.Enqueue($_) }
        { Renew-DHCPInteractive } | Should -Not -Throw
    }
    It 'create SMB share when path exists and not present yet' {
        $answers = @('share1','C:\\data','y')
        Mock -CommandName Read-Host -MockWith { $script:ansShare.Dequeue() } | Out-Null
        $script:ansShare = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansShare.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $Path -eq 'C:\\data' }
        Mock -CommandName Get-SmbShare -MockWith { $null }
        Mock -CommandName New-SmbShare -MockWith {}
        { New-SMBShareInteractive } | Should -Not -Throw
        Assert-MockCalled New-SmbShare -Times 1 -ParameterFilter { $Name -eq 'share1' -and $Path -eq 'C:\\data' }
    }
    It 'remove SMB share when exists and confirmed' {
        $answers = @('share1','y')
        Mock -CommandName Read-Host -MockWith { $script:ansRmShare.Dequeue() } | Out-Null
        $script:ansRmShare = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRmShare.Enqueue($_) }
        Mock -CommandName Get-SmbShare -MockWith { [pscustomobject]@{ Name='share1' } }
        Mock -CommandName Remove-SmbShare -MockWith {}
        { Remove-SMBShareInteractive } | Should -Not -Throw
        Assert-MockCalled Remove-SmbShare -Times 1 -ParameterFilter { $Name -eq 'share1' }
    }
}
