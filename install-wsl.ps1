<# Installs the Windows Terminal portion of MX://WSL-CRT for the current user. #>
[CmdletBinding()]
param([string]$Distribution = 'Ubuntu')

$ErrorActionPreference = 'Stop'
$themeDir = Join-Path $PSScriptRoot 'themes\mx-wsl-crt'
$fragmentDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\MX-Themes'
$iconFile = Join-Path $fragmentDir 'mx-wsl-crt.ico'
$fragmentFile = Join-Path $fragmentDir 'mx-wsl-crt.json'

New-Item -ItemType Directory -Force -Path $fragmentDir | Out-Null
Copy-Item -LiteralPath (Join-Path $themeDir 'mx-wsl-crt.ico') -Destination $iconFile -Force

$fragment = Get-Content -Raw -LiteralPath (Join-Path $themeDir 'windows-terminal-fragment.json') | ConvertFrom-Json
$fragment.profiles[0].icon = $iconFile
$fragment.profiles[0].commandline = "wsl.exe --distribution `"$Distribution`""
$json = $fragment | ConvertTo-Json -Depth 10
[IO.File]::WriteAllText($fragmentFile, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Host "Installed MX://WSL-CRT for Windows Terminal ($Distribution)."
Write-Host "  fragment -> $fragmentFile"
Write-Host "  icon     -> $iconFile"
Write-Host 'Install the Bash prompt in WSL using the README, then restart Windows Terminal.'
