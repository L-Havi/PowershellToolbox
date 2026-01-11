# Pester tests for FileTools.ps1 (mocking destructive changes)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

describe 'Remove-FilesOlderThan' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $fileToolsPath = Join-Path $root 'modules\FileTools.ps1'
        . "$commonPath"
        . "$fileToolsPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }

    It 'removes only files older than specified days after confirmation' {
        $answers = @('C:\\dummy','30','y')
        Mock -CommandName Read-Host -MockWith { $script:answersQ.Dequeue() } | Out-Null
        $script:answersQ = [System.Collections.Queue]::new()
        $answers | ForEach-Object { [void]$script:answersQ.Enqueue($_) }

        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $Path -eq 'C:\\dummy' }

        $oldDate = (Get-Date).AddDays(-40)
        $newDate = (Get-Date).AddDays(-5)
        $files = @(
            [pscustomobject]@{ FullName='C:\\dummy\\old1.txt'; LastWriteTime=$oldDate },
            [pscustomobject]@{ FullName='C:\\dummy\\old2.txt'; LastWriteTime=$oldDate },
            [pscustomobject]@{ FullName='C:\\dummy\\new.txt'; LastWriteTime=$newDate }
        )
        Mock -CommandName Get-ChildItem -MockWith { $files } -ParameterFilter { $Path -eq 'C:\\dummy' }
        Mock -CommandName Remove-Item -MockWith {}

        Remove-FilesOlderThan
        Assert-MockCalled Remove-Item -Times 2
    }
}

describe 'Compress-Folder (zip)' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $fileToolsPath = Join-Path $root 'modules\FileTools.ps1'
        . "$commonPath"
        . "$fileToolsPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'uses Compress-Archive when format is zip' {
        $answers = @('C:\\src','zip','C:\\out\\archive.zip')
        Mock -CommandName Read-Host -MockWith { $script:answersZip.Dequeue() } | Out-Null
        $script:answersZip = [System.Collections.Queue]::new()
        $answers | ForEach-Object { [void]$script:answersZip.Enqueue($_) }

        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $Path -eq 'C:\\src' }
        Mock -CommandName Compress-Archive -MockWith {}

        Compress-Folder
        Assert-MockCalled Compress-Archive -Times 1 -ParameterFilter { $DestinationPath -like 'C:\\out\\archive.zip' }
    }
}

describe 'Other FileTools operations' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $fileToolsPath = Join-Path $root 'modules\FileTools.ps1'
        . "$commonPath"
        . "$fileToolsPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'lists directory contents' {
        $answers = @('C:\\data')
        Mock -CommandName Read-Host -MockWith { $script:ansDir.Dequeue() } | Out-Null
        $script:ansDir = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansDir.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $Path -eq 'C:\\data' }
        Mock -CommandName Get-ChildItem -MockWith { @([pscustomobject]@{ Mode='-a---'; Name='file.txt'; Length=123; LastWriteTime=(Get-Date) }) }
        { Show-DirectoryListing } | Should -Not -Throw
        Assert-MockCalled Get-ChildItem -Times 1 -ParameterFilter { $Path -eq 'C:\\data' }
    }
    It 'creates a new file with content' {
        $answers = @('C:\\data\\note.txt','hello world')
        Mock -CommandName Read-Host -MockWith { $script:ansNew.Dequeue() } | Out-Null
        $script:ansNew = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansNew.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { param($Path) $norm = ($Path -replace "\\$", '') ; if ($norm -eq 'C:\\data') { $true } elseif ($norm -eq 'C:\\data\\note.txt') { $false } else { $false } }
        Mock -CommandName Set-Content -MockWith {}
        { Create-NewFile } | Should -Not -Throw
        Assert-MockCalled Set-Content -Times 1 -ParameterFilter { $Path -eq 'C:\\data\\note.txt' -and $Value -eq 'hello world' }
    }
    It 'deletes a file after confirmation' {
        $answers = @('C:\\data\\old.txt','y')
        Mock -CommandName Read-Host -MockWith { $script:ansDel.Dequeue() } | Out-Null
        $script:ansDel = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansDel.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $Path -eq 'C:\\data\\old.txt' }
        Mock -CommandName Remove-Item -MockWith {}
        { Delete-File } | Should -Not -Throw
        Assert-MockCalled Remove-Item -Times 1 -ParameterFilter { $Path -eq 'C:\\data\\old.txt' }
    }
}

describe 'Copy-ItemInteractive' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $fileToolsPath = Join-Path $root 'modules\FileTools.ps1'
        . "$commonPath"
        . "$fileToolsPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'copies a file to destination folder with overwrite' {
        $answers = @('C:\data\a.txt','C:\dest','y')
        Mock -CommandName Read-Host -MockWith { $script:ansCopy1.Dequeue() } | Out-Null
        $script:ansCopy1 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansCopy1.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\dest' -and $PathType -eq 'Container' }
        Mock -CommandName Copy-Item -MockWith {}
        { Copy-ItemInteractive } | Should -Not -Throw
        Assert-MockCalled Copy-Item -Times 1 -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' -and $Destination -eq 'C:\dest\a.txt' -and $Force }
    }
    It 'copies a folder recursively' {
        $answers = @('C:\data','C:\backup','n')
        Mock -CommandName Read-Host -MockWith { $script:ansCopy2.Dequeue() } | Out-Null
        $script:ansCopy2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansCopy2.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data' }
        Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $LiteralPath -eq 'C:\data' -and $PathType -eq 'Leaf' }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data' -and $PathType -eq 'Container' }
        Mock -CommandName Copy-Item -MockWith {}
        { Copy-ItemInteractive } | Should -Not -Throw
        Assert-MockCalled Copy-Item -Times 1 -ParameterFilter { $LiteralPath -eq 'C:\data' -and $Destination -eq 'C:\backup' -and $Recurse }
    }
}

describe 'Move-ItemInteractive' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $fileToolsPath = Join-Path $root 'modules\FileTools.ps1'
        . "$commonPath"
        . "$fileToolsPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'moves a file to destination folder with overwrite' {
        $answers = @('C:\data\a.txt','C:\dest','y')
        Mock -CommandName Read-Host -MockWith { $script:ansMove1.Dequeue() } | Out-Null
        $script:ansMove1 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMove1.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\dest' -and $PathType -eq 'Container' }
        Mock -CommandName Move-Item -MockWith {}
        { Move-ItemInteractive } | Should -Not -Throw
        Assert-MockCalled Move-Item -Times 1 -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' -and $Destination -eq 'C:\dest\a.txt' -and $Force }
    }
    It 'moves a folder to destination path without overwrite' {
        $answers = @('C:\data','C:\backup','n')
        Mock -CommandName Read-Host -MockWith { $script:ansMove2.Dequeue() } | Out-Null
        $script:ansMove2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansMove2.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data' }
        Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $LiteralPath -eq 'C:\data' -and $PathType -eq 'Leaf' }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data' -and $PathType -eq 'Container' }
        Mock -CommandName Move-Item -MockWith {}
        { Move-ItemInteractive } | Should -Not -Throw
        Assert-MockCalled Move-Item -Times 1 -ParameterFilter { $LiteralPath -eq 'C:\data' -and $Destination -eq 'C:\backup' -and -not $Force }
    }
}

describe 'Get-ItemHashInteractive' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $commonPath = Join-Path $root 'modules\Common.ps1'
        $fileToolsPath = Join-Path $root 'modules\FileTools.ps1'
        . "$commonPath"
        . "$fileToolsPath"
        Mock -CommandName Show-Header -MockWith {}
        Mock -CommandName Pause-Return -MockWith {}
    }
    It 'computes hash for a single file with SHA256' {
        $answers = @('C:\data\a.txt','SHA256')
        Mock -CommandName Read-Host -MockWith { $script:ansHash1.Dequeue() } | Out-Null
        $script:ansHash1 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansHash1.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data\a.txt' -and $PathType -eq 'Leaf' }
        Mock -CommandName Get-FileHash -MockWith { [pscustomobject]@{ Hash='ABCDEF' } }
        { Get-ItemHashInteractive } | Should -Not -Throw
        Assert-MockCalled Get-FileHash -Times 1 -ParameterFilter { $Path -eq 'C:\data\a.txt' -and $Algorithm -eq 'SHA256' }
    }
    It 'computes per-file hashes for a folder and combined digest, writes manifest' {
        $answers = @('C:\data','MD5')
        Mock -CommandName Read-Host -MockWith { $script:ansHash2.Dequeue() } | Out-Null
        $script:ansHash2 = [System.Collections.Queue]::new(); $answers | ForEach-Object { [void]$script:ansHash2.Enqueue($_) }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data' }
        Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $LiteralPath -eq 'C:\data' -and $PathType -eq 'Leaf' }
        Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $LiteralPath -eq 'C:\data' -and $PathType -eq 'Container' }
        $files = @(
            [pscustomobject]@{ FullName='C:\data\a.txt' },
            [pscustomobject]@{ FullName='C:\data\b.txt' }
        )
        Mock -CommandName Get-ChildItem -MockWith { $files } -ParameterFilter { $LiteralPath -eq 'C:\data' -and $Recurse -and $File }
        Mock -CommandName Get-FileHash -MockWith { [pscustomobject]@{ Hash='00AA' } }
        Mock -CommandName Get-AppOutputSettings -MockWith { [pscustomobject]@{ Enabled=$true; Folder='C:\out'; WriteHashManifest=$true } }
        Mock -CommandName Add-Content -MockWith {}
        { Get-ItemHashInteractive } | Should -Not -Throw
        Assert-MockCalled Add-Content -Times 1 -ParameterFilter { $Path -like 'C:\out\hash_manifest_*' }
        Assert-MockCalled Get-FileHash -Times 2
    }
}
