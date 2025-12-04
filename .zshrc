HISTFILE=~/.cache/zsh/histfile
HISTSIZE=10000000000
SAVEHIST=1000000000
setopt autocd extendedglob nomatch
unsetopt beep
bindkey -e
setopt PROMPT_SUBST
PROMPT='%F{white}%n%f@%F{cyan}%m%f %F{white}%~%f %% '
export PATH=$PATH:$HOME/go/bin

zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

export PATH="$HOME/.local/bin:$PATH"

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
      vim='nvim'

# Process management
alias psa='ps auxf' \
      psgrep='ps aux | grep -v grep | grep -i -e VSZ -e' \
      psmem='ps auxf | sort -nr -k 4' \
      pscpu='ps auxf | sort -nr -k 3'

# fzf man page finder
alias fman="compgen -c | fzf | xargs man"

# Journal
alias jctl='journalctl -p 3 -xb'

# test lsd

alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

command -v zoxide >/dev/null && source <(zoxide init --cmd cd zsh)
command -v fzf >/dev/null && source <(fzf --zsh)

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
