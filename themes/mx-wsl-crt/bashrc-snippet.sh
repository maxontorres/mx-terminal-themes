# BEGIN MX://WSL-CRT
if [[ -x "$HOME/.local/bin/oh-my-posh" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
if [[ $- == *i* ]] && command -v oh-my-posh >/dev/null 2>&1; then
    eval "$(oh-my-posh init bash --config "$HOME/.config/oh-my-posh/mx-wsl-crt.omp.json")"
fi
# END MX://WSL-CRT
