#!/bin/bash
# Installs the Flatpaks declared in the image. Idempotent: it only does real
# work when the list file changed since the last successful run.
set -euo pipefail

LIST_FILE="/usr/share/bazzite-custom/flatpaks.list"
STAMP_DIR="/var/lib/bazzite-custom"
STAMP_FILE="${STAMP_DIR}/flatpaks.sha256"

[[ -r "${LIST_FILE}" ]] || exit 0

current_hash="$(sha256sum "${LIST_FILE}" | awk '{print $1}')"
if [[ -r "${STAMP_FILE}" && "$(cat "${STAMP_FILE}")" == "${current_hash}" ]]; then
    exit 0
fi

flatpak remote-add --if-not-exists --system \
    flathub https://dl.flathub.org/repo/flathub.flatpakrepo

mapfile -t apps < <(grep -vE '^[[:space:]]*(#|$)' "${LIST_FILE}")

failed=0
for app in "${apps[@]}"; do
    if ! flatpak install --system --noninteractive --or-update flathub "${app}"; then
        echo "WARNING: could not install ${app}" >&2
        failed=1
    fi
done

# Only write the stamp on a fully clean run, so failures are retried next boot.
if [[ "${failed}" -eq 0 ]]; then
    mkdir -p "${STAMP_DIR}"
    printf '%s\n' "${current_hash}" >"${STAMP_FILE}"
fi
