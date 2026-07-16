# ~/.zshrc: interactive zsh config for both macOS and WSL/Linux.
# Uses oh-my-zsh + powerlevel10k when installed (macOS setup); otherwise falls
# back to a self-contained config ported from .bashrc (same prompt, aliases,
# WSL git.exe) with fish-style autosuggestions + command syntax highlighting.

# If not running interactively, don't do anything.
[[ -o interactive ]] || return

if [[ -d "$HOME/.oh-my-zsh" ]]; then
	# --- macOS: oh-my-zsh + powerlevel10k ---

	# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
	# Initialization code that may require console input (password prompts, [y/n]
	# confirmations, etc.) must go above this block; everything else may go below.
	if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
		source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
	fi

	# Path to your oh-my-zsh installation.
	export ZSH="$HOME/.oh-my-zsh"

	ZSH_THEME="powerlevel10k/powerlevel10k"

	plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)

	source $ZSH/oh-my-zsh.sh

	# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
	[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
	alias code="/Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron"
	export PATH="$HOME/.local/bin:$PATH"
else
	# --- WSL/Linux: self-contained config ported from .bashrc ---

	# --- History ---
	HISTFILE="$HOME/.zsh_history"
	HISTSIZE=1000
	SAVEHIST=2000
	setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

	# --- PATH ---
	# Prefer user-local bins; Windows tools come from WSL interop, no need to pin them.
	typeset -U path
	[[ -d $HOME/bin ]] && path=("$HOME/bin" $path)
	[[ -d $HOME/.local/bin ]] && path=("$HOME/.local/bin" $path)

	# --- Completion: case-insensitive + substring matching (replaces the old cd *foo hack) ---
	autoload -Uz compinit && compinit
	zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'
	zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
	zstyle ':completion:*' menu select

	# --- Aliases ---
	if ls --color=auto >/dev/null 2>&1; then
		alias ls='ls --color=auto'   # GNU/Linux
	else
		alias ls='ls -G'             # BSD/macOS
	fi
	alias grep='grep --color=auto'
	alias ll='ls -alF'
	alias la='ls -A'
	alias l='ls -CF'

	# --- WSL-only: use Windows git on /mnt/c (much faster than Linux git on DrvFs) ---
	if [[ -n ${WSL_DISTRO_NAME-} ]]; then
		alias git=git.exe
	fi

	# --- Compact git-aware prompt (ported from .bashrc) ---
	# branch ↑ahead ↓behind +staged ~modified ?untracked ✗conflicts ⚑stashed
	# single git call per prompt; git.exe on /mnt/* (DrvFs) where Linux git is slow
	setopt PROMPT_SUBST
	autoload -Uz add-zsh-hook

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
				[12]' '*)          [[ ${line[3]} != . ]] && (( staged++ ))
				                   [[ ${line[4]} != . ]] && (( changed++ )) ;;
				'u '*)             (( conflicts++ )) ;;
				'? '*)             (( untracked++ )) ;;
			esac
		done <<< "$out"

		[[ $branch == '(detached)' ]] && branch="@${oid[1,7]}"

		local s=" %F{yellow}(${branch}"
		(( ahead ))     && s+=" %F{cyan}↑${ahead}%F{yellow}"
		(( behind ))    && s+=" %F{cyan}↓${behind}%F{yellow}"
		(( staged ))    && s+=" %F{green}+${staged}%F{yellow}"
		(( changed ))   && s+=" %F{red}~${changed}%F{yellow}"
		(( untracked )) && s+=" %F{red}?${untracked}%F{yellow}"
		(( conflicts )) && s+=" %F{red}✗${conflicts}%F{yellow}"
		(( stash ))     && s+=" %F{cyan}⚑${stash}%F{yellow}"
		print -n "${s})%f"
	}

	# %3~ = last 3 path components (matches PROMPT_DIRTRIM=3)
	PROMPT='%B%F{blue}%3~%f%b$(__git_prompt) $ '

	# keep full info in the window title
	_set_title() { print -Pn "\e]0;%n@%m: %~\a" }
	case $TERM in
		xterm* | *rxvt*) add-zsh-hook precmd _set_title ;;
	esac

	# --- Plugins ---
	# autosuggestion.enable = true
	for p in \
		/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
		/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
		/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
		[[ -r $p ]] && { source "$p"; break; }
	done

	# syntaxHighlighting.enable = true  (must be sourced last)
	for p in \
		/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
		/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
		/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
		[[ -r $p ]] && { source "$p"; break; }
	done
fi

# Shared, shell-agnostic aliases (also sourced by .bashrc on WSL/Linux)
if [ -f ~/.shell_aliases ]; then
	. ~/.shell_aliases
fi
