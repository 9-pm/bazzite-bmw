# Enable the starship prompt for interactive bash sessions.
# Fedora's /etc/bashrc sources /etc/profile.d/*.sh for interactive shells,
# so this covers both login and non-login terminals.

# bash only
[ -n "${BASH_VERSION}" ] || return 0

# interactive only
case $- in
    *i*) ;;
    *) return 0 ;;
esac

command -v starship >/dev/null 2>&1 || return 0

# A user config in ~/.config/starship.toml always wins over the image default.
if [ ! -f "${HOME}/.config/starship.toml" ]; then
    STARSHIP_CONFIG="/usr/share/bazzite-custom/starship.toml"
    export STARSHIP_CONFIG
fi

eval "$(starship init bash)"
