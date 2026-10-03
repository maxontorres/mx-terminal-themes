# BEGIN MX://PS
if ($Host.Name -eq 'ConsoleHost') {
    try {
        # Tab title: name of the Windows Terminal profile this shell was started from
        $env:MX_WT_PROFILE_NAME = 'PowerShell'
        if ($env:WT_PROFILE_ID) {
            $mxWtSettings = @(
                'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
                'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'
                'Microsoft\Windows Terminal\settings.json'
            ) | ForEach-Object { Join-Path $env:LOCALAPPDATA $_ } |
                Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
            if ($mxWtSettings) {
                $mxWtProfile = (Get-Content -Raw -LiteralPath $mxWtSettings | ConvertFrom-Json).profiles.list |
                    Where-Object guid -eq $env:WT_PROFILE_ID | Select-Object -First 1
                if ($mxWtProfile.name) { $env:MX_WT_PROFILE_NAME = $mxWtProfile.name }
            }
        }
        $mxOmpConfig = Join-Path $HOME '.config\oh-my-posh\mx-ps-01.omp.json'
        if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $mxOmpConfig)) {
            (& oh-my-posh init pwsh --config "$mxOmpConfig") | Invoke-Expression
        }
    } catch {
        # swallow startup errors silently
    }
}
# END MX://PS
