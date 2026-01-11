# File Management Tools

function Compare-FoldersBasic {
    Show-Header -Title "File Tools :: Compare Folders (basic)"

    $path1 = Read-Host "Enter first folder path (Path1)"
    $path2 = Read-Host "Enter second folder path (Path2)"

    if (-not (Test-Path $path1)) { Write-Host "Path '$path1' does not exist." -ForegroundColor Red; Pause-Return; return }
    if (-not (Test-Path $path2)) { Write-Host "Path '$path2' does not exist." -ForegroundColor Red; Pause-Return; return }

    Write-Host ""; Write-Host "Collecting files and comparing..." -ForegroundColor Cyan

    $files1 = Get-ChildItem -Path $path1 -Recurse -File | ForEach-Object {
        [PSCustomObject]@{ RelativePath = $_.FullName.Substring($path1.Length).TrimStart('\'); Length = $_.Length; LastWrite = $_.LastWriteTimeUtc }
    }
    $files2 = Get-ChildItem -Path $path2 -Recurse -File | ForEach-Object {
        [PSCustomObject]@{ RelativePath = $_.FullName.Substring($path2.Length).TrimStart('\'); Length = $_.Length; LastWrite = $_.LastWriteTimeUtc }
    }

    $diff = Compare-Object -ReferenceObject $files1 -DifferenceObject $files2 -Property RelativePath, Length, LastWrite

    Write-Host ""
    if (-not $diff) {
        Write-Host "Folders are identical (names, sizes, last write times)." -ForegroundColor Green
    } else {
        Write-Host "Differences found between the folders:" -ForegroundColor Yellow
        $diff | Format-Table -AutoSize
    }

    Pause-Return
}

function Compare-FoldersHash {
    Show-Header -Title "File Tools :: Compare Folders (hash)"

    $path1 = Read-Host "Enter first folder path (Path1)"
    $path2 = Read-Host "Enter second folder path (Path2)"

    if (-not (Test-Path $path1)) { Write-Host "Path '$path1' does not exist." -ForegroundColor Red; Pause-Return; return }
    if (-not (Test-Path $path2)) { Write-Host "Path '$path2' does not exist." -ForegroundColor Red; Pause-Return; return }

    function Get-FilesWithHash {
        param([string]$PathBase)
        Write-Host "Collecting file list for: $PathBase" -ForegroundColor Cyan
        $allFiles = Get-ChildItem -Path $PathBase -Recurse -File
        $total    = $allFiles.Count
        if ($total -eq 0) { Write-Host "No files found in $PathBase" -ForegroundColor Yellow; return @() }
        Write-Host "Calculating hashes for $total files in: $PathBase" -ForegroundColor Cyan
        $index = 0
        foreach ($file in $allFiles) {
            $index++; $percent = [int](($index / $total) * 100)
            Show-ProgressWrapper -Activity "Hashing files in $PathBase" -PercentComplete $percent
            $relative = $file.FullName.Substring($PathBase.Length).TrimStart('\')
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
            [PSCustomObject]@{ RelativePath = $relative; Length = $file.Length; Hash = $hash.Hash }
        }
        Write-Progress -Activity "Hashing files in $PathBase" -Completed
    }

    $files1 = Get-FilesWithHash -PathBase $path1
    $files2 = Get-FilesWithHash -PathBase $path2

    if (($files1.Count -eq 0) -and ($files2.Count -eq 0)) { Write-Host "No files to compare in either folder." -ForegroundColor Yellow; Pause-Return; return }

    Write-Host ""; Write-Host "Comparing results..." -ForegroundColor Cyan
    $diff = Compare-Object -ReferenceObject $files1 -DifferenceObject $files2 -Property RelativePath, Length, Hash

    Write-Host ""
    if (-not $diff) { Write-Host "Folders are identical in content (paths, sizes, hashes)." -ForegroundColor Green }
    else { Write-Host "Differences found between the folders:" -ForegroundColor Yellow; $diff | Format-Table -AutoSize }

    Pause-Return
}

function Find-DuplicateFiles {
    Show-Header -Title "File Tools :: Find Duplicate Files"
    $path = Read-Host "Enter folder path to scan for duplicates"
    if (-not (Test-Path $path)) { Write-Host "Path '$path' does not exist." -ForegroundColor Red; Pause-Return; return }

    Write-Host "Collecting file list..." -ForegroundColor Cyan
    $allFiles = Get-ChildItem -Path $path -Recurse -File
    $total    = $allFiles.Count
    if ($total -eq 0) { Write-Host "No files found in $path" -ForegroundColor Yellow; Pause-Return; return }

    Write-Host "Calculating hashes for $total files..." -ForegroundColor Cyan
    $index = 0
    $files = foreach ($file in $allFiles) {
        $index++; $percent = [int](($index / $total) * 100)
        Show-ProgressWrapper -Activity "Hashing files in $path" -PercentComplete $percent
        $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
        [PSCustomObject]@{ FullName = $file.FullName; Hash = $hash.Hash; Length = $file.Length }
    }
    Write-Progress -Activity "Hashing files in $path" -Completed

    $dups = $files | Group-Object Hash | Where-Object { $_.Count -gt 1 }

    if (-not $dups) { Write-Host "No duplicate files found." -ForegroundColor Green }
    else {
        Write-Host "Duplicate file groups found:" -ForegroundColor Yellow
        foreach ($group in $dups) {
            Write-Host "Hash: $($group.Name)" -ForegroundColor Cyan
            $group.Group | Select-Object FullName, Length | Format-Table -AutoSize
            Write-Host ""
        }
    }

    Pause-Return
}

function Show-DirectoryListing {
    Show-Header -Title "File Tools :: Directory Listing (dir)"
    $path = Read-Host "Enter folder path to list"
    if (-not (Test-Path $path)) { Write-Host "Path '$path' does not exist." -ForegroundColor Red; Pause-Return; return }
    Get-ChildItem -Path $path -Force |
        Select-Object Mode, Name, @{Name='Size';Expression={$_.Length}}, LastWriteTime |
        Format-Table -AutoSize
    Pause-Return
}

function Show-TreeView {
    Show-Header -Title "File Tools :: Tree View"
    $path = Read-Host "Enter folder path to show tree"
    if (-not (Test-Path $path)) { Write-Host "Path '$path' does not exist." -ForegroundColor Red; Pause-Return; return }
    Write-Host "Generating tree for: $path" -ForegroundColor Cyan
    try {
        cmd.exe /c "tree /F `"$path`""
    } catch {
        Write-Host "'tree' command not available. Showing simple recursive view:" -ForegroundColor Yellow
        Get-ChildItem -Path $path -Recurse | ForEach-Object {
            $depth = $_.FullName.Substring($path.Length).Split([char]'\').Where({ $_ -ne '' }).Count
            $indent = (' ' * ($depth * 2))
            Write-Host "$indent$($_.Name)"
        }
    }
    Pause-Return
}

function Create-NewFile {
    Show-Header -Title "File Tools :: Create New File"
    $filePath = Read-Host "Enter full file path to create"
    if ([string]::IsNullOrWhiteSpace($filePath)) { Write-Host "No file path provided." -ForegroundColor Red; Pause-Return; return }
    $dir = Split-Path -Parent $filePath
    if (-not (Test-Path $dir)) { Write-Host "Parent folder does not exist: $dir" -ForegroundColor Red; Pause-Return; return }
    if (Test-Path $filePath) {
        $overwrite = Read-Host "File exists. Overwrite? (y/N)"
        if ($overwrite.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    }
    $content = Read-Host "Optional initial content (leave blank for empty)"
    try {
        if ([string]::IsNullOrEmpty($content)) { New-Item -ItemType File -Path $filePath -Force | Out-Null }
        else { Set-Content -Path $filePath -Value $content -Force }
        Write-Host "Created file: $filePath" -ForegroundColor Green
    } catch { Write-Host "Failed to create file: $_" -ForegroundColor Red }
    Pause-Return
}

function Delete-File {
    Show-Header -Title "File Tools :: Delete File"
    $filePath = Read-Host "Enter full file path to delete"
    if (-not (Test-Path $filePath)) { Write-Host "File not found: $filePath" -ForegroundColor Red; Pause-Return; return }
    $confirm = Read-Host "Are you sure you want to delete '$filePath'? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { Remove-Item -Path $filePath -Force; Write-Host "Deleted: $filePath" -ForegroundColor Green }
    catch { Write-Host "Failed to delete file: $_" -ForegroundColor Red }
    Pause-Return
}

function Remove-FilesOlderThan {
    Show-Header -Title "File Tools :: Delete Files Older Than X Days"
    $path = Read-Host "Enter folder path"
    if (-not (Test-Path $path)) { Write-Host "Path '$path' does not exist." -ForegroundColor Red; Pause-Return; return }
    $daysStr = Read-Host "Delete files older than how many days?"
    [int]$days = 0
    if (-not [int]::TryParse($daysStr, [ref]$days)) { Write-Host "Invalid number of days." -ForegroundColor Red; Pause-Return; return }
    $cutoff = (Get-Date).AddDays(-$days)
    $files = Get-ChildItem -Path $path -File -Recurse | Where-Object { $_.LastWriteTime -lt $cutoff }
    if (-not $files -or $files.Count -eq 0) { Write-Host "No files older than $days days." -ForegroundColor Green; Pause-Return; return }
    Write-Host "Found $($files.Count) files older than $days days (cutoff: $cutoff)." -ForegroundColor Yellow
    $previewCount = [Math]::Min(10, $files.Count)
    $files | Select-Object -First $previewCount FullName, LastWriteTime | Format-Table -AutoSize
    $confirm = Read-Host "Delete all $($files.Count) files? (y/N)"
    if ($confirm.ToLowerInvariant() -ne 'y') { Write-Host "Cancelled." -ForegroundColor Yellow; Pause-Return; return }
    try { $files | Remove-Item -Force; Write-Host "Deleted $($files.Count) files." -ForegroundColor Green }
    catch { Write-Host "Failed deleting some files: $_" -ForegroundColor Red }
    Pause-Return
}

function Compress-Folder {
    Show-Header -Title "File Tools :: Compress Folder (ZIP/7Z/tar)"
    $src = Read-Host "Enter source folder to compress"
    if (-not (Test-Path $src)) { Write-Host "Path '$src' does not exist." -ForegroundColor Red; Pause-Return; return }
    $format = Read-Host "Choose format: zip / 7z / tar (default: zip)"
    if ([string]::IsNullOrWhiteSpace($format)) { $format = 'zip' }
    $format = $format.ToLowerInvariant()
    $dest = Read-Host "Enter destination archive path (e.g. C:\\tmp\\archive.zip)"
    if ([string]::IsNullOrWhiteSpace($dest)) { Write-Host "No destination provided." -ForegroundColor Red; Pause-Return; return }

    try {
        switch ($format) {
            'zip' {
                if (-not $dest.ToLower().EndsWith('.zip')) { $dest = "$dest.zip" }
                Write-Host "Compressing to ZIP: $dest" -ForegroundColor Cyan
                Compress-Archive -Path (Join-Path $src '*') -DestinationPath $dest -Force
                Write-Host "ZIP created: $dest" -ForegroundColor Green
            }
            'tar' {
                if (-not $dest.ToLower().EndsWith('.tar')) { $dest = "$dest.tar" }
                $tar = Get-Command tar -ErrorAction SilentlyContinue
                if (-not $tar) { Write-Host "tar.exe not found in PATH." -ForegroundColor Red; break }
                Write-Host "Compressing to TAR: $dest" -ForegroundColor Cyan
                & $tar.Source -cf "$dest" -C "$src" .
                Write-Host "TAR created: $dest" -ForegroundColor Green
            }
            '7z' {
                if (-not $dest.ToLower().EndsWith('.7z')) { $dest = "$dest.7z" }
                $sevenZ = Get-Command 7z -ErrorAction SilentlyContinue
                if (-not $sevenZ) {
                    $sevenZPath = Read-Host "7z.exe not found. Enter full path to 7z.exe (or leave blank to cancel)"
                    if ([string]::IsNullOrWhiteSpace($sevenZPath) -or -not (Test-Path $sevenZPath)) { Write-Host "7z.exe not available." -ForegroundColor Red; break }
                    $sevenZ = @{ Source = $sevenZPath }
                }
                Write-Host "Compressing to 7Z: $dest" -ForegroundColor Cyan
                & $sevenZ.Source a -t7z "$dest" (Join-Path $src '*') | Out-Null
                Write-Host "7Z created: $dest" -ForegroundColor Green
            }
            default { Write-Host "Unknown format: $format" -ForegroundColor Red }
        }
    } catch { Write-Host "Compression failed: $_" -ForegroundColor Red }

    Pause-Return
}

function Copy-ItemInteractive {
    Show-Header -Title "File Tools :: Copy Item (File/Folder)"
    $src = Read-Host "Enter source path (file or folder)"
    if (-not (Test-Path -LiteralPath $src)) { Write-Host "Source not found: $src" -ForegroundColor Red; Pause-Return; return }

    $dest = Read-Host "Enter destination path (existing folder or full path)"
    if ([string]::IsNullOrWhiteSpace($dest)) { Write-Host "No destination provided." -ForegroundColor Red; Pause-Return; return }

    $isFile = Test-Path -LiteralPath $src -PathType Leaf
    $isDir  = Test-Path -LiteralPath $src -PathType Container

    $overwriteAns = Read-Host "Overwrite existing files if present? (y/N)"
    $overwrite = ($overwriteAns.ToLowerInvariant() -eq 'y')

    try {
        if ($isFile) {
            if (Test-Path -LiteralPath $dest -PathType Container) {
                $target = Join-Path $dest (Split-Path -Leaf $src)
            } else {
                $target = $dest
            }
            Write-Host ("Copying file to: {0}" -f $target) -ForegroundColor Cyan
            if ($overwrite) { Copy-Item -LiteralPath $src -Destination $target -Force }
            else { if (Test-Path -LiteralPath $target) { Write-Host "Target exists. Skipping (overwrite disabled)." -ForegroundColor Yellow } else { Copy-Item -LiteralPath $src -Destination $target } }
        } elseif ($isDir) {
            Write-Host ("Copying folder to: {0}" -f $dest) -ForegroundColor Cyan
            if ($overwrite) { Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force }
            else { Copy-Item -LiteralPath $src -Destination $dest -Recurse }
        } else {
            Write-Host "Source path type unknown." -ForegroundColor Red
        }
        Write-Host "Copy completed." -ForegroundColor Green
    } catch { Write-Host "Copy failed: $_" -ForegroundColor Red }
    Pause-Return
}

function Move-ItemInteractive {
    Show-Header -Title "File Tools :: Move Item (File/Folder)"
    $src = Read-Host "Enter source path (file or folder)"
    if (-not (Test-Path -LiteralPath $src)) { Write-Host "Source not found: $src" -ForegroundColor Red; Pause-Return; return }

    $dest = Read-Host "Enter destination path (existing folder or full path)"
    if ([string]::IsNullOrWhiteSpace($dest)) { Write-Host "No destination provided." -ForegroundColor Red; Pause-Return; return }

    $isFile = Test-Path -LiteralPath $src -PathType Leaf
    $isDir  = Test-Path -LiteralPath $src -PathType Container

    $overwriteAns = Read-Host "Overwrite existing files/folders if present? (y/N)"
    $overwrite = ($overwriteAns.ToLowerInvariant() -eq 'y')

    try {
        if ($isFile) {
            if (Test-Path -LiteralPath $dest -PathType Container) {
                $target = Join-Path $dest (Split-Path -Leaf $src)
            } else {
                $target = $dest
            }
            Write-Host ("Moving file to: {0}" -f $target) -ForegroundColor Cyan
            if (-not $overwrite -and (Test-Path -LiteralPath $target)) {
                Write-Host "Target exists. Skipping (overwrite disabled)." -ForegroundColor Yellow
            } else {
                if ($overwrite) { Move-Item -LiteralPath $src -Destination $target -Force }
                else { Move-Item -LiteralPath $src -Destination $target }
                Write-Host "Move completed." -ForegroundColor Green
            }
        } elseif ($isDir) {
            Write-Host ("Moving folder to: {0}" -f $dest) -ForegroundColor Cyan
            if (-not $overwrite -and (Test-Path -LiteralPath $dest -PathType Leaf)) {
                Write-Host "A file exists at destination path. Skipping (overwrite disabled)." -ForegroundColor Yellow
            } else {
                if ($overwrite) { Move-Item -LiteralPath $src -Destination $dest -Force }
                else { Move-Item -LiteralPath $src -Destination $dest }
                Write-Host "Move completed." -ForegroundColor Green
            }
        } else {
            Write-Host "Source path type unknown." -ForegroundColor Red
        }
    } catch { Write-Host "Move failed: $_" -ForegroundColor Red }
    Pause-Return
}

function Get-ItemHashInteractive {
    Show-Header -Title "File Tools :: Compute Hash (File/Folder)"
    $path = Read-Host "Enter path to file or folder"
    if (-not (Test-Path -LiteralPath $path)) { Write-Host "Path not found: $path" -ForegroundColor Red; Pause-Return; return }

    $algInput = Read-Host "Algorithm (MD5/SHA1/SHA256/SHA384/SHA512) [default: SHA256]"
    if ([string]::IsNullOrWhiteSpace($algInput)) { $algInput = 'SHA256' }
    $algorithm = $algInput.ToUpperInvariant()
    if (@('MD5','SHA1','SHA256','SHA384','SHA512') -notcontains $algorithm) { Write-Host "Unsupported algorithm: $algInput" -ForegroundColor Red; Pause-Return; return }

    $isFile = Test-Path -LiteralPath $path -PathType Leaf
    $isDir  = Test-Path -LiteralPath $path -PathType Container

    try {
        if ($isFile) {
            $h = Get-FileHash -Path $path -Algorithm $algorithm
            Write-Host ("{0}  {1}" -f $h.Hash, $path) -ForegroundColor Cyan
            $out = Get-AppOutputSettings
            if ($out.WriteHashManifest) {
                $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
                $manifest = Join-Path $out.Folder ("hash_manifest_{0}.txt" -f $stamp)
                try { Add-Content -Path $manifest -Value ("{0}  {1}" -f $h.Hash, $path) -Encoding utf8 } catch {}
            }
        } elseif ($isDir) {
            Write-Host "Computing per-file hashes..." -ForegroundColor Cyan
            $files = Get-ChildItem -LiteralPath $path -Recurse -File
            if (-not $files -or $files.Count -eq 0) { Write-Host "No files found in folder." -ForegroundColor Yellow; Pause-Return; return }
            $total = $files.Count; $idx = 0
            $entries = foreach ($f in ($files | Sort-Object FullName)) {
                $idx++; $pct = [int](($idx / $total) * 100); Show-ProgressWrapper -Activity "Hashing files" -PercentComplete $pct
                $fh = Get-FileHash -Path $f.FullName -Algorithm $algorithm
                [PSCustomObject]@{ RelativePath = $f.FullName.Substring($path.Length).TrimStart('\'); Hash = $fh.Hash }
            }
            Write-Progress -Activity "Hashing files" -Completed
            $entries | Format-Table RelativePath, Hash -AutoSize

            # Combined folder hash (deterministic by sorted path:hash lines)
            $concat = ($entries | Sort-Object RelativePath | ForEach-Object { "{0}:{1}" -f $_.RelativePath, $_.Hash }) -join "`n"
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($concat)
            $hasher = [System.Security.Cryptography.HashAlgorithm]::Create($algorithm)
            $combined = [System.BitConverter]::ToString($hasher.ComputeHash($bytes)).Replace('-', '')
            Write-Host ("Combined {0} of folder: {1}" -f $algorithm, $combined) -ForegroundColor Green

            $out = Get-AppOutputSettings
            if ($out.WriteHashManifest) {
                $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
                $manifest = Join-Path $out.Folder ("hash_manifest_{0}.txt" -f $stamp)
                try {
                    Add-Content -Path $manifest -Value ("# Hash manifest ({0}) for {1}" -f $algorithm, $path) -Encoding utf8
                    foreach ($e in ($entries | Sort-Object RelativePath)) { Add-Content -Path $manifest -Value ("{0}  {1}" -f $e.Hash, $e.RelativePath) -Encoding utf8 }
                    Add-Content -Path $manifest -Value ("Combined {0}: {1}" -f $algorithm, $combined) -Encoding utf8
                } catch {}
            }
        } else { Write-Host "Unknown path type." -ForegroundColor Red }
    } catch { Write-Host "Hash computation failed: $_" -ForegroundColor Red }
    Pause-Return
}

function Show-FileToolsMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "File Management Tools"
        Write-Host " [1] Comparisons & Listings" -ForegroundColor White
        Write-Host " [2] Create & Delete" -ForegroundColor White
        Write-Host " [3] Copy & Compress" -ForegroundColor White
        Write-Host " [4] Hashing" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back to main menu" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Show-FileCompareListMenu }
            '2' { Show-FileCreateDeleteMenu }
            '3' { Show-FileCopyCompressMenu }
            '4' { Show-FileHashingMenu }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-FileCompareListMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "File Tools :: Comparisons & Listings"
        Write-Host " [1] Compare folders (basic: names, sizes, times)" -ForegroundColor White
        Write-Host " [2] Compare folders (hash: SHA256, exact content)" -ForegroundColor White
        Write-Host " [3] Find duplicate files (hash-based)" -ForegroundColor White
        Write-Host " [4] Directory listing (dir)" -ForegroundColor White
        Write-Host " [5] Tree view of folder" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'File.CompareFoldersBasic' -Action { Compare-FoldersBasic } }
            '2' { Invoke-Tool -Name 'File.CompareFoldersHash' -Action { Compare-FoldersHash } }
            '3' { Invoke-Tool -Name 'File.FindDuplicateFiles' -Action { Find-DuplicateFiles } }
            '4' { Invoke-Tool -Name 'File.DirectoryListing' -Action { Show-DirectoryListing } }
            '5' { Invoke-Tool -Name 'File.TreeView' -Action { Show-TreeView } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-FileCreateDeleteMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "File Tools :: Create & Delete"
        Write-Host " [1] Create new file" -ForegroundColor White
        Write-Host " [2] Delete a file" -ForegroundColor White
        Write-Host " [3] Delete files older than X days" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'File.CreateNewFile' -Action { Create-NewFile } }
            '2' { Invoke-Tool -Name 'File.DeleteFile' -Action { Delete-File } }
            '3' { Invoke-Tool -Name 'File.DeleteOlderThan' -Action { Remove-FilesOlderThan } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-FileCopyCompressMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "File Tools :: Copy, Move & Compress"
        Write-Host " [1] Copy item (file/folder)" -ForegroundColor White
        Write-Host " [2] Move item (file/folder)" -ForegroundColor White
        Write-Host " [3] Compress folder (ZIP/7Z/tar)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'File.CopyItem' -Action { Copy-ItemInteractive } }
            '2' { Invoke-Tool -Name 'File.MoveItem' -Action { Move-ItemInteractive } }
            '3' { Invoke-Tool -Name 'File.CompressFolder' -Action { Compress-Folder } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-FileHashingMenu {
    $selection = $null
    while ($selection -ne '0') {
        Show-Header -Title "File Tools :: Hashing"
        Write-Host " [1] Compute hash (file/folder)" -ForegroundColor White
        Write-Host ""; Write-Host " [0] Back" -ForegroundColor DarkGray; Write-Host ""
        $selection = Read-Host "Select an option"
        switch ($selection) {
            '1' { Invoke-Tool -Name 'File.ComputeHash' -Action { Get-ItemHashInteractive } }
            '0' { break }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
