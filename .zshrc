if (( _z4h_initialized )); then
  print -ru2 -- ${(%):-"%F{3}z4h%f: please use %F{2}%Uexec%u zsh%f instead of %F{2}source%f %U~/.zshrc%u"}
  return 1
fi

emulate zsh

emulate zsh -o posix_argzero -c ': ${Z4H_ZSH:=${${0#-}:-zsh}}' # command to start zsh
: ${Z4H_DIR:=~/.plugins/zsh}                                   # cache directory

function update-pkgs() {
  case $(uname -s) in
    Linux)
      case $(cat /etc/os-release | grep "^ID=" | sed "s/ID=//") in
        ubuntu) sudo sh -c 'apt update && apt dist-upgrade && apt autoremove --purge && apt clean ; snap refresh' ; clean-snap ;;
        fedora) sudo sh -c 'dnf -y upgrade && dnf -y clean packages';;
        '"amzn"') sudo sh -c 'yum -y update && yum -y clean packages';;
        arch) sudo sh -c 'pacman -Syu && pacman -Scc && pkgfile --update';;
        *) echo "Unrecognized linux flavor. Skipping upgrade"
      esac;;
    Darwin) brew update && brew upgrade && brew cleanup -s --prune=all;;
    *) echo "Unrecognized OS, skipping upgrade";;
  esac
}

function clean-snap() {
  snap list --all | grep disabled | awk '{print "snap remove " $1 " --purge --revision=" $3}' | sudo sh
}

function pvtar() {
	tar -cf - "$1" | pv -s $(du -sb "$1" | awk '{print $1}') ${@:2}
}

function gitshow() {
  git difftool ${1:-HEAD}~ ${1:-HEAD} ${@:2}
}

function update-all() {
  update-pkgs
  nvim --headless "+Lazy! sync" +qa
  uv tool upgrade --all

  ! [ -f ~/.zsh_history.bak ] ||

  diff <(head -n $(wc -l ~/.zsh_history.bak | awk '{print $1}') ~/.zsh_history | sed -E "s/^:[^:]+://g") <(sed -E "s/^:[^:]+://g" ~/.zsh_history.bak) > /dev/null &&
  cp ~/.zsh_history ~/.zsh_history.bak &&
  echo "Zsh history backed up" ||
  echo "WARNING: ZSH History modified. Not updating backup."
  z4h update
}

function z4h() {
  emulate -L zsh

  case $ARGC-$1 in
    1-init)   local -i update=0;;
    1-update) local -i update=1;;
    2-source)
      [[ -r $2 ]] || return
      if [[ ! $2.zwc -nt $2 && -w ${2:h} ]]; then
        zmodload -F zsh/files b:zf_mv b:zf_rm || return
        local tmp=$2.tmp.$$.zwc
        {
          zcompile -R -- $tmp $2 && zf_mv -f -- $tmp $2.zwc || return
        } always {
          (( $? )) && zf_rm -f $tmp
        }
      fi
      source -- $2
      return
    ;;
    *)
      print -ru2 -- ${(%):-"usage: %F{2}z4h%f %Binit%b|%Bupdate%b|%Bsource%b"}
      return 1
    ;;
  esac

  (( _z4h_initialized && ! update )) && exec -- $Z4H_ZSH

  # GitHub projects to clone.
  local github_repos=(
    zsh-users/zsh-syntax-highlighting  # https://github.com/zsh-users/zsh-syntax-highlighting
    zsh-users/zsh-autosuggestions      # https://github.com/zsh-users/zsh-autosuggestions
    zsh-users/zsh-completions          # https://github.com/zsh-users/zsh-completions
    romkatv/powerlevel10k              # https://github.com/romkatv/powerlevel10k
    Aloxaf/fzf-tab                     # https://github.com/Aloxaf/fzf-tab
  )

  {
    if [[ ! -d $Z4H_DIR ]]; then
      zmodload -F zsh/files b:zf_mkdir || return
      zf_mkdir -p -- $Z4H_DIR || return
      update=1
    fi

    # Clone or update all repositories.
    local repo
    for repo in $github_repos; do
      if [[ -d $Z4H_DIR/$repo ]]; then
        if (( update )); then
          print -ru2 -- ${(%):-"%F{3}z4h%f: updating %B${repo//\%/%%}%b"}
          cd $Z4H_DIR/$repo && {
            git fetch -p --recurse-submodules=on-demand -j 8 &&
            git log master..origin/master --oneline --graph --shortstat &&
            git merge -q || return
          } always {
            cd - > /dev/null
          }
        fi
      else
        print -ru2 -- ${(%):-"%F{3}z4h%f: installing %B${repo//\%/%%}%b"}
        >&2 git clone --depth=1 --recurse-submodules -j 8 -- \
          https://github.com/$repo.git $Z4H_DIR/$repo || return
      fi
    done

    (( update )) && print -n >$Z4H_DIR/.last-update-ts

    if (( _z4h_initialized )); then
      print -ru2 -- ${(%):-"%F{3}z4h%f: restarting zsh"}
      exec -- $Z4H_ZSH
    else
      typeset -gri _z4h_initialized=1
    fi
  } always {
    (( $? )) || return
    local retry
    (( _z4h_initialized )) || retry="; type %F{2}%Uexec%u zsh%f to retry"
    print -ru2 -- ${(%):-"%F{3}z4h%f: %F{1}failed to pull dependencies%f$retry"}
  }
}

z4h init || return

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# When a command is running, display it in the terminal title.
function _z4h-set-term-title-preexec() {
  emulate -L zsh
  print -rn -- $'\e]0;'${(V%):-"%M#"}${(V%)1}$'\a' >$TTY
}
# When no command is running, display the current directory in the terminal title.
function _z4h-set-term-title-precmd() {
  emulate -L zsh
  print -rn -- $'\e]0;'${(V%):-"%M:%."}$'\a' >$TTY
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _z4h-set-term-title-preexec
add-zsh-hook precmd _z4h-set-term-title-precmd
_z4h-set-term-title-precmd

# Enable command_not_found_handler if possible.
if (( $+functions[command_not_found_handler] )); then
  # already installed
elif [[ -e /etc/zsh_command_not_found ]]; then
  source /etc/zsh_command_not_found
elif [[ -e /usr/share/doc/pkgfile/command-not-found.zsh ]]; then
  source /usr/share/doc/pkgfile/command-not-found.zsh
elif [[ -x /usr/libexec/pk-command-not-found && -S /var/run/dbus/system_bus_socket ]]; then
  command_not_found_handler() { /usr/libexec/pk-command-not-found "$@" }
elif [[ -x /data/data/com.termux/files/usr/libexec/termux/command-not-found ]]; then
  command_not_found_handler() { /data/data/com.termux/files/usr/libexec/termux/command-not-found "$@" }
elif [[ -x /run/current-system/sw/bin/command-not-found ]]; then
  command_not_found_handler() { /run/current-system/sw/bin/command-not-found "$@" }
elif (( $+commands[brew] )); then
  () {
    emulate -L zsh -o extended_glob
    [[ -n $TTY && ( -n $CONTINUOUS_INTEGRATION || -z $MC_SID ) ]] || return
    local repo
    repo="$(brew --repository 2>/dev/null)" || return
    [[ -n $repo/Library/Taps/*/*/cmd/command-not-found-init(|.rb)(#q.N) ]] || return
    autoload -Uz is-at-least
    function command_not_found_handler() {
      emulate -L zsh
      local msg
      if msg="$(brew which-formula --explain $1 2>/dev/null)" && [[ -n $msg ]]; then
        print -ru2 -- $msg
      elif is-at-least 5.3; then
        print -ru2 -- "zsh: command not found: $1"
      fi
      return 127
    }
  }
elif (( $+commands[dnf] )); then
  function command_not_found_handler() {
    echo "zsh: command not found: $1"
    dnf provides "$1"
  }
fi

# The same as up-line-or-history but for local history.
function z4h-up-line-or-history-local() {
  emulate -L zsh
  local last=$LASTWIDGET
  zle .set-local-history 1
  () { local -h LASTWIDGET=$last; zle up-line-or-history "$@" } "$@"
  zle .set-local-history 0
}

# The same as down-line-or-history but for local history.
function z4h-down-line-or-history-local() {
  emulate -L zsh
  local last=$LASTWIDGET
  zle .set-local-history 1
  () { local -h LASTWIDGET=$last; zle down-line-or-history "$@" } "$@"
  zle .set-local-history 0
}

# Widgets for changing current working directory.
function z4h-redraw-prompt() {
  emulate -L zsh
  local f
  for f in chpwd $chpwd_functions precmd $precmd_functions; do
    (( $+functions[$f] )) && $f &>/dev/null
  done
  zle .reset-prompt
  zle -R
}
function z4h-cd-rotate() {
  emulate -L zsh
  while (( $#dirstack )) && ! pushd -q $1 &>/dev/null; do
    popd -q $1
  done
  if (( $#dirstack )); then
    z4h-redraw-prompt
  fi
}
function z4h-cd-back() { z4h-cd-rotate +1 }
function z4h-cd-forward() { z4h-cd-rotate -0 }
function z4h-cd-up() { cd .. && z4h-redraw-prompt }

autoload -Uz up-line-or-history down-line-or-history run-help
(( $+aliases[run-help] )) && unalias run-help  # make alt-h binding more useful

function complete-file() {
  local old_completer
  zstyle -g old_completer ':completion:*' completer
  zstyle ':completion:*' completer _files
  zle fzf-tab-complete
  zstyle ':completion:*' completer $old_completer
}

zle -N complete-file
zle -N z4h-up-line-or-history-local
zle -N z4h-down-line-or-history-local
zle -N z4h-cd-back
zle -N z4h-cd-forward
zle -N z4h-cd-up

zmodload zsh/terminfo
if (( terminfo[colors] >= 256 )); then
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'         # the default is hard to see
  typeset -A ZSH_HIGHLIGHT_STYLES=(comment fg=96)  # different colors for comments and suggestions
else
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=black,bold'  # the default is outside of 8 color range
fi

ZSH_HIGHLIGHT_MAXLENGTH=1024                       # don't colorize long command lines (slow)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)         # main syntax highlighting plus matching brackets
ZSH_AUTOSUGGEST_MANUAL_REBIND=1                    # disable a very slow obscure feature

PROMPT_EOL_MARK='%K{red} %k'   # mark the missing \n at the end of a comand output with a red block
READNULLCMD=less               # use `less` instead of the default `more`
WORDCHARS=''                   # only alphanums make up words in word-based zle widgets
ZLE_REMOVE_SUFFIX_CHARS=''     # don't eat space when typing '|' after a tab completion
zle_highlight=('paste:none')   # disable highlighting of text pasted into the command line

: ${HISTFILE:=${ZDOTDIR:-~}/.zsh_history}  # save command history in this file
HISTSIZE=1000000000                        # infinite command history
SAVEHIST=1000000000                        # infinite command history

bindkey -v  # enable vim keymap

FZF_COMPLETION_TRIGGER=''                                # ctrl-t goes to fzf whenever possible
z4h source ~/.fzf.zsh                                    # load fzf
bindkey -r '^[c'                                         # remove unwanted binding

FZF_TAB_PREFIX=                                 # remove '·'
FZF_TAB_SHOW_GROUP=brief                        # show group headers only for duplicate options
bindkey '\t' expand-or-complete                 # fzf-tab reads it during initialization
z4h source $Z4H_DIR/Aloxaf/fzf-tab/fzf-tab.zsh  # load fzf-tab-complete

# Do nothing on pageup and pagedown. Better than printing '~'.
bindkey -s '^[[5~' ''
bindkey -s '^[[6~' ''

bindkey '^[[A'    z4h-up-line-or-history-local            # up         prev command in local history
bindkey '^[[B'    z4h-down-line-or-history-local          # down       next command in local history
bindkey '^?'      backward-delete-char                    # bs         delete one char backward
bindkey '^[[1;5C' forward-word                            # ctrl+right go forward one word
bindkey '^[[1;5D' backward-word                           # ctrl+left  go backward one word
bindkey '^W'      backward-kill-word                      # ctrl+w     delete previous word
bindkey '^[[1;5A' up-line-or-history                      # ctrl+up    prev cmd in global history
bindkey '^[[1;5B' down-line-or-history                    # ctrl+down  next cmd in global history
bindkey '^E'      _expand_alias                           # ctrl+E     expand alias
bindkey '^ '      end-of-line                             # ctrl+space go to the end of line
bindkey '^[[1;2D' z4h-cd-back                             # ⇧+left     cd into the prev directory
bindkey '^[[1;2C' z4h-cd-forward                          # ⇧+right    cd into the next directory
bindkey '^[[1;2A' z4h-cd-up                               # ⇧+up       cd ..
bindkey '^[[1;2B' fzf-cd-widget                           # ⇧+down     fzf cd
bindkey '\t'      fzf-tab-complete                        # tab        fzf-tab completion
bindkey '^F'      complete-file                           # ctrl+f     fzf file completion
bindkey '^T'      fzf-completion                          # ctrl+t     default fzf completion
bindkey -M vicmd  'K'   run-help                          # normal-K   help for the cmd at cursor

# Tell zsh-autosuggestions how to handle different widgets.
typeset -g ZSH_AUTOSUGGEST_EXECUTE_WIDGETS=()
typeset -g ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(end-of-line vi-end-of-line vi-add-eol)
typeset -g ZSH_AUTOSUGGEST_CLEAR_WIDGETS=(
  history-search-forward
  history-search-backward
  history-substring-search-up
  history-substring-search-down
  up-line-or-history
  down-line-or-history
  accept-line
  z4h-up-line-or-history-local
  z4h-down-line-or-history-local
  _expand_alias
  fzf-tab-complete
  complete-file
)
typeset -g ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(
  forward-word
  vi-forward-word
  vi-forward-word-end
  vi-forward-blank-word
  vi-forward-blank-word-end
  vi-find-next-char
  vi-find-next-char-skip
  forward-char            # right arrow accepts a single character; press end to accept to the end
  vi-forward-char
)
typeset -g ZSH_AUTOSUGGEST_IGNORE_WIDGETS=(
  orig-\*
  beep
  run-help
  set-local-history
  which-command
  yank
  yank-pop
  zle-\*
)

# Use lesspipe if available. It allows you to use less on binary files (zip archives, etc.).
if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

# This affects every invocation of `less`.
#   -i   case-insensitive search unless search string contains uppercase letters
#   -R   color
#   -F   exit if there is less than one page of content
#   -M   show more info at the bottom prompt line
#   -x4  tabs are 4 spaces wide instead of 8
#   --mouse  enable mouse support in tmux, but breaks selections
if [ -n "$TMUX" ]; then
    export LESS="-iRFMx4 --mouse"
else
    export LESS="-iRFMx4"
fi

# Export variables.
export PAGER=less

typeset -gaU cdpath fpath mailpath path
fpath+=($Z4H_DIR/zsh-users/zsh-completions/src)

# Initialize completions.
autoload -Uz compinit
compinit -d ${XDG_CACHE_HOME:-~/.cache}/.zcompdump-$ZSH_VERSION

# Configure completions.
zstyle ':completion:*'                  matcher-list    'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'
zstyle ':completion:*:descriptions'     format          '[%d]'
zstyle ':completion:*'                  completer       _complete
zstyle ':completion:*:*:-subscript-:*'  tag-order       indexes parameters
zstyle ':completion:*'                  squeeze-slashes true
zstyle '*'                              single-ignored  show
zstyle ':completion:*:(rm|kill|diff):*' ignore-line     other
zstyle ':completion:*:rm:*'             file-patterns   '*:all-files'
zstyle ':completion::complete:*'        use-cache       on
zstyle ':completion::complete:*'        cache-path      ${XDG_CACHE_HOME:-$HOME/.cache}/zcompcache-$ZSH_VERSION

# Make it possible to use completion specifications and functions written for bash.
autoload -Uz bashcompinit
bashcompinit

# Enable iTerm2 shell integration if available.
if [[ $TERM_PROGRAM == iTerm.app || $LC_TERMINAL == iTerm2 && -e ~/.iterm2_shell_integration.zsh ]]; then
  z4h source ~/.iterm2_shell_integration.zsh
fi

# Initialize prompt. Type `p10k configure` or edit .p10k.zsh to customize it.
[[ -e ${ZDOTDIR:-~}/.p10k.zsh ]] && z4h source ${ZDOTDIR:-~}/.p10k.zsh

# Customize p10k config to show time with every previous command
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS+=(command_execution_time time)
POWERLEVEL9K_TIME_FORMAT="%D{%d/%m %H:%M:%S}"
POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=true
function p10k-on-pre-prompt() { p10k display '1|2/left/prompt_char|2/right'=show '2/left/time|2/left/command_execution_time'=hide }
function p10k-on-post-prompt() { p10k display '1|2/left/prompt_char|2/right'=hide '2/left/time|2/left/command_execution_time'=show }

POWERLEVEL9K_SHORTEN_STRATEGY=truncate_middle  # Default truncate_to_unique is nice but hangs on super-large dirs
z4h source $Z4H_DIR/romkatv/powerlevel10k/powerlevel10k.zsh-theme

z4h source $Z4H_DIR/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
# zsh-syntax-highlighting must be loaded after all widgets have been defined.
z4h source $Z4H_DIR/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

autoload -Uz zcalc zmv zcp zln # enable a bunch of awesome zsh commands

# Aliases.
if (( $+commands[dircolors] )); then  # proxy for GNU coreutils vs BSD
  alias diff='diff --color=auto'
  alias ls='ls --color=auto'
else
  alias ls='ls -G'
fi
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias tree='tree -aC -I .git'

if [[ -f /usr/bin/ffmpeg ]] ; then
  FFMPEG=/usr/bin/ffmpeg
elif [[ -f /opt/homebrew/bin/ffmpeg ]] ; then
  FFMPEG=/opt/homebrew/bin/ffmpeg
else
  FFMPEG=ffmpeg
fi
alias ffmpeg="$FFMPEG -hide_banner"

alias cfg="GIT_DIR=$HOME/.dotfiles.git"
alias psync="rsync -a --no-i-r --info=progress2 --partial"
alias num_frames="ffprobe -v error -select_streams v:0 -of csv=p=0 -show_entries stream=nb_frames"
alias frame_rate="ffprobe -v error -select_streams v:0 -of csv=p=0 -show_entries stream=r_frame_rate"
alias timestamps="ffprobe -v error -select_streams v:0 -of csv=p=0 -show_entries frame=coded_picture_number,pts_time"
alias tempssh="ssh -o UserKnownHostsFile=/dev/null"
alias ffprobe="ffprobe -hide_banner"

export NVIMRC=~/.config/nvim/init.lua
export EDITOR=nvim
export VISUAL=nvim
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
[ "${HOST##*internal*}" ] || export iterm2_hostname="$(hostname -f | sed -E 's/\.internal//')"
[ -d ~/.emacs.d ] && path=(~/.emacs.d/bin $path)
[ -d "$HOME/.atuin" ] && source "$HOME/.atuin/bin/env"
[ -d ~/.cargo/bin ] && path=(~/.cargo/bin $path)
[ -f ~/.additional.zsh ] && source ~/.additional.zsh
[ ${path[(i)$HOME/.local/bin]} -gt ${#path} ] && path=(~/.local/bin $path)

# Enable decent options. See http://zsh.sourceforge.net/Doc/Release/Options.html.
emulate zsh                    # restore default options just in case something messed them up
setopt ALWAYS_TO_END           # full completions move cursor to the end
setopt AUTO_CD                 # `dirname` is equivalent to `cd dirname`
setopt AUTO_PARAM_SLASH        # if completed parameter is a directory, add a trailing slash
setopt AUTO_PUSHD              # `cd` pushes directories to the directory stack
setopt COMPLETE_IN_WORD        # complete from the cursor rather than from the end of the word
setopt EXTENDED_GLOB           # more powerful globbing
setopt EXTENDED_HISTORY        # write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST  # if history needs to be trimmed, evict dups first
setopt HIST_FIND_NO_DUPS       # don't show dups when searching history
setopt HIST_IGNORE_DUPS        # don't add consecutive dups to history
setopt HIST_IGNORE_SPACE       # don't add commands starting with space to history
setopt HIST_VERIFY             # if a command triggers history expansion, show it instead of running
setopt INTERACTIVE_COMMENTS    # allow comments in command line
setopt MULTIOS                 # allow multiple redirections for the same fd
setopt NO_BG_NICE              # don't nice background jobs
setopt NO_FLOW_CONTROL         # disable start/stop characters in shell editor
setopt PATH_DIRS               # perform path search even on command names with slashes
setopt SHARE_HISTORY           # write and import history on every command
setopt C_BASES                 # print hex/oct numbers as 0xFF/077 instead of 16#FF/8#77

eval "$(atuin init zsh --disable-up-arrow)"  # Initialize atuin history
export VIDFLAGS=(-b:v 0 -crf 18 -profile:v high444 -preset veryfast -tune zerolatency -movflags +faststart)

# Activate base python env (needs to be done at the end since deactivate pops the path from there)
[ -d ~/basepython/bin ] && source ~/basepython/bin/activate
