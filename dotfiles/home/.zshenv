# Ubuntu's /etc/zsh/zshrc runs its own compinit before ~/.zshrc is read, so it
# scans fpath before we can fix it up and errors on stale vendor completions
# (Docker Desktop's dangling _docker symlink). We run compinit ourselves.
skip_global_compinit=1
