# Pester tests for menu dispatch routing
$ErrorActionPreference = 'Stop'

Describe 'FileTools menu dispatch' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $fileToolsPath = Join-Path $root 'modules\FileTools.ps1'
        . "$commonPath"; . "$fileToolsPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'invokes Show-DirectoryListing via Comparisons submenu (1->4)' {
        # Navigate: Main [1] Comparisons & Listings -> Submenu [4] Directory listing -> Back -> Back
        $answers = @('1','4','0','0')
        Mock -CommandName Read-Host -MockWith { $script:ansFT.Dequeue() } | Out-Null
        $script:ansFT = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansFT.Enqueue($_) }
        Mock -CommandName Show-DirectoryListing -MockWith {}
        Show-FileToolsMenu
        Assert-MockCalled Show-DirectoryListing -Times 1
    }
}

Describe 'NetworkTools menu dispatch' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $networkPath = Join-Path $root 'modules\NetworkTools.ps1'
        . "$commonPath"; . "$networkPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'invokes Show-NetworkAdapterProperties via Adapter & IP submenu (2->1)' {
        # Navigate: Main [2] Adapter & IP -> Submenu [1] Show adapter properties -> Back -> Back
        $answers = @('2','1','0','0')
        Mock -CommandName Read-Host -MockWith { $script:ansNT1.Dequeue() } | Out-Null
        $script:ansNT1 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansNT1.Enqueue($_) }
        Mock -CommandName Show-NetworkAdapterProperties -MockWith {}
        Show-NetworkToolsMenu
        Assert-MockCalled Show-NetworkAdapterProperties -Times 1
    }
    It 'invokes Start-TcpListenerInteractive via Listeners submenu (7->1)' {
        # Navigate: Main [7] Listeners -> Submenu [1] Start TCP listener -> Back -> Back
        $answers = @('7','1','0','0')
        Mock -CommandName Read-Host -MockWith { $script:ansNT2.Dequeue() } | Out-Null
        $script:ansNT2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansNT2.Enqueue($_) }
        Mock -CommandName Start-TcpListenerInteractive -MockWith {}
        Show-NetworkToolsMenu
        Assert-MockCalled Start-TcpListenerInteractive -Times 1
    }
}

Describe 'SystemTools menu dispatch' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $systemPath = Join-Path $root 'modules\SystemTools.ps1'
        . "$commonPath"; . "$systemPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'invokes Start-ServiceInteractive via Services submenu (2->2)' {
        # Navigate: Main [2] Services -> Submenu [2] Start service -> Back -> Back
        $answers = @('2','2','0','0')
        Mock -CommandName Read-Host -MockWith { $script:ansST.Dequeue() } | Out-Null
        $script:ansST = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansST.Enqueue($_) }
        Mock -CommandName Start-ServiceInteractive -MockWith {}
        Show-SystemToolsMenu
        Assert-MockCalled Start-ServiceInteractive -Times 1
    }
}

Describe 'SecurityTools menu dispatch' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $securityPath = Join-Path $root 'modules\SecurityTools.ps1'
        . "$commonPath"; . "$securityPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'invokes List-LocalAdmins on option 1' {
        $answers = @('1','0')
        Mock -CommandName Read-Host -MockWith { $script:ansSec.Dequeue() } | Out-Null
        $script:ansSec = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansSec.Enqueue($_) }
        Mock -CommandName List-LocalAdmins -MockWith {}
        Show-SecurityToolsMenu
        Assert-MockCalled List-LocalAdmins -Times 1
    }
}

Describe 'HypervisorTools menu dispatch' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $hyperPath = Join-Path $root 'modules\HypervisorTools.ps1'
        $proxPath = Join-Path $root 'modules\ProxmoxTools.ps1'
        . "$commonPath"; . "$proxPath"; . "$hyperPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'invokes Show-ProxmoxToolsMenu on option 1' {
        $answers = @('1','0')
        Mock -CommandName Read-Host -MockWith { $script:ansHyp.Dequeue() } | Out-Null
        $script:ansHyp = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansHyp.Enqueue($_) }
        Mock -CommandName Show-ProxmoxToolsMenu -MockWith {}
        Show-HypervisorToolsMenu
        Assert-MockCalled Show-ProxmoxToolsMenu -Times 1
    }
}

Describe 'Main menu dispatch' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $loader = Join-Path $root 'PowershellToolbox.ps1'
        . "$loader"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'invokes Show-FileToolsMenu on option 1' {
        $answers = @('1','0')
        Mock -CommandName Read-Host -MockWith { $script:ansMain1.Dequeue() } | Out-Null
        $script:ansMain1 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMain1.Enqueue($_) }
        Mock -CommandName Show-FileToolsMenu -MockWith {}
        Show-MainMenu
        Assert-MockCalled Show-FileToolsMenu -Times 1
    }
    It 'invokes Show-NetworkToolsMenu on option 2' {
        $answers = @('2','0')
        Mock -CommandName Read-Host -MockWith { $script:ansMain2.Dequeue() } | Out-Null
        $script:ansMain2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMain2.Enqueue($_) }
        Mock -CommandName Show-NetworkToolsMenu -MockWith {}
        Show-MainMenu
        Assert-MockCalled Show-NetworkToolsMenu -Times 1
    }
    It 'invokes Show-HypervisorToolsMenu on option 5' {
        $answers = @('5','0')
        Mock -CommandName Read-Host -MockWith { $script:ansMain5.Dequeue() } | Out-Null
        $script:ansMain5 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMain5.Enqueue($_) }
        Mock -CommandName Show-HypervisorToolsMenu -MockWith {}
        Show-MainMenu
        Assert-MockCalled Show-HypervisorToolsMenu -Times 1
    }
}
