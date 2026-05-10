param(
    [switch]$Apply = $false
)

$ErrorActionPreference = "Stop"

$libDir = "c:\Users\ferdi\Desktop\randevumcepteuygulamaweb\Randevumcepte-Private-Flutter\lib"
$packageName = "randevu_sistem"
$libPathFull = [System.IO.Path]::GetFullPath($libDir).TrimEnd('\').TrimEnd('/')

$totalFilesScanned = 0
$totalFilesChanged = 0
$totalImportsFixed = 0
$skippedBackups = 0

# Match: import '<relpath>'; where relpath starts with . or ..
$importRegex = [regex]"import\s+'(\.{1,2}(?:/[^']+)+)'\s*;"

Get-ChildItem -Path $libDir -Recurse -File -Filter "*.dart" | ForEach-Object {
    $file = $_

    # Skip backup files
    if ($file.Name -like "*.bak" -or $file.Name -like "*.bak.dart" -or $file.Name -match "-old\." -or $file.Name -match "-bak\." -or $file.FullName -like "*-1.dart" -or $file.FullName -like "*.dart-*") {
        $script:skippedBackups++
        return
    }

    $script:totalFilesScanned++

    $content = [System.IO.File]::ReadAllText($file.FullName)
    $original = $content
    $localFixCount = 0

    # Find all matches first, then replace in reverse
    $matches = $importRegex.Matches($content)
    if ($matches.Count -eq 0) { return }

    # Build replacement list
    $reps = @()
    foreach ($m in $matches) {
        $relpath = $m.Groups[1].Value
        $importingDir = [System.IO.Path]::GetDirectoryName($file.FullName)

        $newImport = $null

        # Try normal resolution
        try {
            $abs = [System.IO.Path]::GetFullPath((Join-Path $importingDir $relpath))
        } catch {
            continue
        }

        $absForward = $abs.Replace('\', '/')
        $libForward = $libPathFull.Replace('\', '/')

        if ($absForward.StartsWith($libForward + '/')) {
            $rel = $absForward.Substring($libForward.Length + 1)
            $newImport = "import 'package:$packageName/$rel';"
        } else {
            # Path goes outside lib/. Try stripping all ../ prefixes.
            $stripped = [regex]::Replace($relpath, '^((\.\.?)/)+', '')
            if ($stripped -ne $relpath) {
                $candidate = Join-Path $libDir ($stripped -replace '/', '\')
                if (Test-Path -LiteralPath $candidate) {
                    $newImport = "import 'package:$packageName/$stripped';"
                }
            }
        }

        if ($null -ne $newImport -and $newImport -ne $m.Value) {
            $reps += [PSCustomObject]@{
                Index = $m.Index
                Length = $m.Length
                Old = $m.Value
                New = $newImport
            }
        }
    }

    if ($reps.Count -eq 0) { return }

    # Apply replacements in reverse order
    $reps = $reps | Sort-Object -Property Index -Descending
    foreach ($r in $reps) {
        $content = $content.Substring(0, $r.Index) + $r.New + $content.Substring($r.Index + $r.Length)
        $localFixCount++
    }

    $script:totalImportsFixed += $localFixCount

    if ($content -ne $original) {
        $script:totalFilesChanged++
        $relFilePath = $file.FullName.Substring($libPathFull.Length + 1)
        if ($Apply) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
            Write-Host "[FIXED $localFixCount] $relFilePath" -ForegroundColor Green
        } else {
            Write-Host "[WOULD FIX $localFixCount] $relFilePath" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
if ($Apply) {
    Write-Host "APPLIED. Files changed: $totalFilesChanged / $totalFilesScanned (skipped $skippedBackups backups). Imports fixed: $totalImportsFixed" -ForegroundColor Cyan
} else {
    Write-Host "DRY RUN. Files that would change: $totalFilesChanged / $totalFilesScanned (skipped $skippedBackups backups). Imports to fix: $totalImportsFixed" -ForegroundColor Cyan
    Write-Host "Re-run with: powershell -File fix_imports.ps1 -Apply" -ForegroundColor Cyan
}
Write-Host "================================" -ForegroundColor Cyan
