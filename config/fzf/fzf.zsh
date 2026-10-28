# 0x0ps Neon Matrix — fzf interface
export FZF_DEFAULT_OPTS='--ansi --color=fg:#D7F7D7,bg:#000000,hl:#00FFFF,fg+:#FFFFFF,bg+:#101010,hl+:#A6FF00,info:#00FFFF,prompt:#A6FF00,pointer:#FF00AF,marker:#FF00AF,spinner:#00FFFF,header:#00FFFF,border:#A6FF00'

# Dedicated file colors for fzf only; do not change lsd's LS_COLORS.
export FZF_FILE_LS_COLORS='fi=38;5;46:di=38;5;46:ex=38;5;51:ln=38;5;51:*.sh=38;5;51:*.bash=38;5;51:*.zsh=38;5;51:*.py=38;5;51:*.pl=38;5;51:*.rb=38;5;51:*.js=38;5;51:*.ts=38;5;51:*.go=38;5;51:*.php=38;5;51:*.ps1=38;5;51:*.conf=38;5;201:*.config=38;5;201:*.yaml=38;5;201:*.yml=38;5;201:*.json=38;5;201:*.toml=38;5;201:*.ini=38;5;201:*.env=38;5;201:*.xml=38;5;201:*.properties=38;5;201'

# Use fd-find (named fdfind on Debian/Kali) and preserve ANSI colors.
if command -v fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='env LS_COLORS="$FZF_FILE_LS_COLORS" fdfind --type f --type d --hidden --follow --exclude .git --color=always'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Debian/Kali Zsh key bindings and completion.
if [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
elif [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi

if [[ -r /usr/share/doc/fzf/examples/completion.zsh ]]; then
  source /usr/share/doc/fzf/examples/completion.zsh
elif [[ -r /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi
