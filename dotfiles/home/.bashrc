# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Keep native tools ahead of Windows interop without replacing the inherited PATH.
for bin_dir in "$HOME/bin" "$HOME/.local/bin" "$HOME/.local/node/bin"; do
    [ ! -d "$bin_dir" ] || PATH="$bin_dir:$PATH"
done
export PATH

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- cd substring/fuzzy completion (like PS1 "cd *mcp") ---
_cd_substring_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local matches=()
    local d nocasematch_enabled=0
    shopt -q nocasematch && nocasematch_enabled=1
    shopt -s nocasematch
    for d in */ ; do
        [ -d "$d" ] || continue
        d="${d%/}"
        if [[ "$d" == *"$cur"* ]]; then
            matches+=("$d")
        fi
    done
    COMPREPLY=("${matches[@]}")
    [ "$nocasematch_enabled" = 1 ] || shopt -u nocasematch
}
complete -F _cd_substring_complete cd

# --- Compact git-aware prompt ---
PROMPT_DIRTRIM=3
# branch ↑ahead ↓behind +staged ~modified ?untracked ✗conflicts ⚑stashed
# single git call per prompt; git.exe on /mnt/* (DrvFs) where Linux git is slow
__git_prompt() {
    local g=git
    case $PWD in /mnt/*) g=git.exe ;; esac

    local out
    out=$("$g" --no-optional-locks status --porcelain=v2 --branch --show-stash 2>/dev/null) || return

    local branch='' oid='' ab ahead=0 behind=0 stash=0 staged=0 changed=0 untracked=0 conflicts=0 line
    while IFS= read -r line; do
        line=${line%$'\r'}
        case $line in
            '# branch.head '*) branch=${line#'# branch.head '} ;;
            '# branch.oid '*)  oid=${line#'# branch.oid '} ;;
            '# branch.ab '*)   ab=${line#'# branch.ab '}
                               ahead=${ab%% *};  ahead=${ahead#+}
                               behind=${ab##* }; behind=${behind#-} ;;
            '# stash '*)       stash=${line#'# stash '} ;;
            [12]' '*)          [ "${line:2:1}" != . ] && ((staged++))
                               [ "${line:3:1}" != . ] && ((changed++)) ;;
            'u '*)             ((conflicts++)) ;;
            '? '*)             ((untracked++)) ;;
        esac
    done <<<"$out"

    [ "$branch" = '(detached)' ] && branch="@${oid:0:7}"

    # \001/\002 = readline's "invisible chars" markers (the \[ \] of PS1 don't
    # survive command substitution)
    local Y=$'\001\e[0;33m\002' G=$'\001\e[0;32m\002' R=$'\001\e[0;31m\002' C=$'\001\e[0;36m\002' X=$'\001\e[0m\002'
    local s=" ${Y}(${branch}"
    ((ahead))     && s+=" ${C}↑${ahead}${Y}"
    ((behind))    && s+=" ${C}↓${behind}${Y}"
    ((staged))    && s+=" ${G}+${staged}${Y}"
    ((changed))   && s+=" ${R}~${changed}${Y}"
    ((untracked)) && s+=" ${R}?${untracked}${Y}"
    ((conflicts)) && s+=" ${R}✗${conflicts}${Y}"
    ((stash))     && s+=" ${C}⚑${stash}${Y}"
    printf '%s)%s' "$s" "$X"
}
PS1='\[\e[1;34m\]\w\[\e[0m\]$(__git_prompt)\[\e[0m\] \$ '
# keep full info in the window title
PS1="\[\e]0;\u@\h: \w\a\]$PS1"
# --- WSL-only: Windows interop (skipped on mac/Linux) ---
if [ -n "${WSL_DISTRO_NAME-}" ]; then
    # Use Windows git on /mnt/c (much faster than Linux git on DrvFs)
    alias git=git.exe
fi


# Claude Code and Codex in auto mode (no permission prompts)
alias cc="claude --dangerously-skip-permissions"
alias cx="codex --dangerously-bypass-approvals-and-sandbox"
