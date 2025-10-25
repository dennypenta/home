export PATH=$HOME/bin:/usr/local/bin:$PATH
export GOBIN=~/go/bin
export PATH=~/Library/Python/3.9/bin:$GOBIN:$PATH
export PATH=/Users/denis/.cargo/bin:$PATH
export GOPRIVATE=github.com/digitalocean/*
export DOCKER_BUILDKIT=1
export EDITOR='nvim'
export LS_COLORS='no=00;37:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:'
# export EZA_COLORS='no=00;37:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:'
# brew envs
eval "$(/opt/homebrew/bin/brew shellenv)"

# node
export NODE_OPTIONS="--max-old-space-size=6096"
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_co

# zinit dir
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# download zinit
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# load zinit
source "${ZINIT_HOME}/zinit.zsh"

# load completions
autoload -U compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# history scroll by prefix up and down
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
# make alt+backspace delete a word until / symbol
# # helps to remove a single folder from a path string
autoload -U select-word-style
select-word-style bash

# plugins
# fzf tab must be first in order to make it work
# the rest plugins conflict with TAB key binding
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
# highlights suggestions from the history
zinit light zsh-users/zsh-autosuggestions
# omzsh plugins
# ctrl+o(^o) copies the current input 
zinit snippet OMZP::copybuffer
zinit snippet OMZP::git
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose
zinit snippet OMZP::kubectl
zinit snippet OMZP::command-not-found
zinit snippet OMZP::colored-man-pages
# substring search
zinit load 'zsh-users/zsh-history-substring-search'
bindkey '^p' history-substring-search-up
bindkey '^n' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
# to learning shortcut
zinit snippet OMZP::alias-finder 
zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
zstyle ':omz:plugins:alias-finder' longer yes # disabled by default
zstyle ':omz:plugins:alias-finder' exact yes # disabled by default
zstyle ':omz:plugins:alias-finder' cheaper yes # disabled by default

# read man zshoptions
# sound
unsetopt beep
# cd
setopt autocd
# completion
# history search
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# make completion case insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# disable sort when completing git checkout
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using < and >
zstyle ':fzf-tab:*' switch-group '<' '>'
# turn off path highlighting and outline
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none
# bind TAB to expand completion
# note: it has a confilict with fzf-tab, so I experiment without that bindkey
# bindkey '^I' expand-or-complete

# substring search
# source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# edit a command in vim
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-x' edit-command-line

# stores commands for later use
zinit cdreplay -q

# enable shell batteries
# fzf
eval "$(fzf --zsh)"
# zoxide
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# aliases
alias -- -='cd -'
alias l='eza -la --header --icons=always --git'
alias ls='eza'
alias ll='eza -lh'
alias la='eza -lAh'
alias ltree='eza --tree --icons'
alias vi='nvim'
alias gfrm="git fetch --all && git rebase origin/main  git rebase origin/master"
alias gfrd="git fetch --all && git rebase origin/develop"
alias cpf="copyfile"
alias zshrc="${=EDITOR} ~/.zshrc"

# starship load
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# fzf batteries 
# # fd - cd to selected directory
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}
# # ff - find a file by path
ff() {
  local file
  file=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type f -print 2> /dev/null | fzf +m) &&
  [ -n "$file" ] && ${EDITOR} "$file"
}
# # fn - find a file by name
fn() {
  local file
  file=$(find ${1:-.} -name '*/\.*' -prune \
                  -o -type f -print 2> /dev/null | fzf +m) &&
  [ -n "$file" ] && ${EDITOR} "$file"
}
# fh - search in your command history and execute selected command
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}
# copyfile 
function copyfile {
  [[ "$#" != 1 ]] && return 1
  local file_to_copy=$1
  cat $file_to_copy | pbcopy
}
# copy a command to a clipboard
function clipcopy() { cat "${1:-/dev/stdin}" | pbcopy; }


# work related staff
if [ -f "$HOME/.zshrcwork" ];
  then source "$HOME/.zshrcwork"
fi

# pnpm
export PNPM_HOME="/Users/d.dvornikov/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.local/bin:$PATH"
# mason 
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# wezterm
export WEZTERM_CONFIG_FILE=$HOME/.config/wezterm/wezterm.lua
