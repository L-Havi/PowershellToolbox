# Pester tests for SystemTools.ps1 (mocking service changes)
$ErrorActionPreference = 'Stop'

describe 'Service operations' {
    BeforeEach {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $systemPath = Join-Path $root 'modules\SystemTools.ps1'
        . "$commonPath"; . "$systemPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }

    It 'starts a service by name' {
        Mock -CommandName Read-Host -MockWith { 'Spooler' }
        Mock -CommandName Start-Service -MockWith {}
        Mock -CommandName Get-Service -MockWith { [pscustomobject]@{ Status='Running' } }
        Start-ServiceInteractive
        Assert-MockCalled Start-Service -Times 1 -ParameterFilter { $Name -eq 'Spooler' }
    }

    It 'disables service startup' {
        Mock -CommandName Read-Host -MockWith { 'Spooler' }
        Mock -CommandName Set-Service -MockWith {}
        Mock -CommandName Get-CimInstance -MockWith { [pscustomobject]@{ StartMode='Disabled' } }
        Disable-ServiceStartup
        Assert-MockCalled Set-Service -Times 1 -ParameterFilter { $Name -eq 'Spooler' -and $StartupType -eq 'Disabled' }
    }

    It 'enables service startup (automatic by default)' {
        $answers = @('Spooler','')
        Mock -CommandName Read-Host -MockWith { $script:answersSvc.Dequeue() } | Out-Null
        $script:answersSvc = [System.Collections.Queue]::new()
        $answers | ForEach-Object { [void]$script:answersSvc.Enqueue($_) }

        Mock -CommandName Set-Service -MockWith {}
        Mock -CommandName Get-CimInstance -MockWith { [pscustomobject]@{ StartMode='Auto' } }
        Enable-ServiceStartup
        Assert-MockCalled Set-Service -Times 1 -ParameterFilter { $Name -eq 'Spooler' -and $StartupType -eq 'Automatic' }
    }
}

describe 'Other system views' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $systemPath = Join-Path $root 'modules\SystemTools.ps1'
        . "$commonPath"; . "$systemPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'restarts a service by name' {
        Mock -CommandName Read-Host -MockWith { 'Spooler' }
        Mock -CommandName Restart-Service -MockWith {}
        Mock -CommandName Get-Service -MockWith { [pscustomobject]@{ Status='Running' } }
        { Restart-ServiceInteractive } | Should -Not -Throw
        Assert-MockCalled Restart-Service -Times 1 -ParameterFilter { $Name -eq 'Spooler' }
    }
    It 'lists all services without throwing' {
        Mock -CommandName Get-CimInstance -MockWith { @([pscustomobject]@{ Name='Spooler'; DisplayName='Print Spooler'; State='Running'; StartMode='Auto' }) }
        { List-AllServices } | Should -Not -Throw
        Assert-MockCalled Get-CimInstance -Times 1
    }
}

describe 'Process management' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $systemPath = Join-Path $root 'modules\SystemTools.ps1'
        . "$commonPath"; . "$systemPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'lists processes with filter without throwing' {
        Mock -CommandName Read-Host -MockWith { '' }
        Mock -CommandName Get-Process -MockWith { @([pscustomobject]@{ Name='notepad'; Id=123; CPU=1.2; WorkingSet=100MB },[pscustomobject]@{ Name='spooler'; Id=456; CPU=0.5; WorkingSet=50MB }) }
        { List-ProcessesInteractive } | Should -Not -Throw
        Assert-MockCalled Get-Process -Times 1
    }
    It 'starts a process with arguments after confirmation' {
        $answers = @('notepad.exe','-n','y')
        Mock -CommandName Read-Host -MockWith { $script:ansProcS.Dequeue() } | Out-Null
        $script:ansProcS = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansProcS.Enqueue($_) }
        Mock -CommandName Start-Process -MockWith {}
        { Start-ProcessInteractive } | Should -Not -Throw
        Assert-MockCalled Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'notepad.exe' -and $ArgumentList -eq '-n' }
    }
    It 'stops a process by name after confirmation' {
        $answers = @('notepad','y')
        Mock -CommandName Read-Host -MockWith { $script:ansProcX.Dequeue() } | Out-Null
        $script:ansProcX = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansProcX.Enqueue($_) }
        Mock -CommandName Stop-Process -MockWith {}
        { Stop-ProcessInteractive } | Should -Not -Throw
        Assert-MockCalled Stop-Process -Times 1 -ParameterFilter { $Name -eq 'notepad' }
    }
    It 'stops a process by PID after confirmation' {
        $answers = @('1234','y')
        Mock -CommandName Read-Host -MockWith { $script:ansProcPID.Dequeue() } | Out-Null
        $script:ansProcPID = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansProcPID.Enqueue($_) }
        Mock -CommandName Stop-Process -MockWith {}
        { Stop-ProcessInteractive } | Should -Not -Throw
        Assert-MockCalled Stop-Process -Times 1 -ParameterFilter { $Id -eq 1234 }
    }
}

describe 'Registry operations' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $systemPath = Join-Path $root 'modules\SystemTools.ps1'
        . "$commonPath"; . "$systemPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'reads a registry value' {
        $answers = @('HKLM','SOFTWARE\\MyApp','Setting')
        Mock -CommandName Read-Host -MockWith { $script:ansRegR.Dequeue() } | Out-Null
        $script:ansRegR = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRegR.Enqueue($_) }
        $obj = New-Object psobject; $obj | Add-Member -NotePropertyName Setting -NotePropertyValue '123'
        Mock -CommandName Get-ItemProperty -MockWith { $obj }
        { Read-RegistryValueInteractive } | Should -Not -Throw
        Assert-MockCalled Get-ItemProperty -Times 1 -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\MyApp' -and $Name -eq 'Setting' }
    }
    It 'sets a registry value after confirmation' {
        $answers = @('HKCU','SOFTWARE\\MyApp','Setting','456','y')
        Mock -CommandName Read-Host -MockWith { $script:ansRegS.Dequeue() } | Out-Null
        $script:ansRegS = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansRegS.Enqueue($_) }
        Mock -CommandName Set-ItemProperty -MockWith {}
        { Set-RegistryValueInteractive } | Should -Not -Throw
        Assert-MockCalled Set-ItemProperty -Times 1 -ParameterFilter { $Path -eq 'HKCU:\SOFTWARE\MyApp' -and $Name -eq 'Setting' -and $Value -eq '456' }
    }
}
