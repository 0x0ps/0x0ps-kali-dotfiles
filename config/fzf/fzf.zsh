# 0x0ps Neon Matrix colors for fzf
export FZF_DEFAULT_OPTS='--color=fg:#D7F7D7,bg:#000000,hl:#00FFFF,fg+:#FFFFFF,bg+:#101010,hl+:#A6FF00,info:#00FFFF,prompt:#A6FF00,pointer:#FF00AF,marker:#FF00AF,spinner:#00FFFF,header:#00FFFF,border:#A6FF00'

# Debian/Kali package paths for Zsh key bindings and completion.
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
