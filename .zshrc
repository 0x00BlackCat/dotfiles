HISTFILE=~/.cache/zsh/histfile
HISTSIZE=10000000000
SAVEHIST=1000000000
setopt autocd extendedglob nomatch
unsetopt beep
bindkey -e
setopt PROMPT_SUBST
export PATH=$PATH:$HOME/go/bin
zstyle :compinstall filename '~/.zshrc'

autoload -U compinit && compinit

export PATH="$HOME/.local/bin:$PATH"


# Completion

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# === Aliases ===

# Sudo wrappers
alias mount='sudo mount' \
      umount='sudo umount' \
      sv='sudo sv' \
      pacman='sudo pacman' \
      updatedb='sudo updatedb' \
      su='sudo su' \
      shutdown='sudo shutdown' \
      poweroff='sudo poweroff' \
      reboot='sudo reboot'

# Verbose defaults
alias cp='cp -iv' \
      mv='mv -iv' \
      rm='rm -vI' \
      bc='bc -ql' \
      rsync='rsync -vrPlu' \
      mkd='mkdir -pv'

# Colorized output
alias grep='grep --color=auto' \
      diff='diff --color=auto' \
      ccat='highlight --out-format=ansi' \
      ip='ip -color=auto' \
	  ls='ls --color=auto'

# Shortcuts
alias ka='killall' \
      g='git' \
      sdn='shutdown -h now' \
      p='pacman' \
      gg='lazygit' \
      vim='nvim' \

# Process management
alias psa='ps auxf' \
      psgrep='ps aux | grep -v grep | grep -i -e VSZ -e' \
      psmem='ps auxf | sort -nr -k 4' \
      pscpu='ps auxf | sort -nr -k 3'

# fzf man page finder
alias fman="compgen -c | fzf | xargs man"

# Journal
alias jctl='journalctl -p 3 -xb'

# Eza
alias ls='eza --icons'

# fzf test
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --layout=reverse
  --info=inline
  --height=80%
  --multi
  --preview 'bat --style=numbers --color=always --line-range :500 {}'
  --preview-window 'right:60%:wrap'
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'
"



command -v zoxide >/dev/null && source <(zoxide init --cmd cd zsh)
command -v fzf >/dev/null && source <(fzf --zsh)

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

export MANPAGER='nvim +Man!'
eval "$(starship init zsh)"
eval "$(atuin init zsh)"
