#Requires -Version 7.0
<#
.SYNOPSIS
    Installs (or removes) an MX terminal theme for PowerShell 7 + Windows Terminal.
.EXAMPLE
    ./install.ps1
.EXAMPLE
    ./install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string]$Theme = 'mx-ps-01',
    [switch]$Uninstall,
    [string]$OmpDir = (Join-Path $HOME '.config\oh-my-posh'),
    [string]$FragmentDir = (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\MX-Themes'),
    [string]$ProfilePath = $PROFILE.CurrentUserCurrentHost
)

$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot "themes\$Theme"
if (-not (Test-Path -LiteralPath $source)) {
    $known = (Get-ChildItem (Join-Path $PSScriptRoot 'themes') -Directory).Name -join ', '
    throw "Unknown theme '$Theme'. Available: $known"
}

$meta = Get-Content -Raw (Join-Path $source 'theme.json') | ConvertFrom-Json
$ompFile = Join-Path $OmpDir "$Theme.omp.json"
$fragmentFile = Join-Path $FragmentDir "$Theme.json"
$blockPattern = '(?ms)^# BEGIN MX://PS\r?\n.*?^# END MX://PS[^\S\r\n]*(\r?\n)?'
$stamp = Get-Date -Format 'yyyyMMddTHHmmss'
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Backup-File([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        Copy-Item -LiteralPath $Path -Destination "$Path.$stamp.bak"
        Write-Host "  backed up $Path"
    }
}

function Get-ProfileText {
    if (Test-Path -LiteralPath $ProfilePath) { [IO.File]::ReadAllText($ProfilePath) } else { '' }
}

if ($Uninstall) {
    Write-Host "Removing $($meta.id) `"$($meta.codename)`""
    foreach ($file in $ompFile, $fragmentFile) {
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file; Write-Host "  removed $file" }
    }
    $text = Get-ProfileText
    if ($text -match $blockPattern) {
        Backup-File $ProfilePath
        [IO.File]::WriteAllText($ProfilePath, ($text -replace $blockPattern, ''), $utf8)
        Write-Host "  removed the MX://PS block from $ProfilePath"
    }
    Write-Host 'Done. Open a new tab.'
    return
}

Write-Host "Installing $($meta.id) `"$($meta.codename)`" v$($meta.version)"

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Warning 'oh-my-posh is not installed. Install it with: winget install JanDeDobbeleer.OhMyPosh --source winget'
}
$fontKeys = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
$hasFont = $fontKeys | Where-Object { Test-Path $_ } |
    ForEach-Object { (Get-Item $_).Property } | Where-Object { $_ -like 'JetBrainsMono N*' }
if (-not $hasFont) {
    Write-Warning 'JetBrainsMono Nerd Font not found. Install it with: oh-my-posh font install JetBrainsMono'
}

# Prompt theme
New-Item -ItemType Directory -Force -Path $OmpDir | Out-Null
Backup-File $ompFile
Copy-Item -LiteralPath (Join-Path $source "$Theme.omp.json") -Destination $ompFile -Force
Write-Host "  theme    -> $ompFile"

# Windows Terminal profile + colour scheme
New-Item -ItemType Directory -Force -Path $FragmentDir | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'windows-terminal-fragment.json') -Destination $fragmentFile -Force
Write-Host "  terminal -> $fragmentFile"

# PowerShell profile block (replaces a previous MX://PS block if present)
$snippet = [IO.File]::ReadAllText((Join-Path $source 'profile-snippet.ps1')).TrimEnd() + [Environment]::NewLine
$text = Get-ProfileText
Backup-File $ProfilePath
$text = ($text -replace $blockPattern, '').TrimEnd()
if ($text) { $text += [Environment]::NewLine * 2 }
New-Item -ItemType Directory -Force -Path (Split-Path $ProfilePath) | Out-Null
[IO.File]::WriteAllText($ProfilePath, $text + $snippet, $utf8)
Write-Host "  profile  -> $ProfilePath"

Write-Host "Done. Restart Windows Terminal and pick the `"$($meta.id)`" profile."
