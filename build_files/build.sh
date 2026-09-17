#!/bin/bash
set -ouex pipefail

# ---------------------------------------------------------------------------
# Custom Bazzite image – build script
#
# This runs INSIDE the container build on GitHub Actions, not on a live system.
# The repository contents are mounted at /ctx.
# ---------------------------------------------------------------------------

# Copy everything from system_files/ into the image root.
cp -avf "/ctx/system_files"/. /

# ---------------------------------------------------------------------------
# 1) RPM packages (Fedora repos + RPM Fusion, both enabled on ublue images)
#
#    IMPORTANT: only put things here that genuinely belong in the OS layer.
#    GUI applications should be Flatpaks (see flatpaks.list) or Homebrew/
#    distrobox, so the image stays small and updates stay fast.
# ---------------------------------------------------------------------------
RPM_PACKAGES=(
  # (coolercontrol and liquidctl are NOT here -- they need the Terra repo,
  #  see the separate block below.)
  # --- shell & CLI ---
  git
  ddrescue
  eza
  zoxide
  # zsh    -- dropped on purpose, replaced by bash + starship (COPR, see below)
  # starship -- not packaged in Fedora, comes from a COPR below
  # fzf    -- already part of the Bazzite base image
  # --- media ---
  mkvtoolnix
  # --- gaming / memory tools ---
  scanmem
  gameconqueror
  # --- session ---
  numlockx
)

dnf5 install -y "${RPM_PACKAGES[@]}"

# NOTE: all of the above were verified as layered on the target machine, so they
# resolve from the repos that Bazzite enables by default. If the build fails on
# one of them, find out which repo it came from by running this on the machine:
#   dnf5 repoquery --qf '%{name}  ->  %{repoid}\n' <package>
# and enable that repo below before installing.

# ---------------------------------------------------------------------------
# 2) Packages from COPR repositories
#    Always disable the COPR again afterwards, otherwise it stays enabled on
#    the installed system and can break future rebases.
# ---------------------------------------------------------------------------

# --- starship ---------------------------------------------------------------
# Not packaged in Fedora. The source recommended by the starship project for
# Fedora is the atim COPR.
dnf5 -y copr enable atim/starship
dnf5 -y install starship
dnf5 -y copr disable atim/starship

# --- Terra repository -------------------------------------------------------
# coolercontrol and liquidctl live in Terra, which Bazzite ships DISABLED.
# This mirrors exactly what `ujust install-coolercontrol` does, except that we
# switch the repo off again so the finished image stays as Bazzite intends it.
TERRA_REPO="/etc/yum.repos.d/terra.repo"
if [ -f "${TERRA_REPO}" ]; then
    sed -i 's@enabled=0@enabled=1@g' "${TERRA_REPO}"
    dnf5 install -y coolercontrol liquidctl
    sed -i 's@enabled=1@enabled=0@g' "${TERRA_REPO}"
else
    echo "ERROR: ${TERRA_REPO} not found in the base image." >&2
    exit 1
fi

# (No COPR needed. Both Nerd Fonts ship as files under
#  system_files/usr/share/fonts/ and are registered below.)

# Register the fonts copied in from system_files/.
fc-cache --force --system-only

# ---------------------------------------------------------------------------
# 3) Packages to remove from the base image
# ---------------------------------------------------------------------------
# dnf5 remove -y <package>

# ---------------------------------------------------------------------------
# 4) Enable systemd units shipped via system_files/
# ---------------------------------------------------------------------------
systemctl enable bazzite-custom-flatpaks.service

# CoolerControl daemon. Its RPM preset is "disabled"; on the running machine it
# was explicitly enabled, so we reproduce that here.
systemctl enable coolercontrold.service

# Sunshine autostart. --global enables a user unit for every user, so it does
# not depend on anything in /home and survives a reinstall.
systemctl --global enable app-dev.lizardbyte.app.Sunshine.service

# ---------------------------------------------------------------------------
# 5) Cleanup
# ---------------------------------------------------------------------------
dnf5 clean all
