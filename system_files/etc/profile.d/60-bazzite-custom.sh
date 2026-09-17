# Personal shell environment, ported from the old ~/.zshrc.
# Lives in the image, so it survives a reinstall.

EDITOR="nano"
VISUAL="nano"
export EDITOR VISUAL

# Everything below is interactive-only.
[ -n "${BASH_VERSION}" ] || return 0
case $- in
    *i*) ;;
    *) return 0 ;;
esac

# On Fedora Atomic /home is a symlink to /var/home, so depending on how the
# shell was started it can begin in /var/home/<user>. That does not match $HOME
# literally, so the prompt prints the long path instead of "~".
# (Reinstated: this is NOT caused by the Flatpak terminal, it still occurs.)
if [ "${PWD}" = "/var/home/${USER}" ] && [ -d "${HOME}" ]; then
    cd "${HOME}" || true
fi

# zoxide: smarter "cd". Use `z <part-of-path>` to jump.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# fzf: Ctrl+R history search, Ctrl+T file picker.
if [ -f /usr/share/fzf/shell/key-bindings.bash ]; then
    . /usr/share/fzf/shell/key-bindings.bash
fi

# eza: modern ls. Delete these three lines if you prefer plain ls.
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --group-directories-first --git'
    alias la='eza -la --group-directories-first --git'
fi
