#!/usr/bin/env bash
# Claude Code status line: model, working dir + branch, context and plan usage.
# Runs on every render, so it stays to one jq pass and reads git state from
# .git directly instead of spawning git.
set -uo pipefail

input=$(cat)

# One field per line: mapfile keeps blank lines, so an absent value stays in
# its slot. Splitting on tabs would not - bash collapses runs of whitespace.
mapfile -t f < <(
	printf '%s' "$input" | jq -r '
		def pct: if . == null then "" else (floor | tostring) end;
		[ .model.display_name // "?"
		, .workspace.current_dir // .cwd // ""
		, (.context_window.used_percentage | pct)
		, (.rate_limits.five_hour.used_percentage | pct)
		, (.rate_limits.seven_day.used_percentage | pct)
		, (.cost.total_cost_usd // 0)
		] | .[]'
)

model=${f[0]:-?} dir=${f[1]-} ctx=${f[2]-} five=${f[3]-} week=${f[4]-} cost=${f[5]:-0}

# Base ANSI colors, not a 256-colour ramp, so the bar follows the terminal
# theme the way the dark-ansi Claude theme does.
RESET=$'\e[0m'
DIM=$'\e[2m'
C_MODEL=$'\e[36m'
C_DIR=$'\e[32m'
SEP="${DIM}│${RESET}"

# Green under half, amber past 50%, red past 80%.
heat() {
	if [ "$1" -ge 80 ]; then printf '\e[31m'
	elif [ "$1" -ge 50 ]; then printf '\e[33m'
	else printf '\e[32m'
	fi
}

# Deep monorepo paths would eat the whole bar, so keep the last two segments.
short_path() {
	local p="${1/#$HOME/\~}"
	case "$p" in
	*/*/*) printf '…/%s' "${p#"${p%/*/*}/"}" ;;
	*) printf '%s' "$p" ;;
	esac
}

git_branch() {
	local d="$1" gitdir head
	while [ -n "$d" ] && [ "$d" != "/" ]; do
		if [ -d "$d/.git" ]; then
			gitdir="$d/.git"
		elif [ -f "$d/.git" ]; then
			read -r _ gitdir <"$d/.git" || return 0 # "gitdir: <path>"
		else
			d="${d%/*}"
			continue
		fi
		[ -r "$gitdir/HEAD" ] || return 0
		read -r head <"$gitdir/HEAD"
		case "$head" in
		"ref: refs/heads/"*) printf '%s' "${head#ref: refs/heads/}" ;;
		*) printf '%s' "${head:0:7}" ;; # detached HEAD
		esac
		return 0
	done
}

out="${C_MODEL}${model/ (1M context)/ 1M}${RESET}"

if [ -n "$dir" ]; then
	out+=" ${SEP} ${C_DIR}$(short_path "$dir")${RESET}"
	branch=$(git_branch "$dir")
	[ -n "$branch" ] && out+=" ${DIM}(${branch})${RESET}"
fi

[ -n "$ctx" ] && out+=" ${SEP} $(heat "$ctx")ctx ${ctx}%${RESET}"

# rate_limits is subscription-only and absent until the first API response.
usage=""
[ -n "$five" ] && usage+="$(heat "$five")5h ${five}%${RESET}"
[ -n "$week" ] && usage+="${usage:+${DIM} · ${RESET}}$(heat "$week")7d ${week}%${RESET}"
[ -n "$usage" ] && out+=" ${SEP} ${DIM}usage${RESET} ${usage}"

spend=$(printf '%.2f' "$cost" 2>/dev/null) || spend="0.00"
[ "$spend" != "0.00" ] && out+=" ${SEP} ${DIM}\$${spend}${RESET}"

printf '%s' "$out"
