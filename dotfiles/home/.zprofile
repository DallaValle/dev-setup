# macOS: put Homebrew on PATH (Apple Silicon location). Guarded so this file is
# a no-op on machines without Homebrew (e.g. WSL/Linux).
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
