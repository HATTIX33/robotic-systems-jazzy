#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

if [[ -z ${DISPLAY:-} ]]; then
    echo 'DISPLAY non impostato. Apri VS Code dalla sessione grafica Fedora.' >&2
    exit 1
fi

for device in /dev/dri /dev/snd /dev/bus/usb; do
    if [[ ! -d $device ]]; then
        printf 'Dispositivo host assente: %s. Controlla i --device in .devcontainer/devcontainer.json.\n' "$device" >&2
        exit 1
    fi
done

authority_file=${XAUTHORITY:-${HOME}/.Xauthority}
if [[ ! -r $authority_file || ! -s $authority_file ]]; then
    echo 'File XAUTHORITY assente, vuoto o non leggibile.' >&2
    echo 'Verifica XAUTHORITY nel terminale grafico Fedora e avvia code . dallo stesso terminale.' >&2
    exit 1
fi

if ! command -v xauth >/dev/null 2>&1; then
    echo 'Manca xauth su Fedora. Installa il pacchetto xorg-x11-xauth e riprova.' >&2
    exit 1
fi

# Only the X11 session cookie is copied; no SSH files are touched.
umask 077
mkdir -p "$project_dir/.devcontainer/.host"
chmod 0700 "$project_dir/.devcontainer/.host"
cookie_input=$(mktemp "$project_dir/.devcontainer/.host/.input.XXXXXX")
cookie_output=$(mktemp "$project_dir/.devcontainer/.host/.output.XXXXXX")
trap 'rm -f -- "$cookie_input" "$cookie_output"' EXIT
cat -- "$authority_file" > "$cookie_input"
# FamilyWild allows the same cookie to work with the container's hostname.
xauth -f "$cookie_input" nlist "$DISPLAY" \
    | sed 's/^..../ffff/' \
    | xauth -f "$cookie_output" nmerge -
if [[ ! -s $cookie_output ]]; then
    echo 'Nessun cookie X11 trovato per il DISPLAY corrente.' >&2
    exit 1
fi
# Keep the target inode: an existing container can still have this file mounted.
cat -- "$cookie_output" > "$project_dir/.devcontainer/.host/Xauthority"
chmod 0600 "$project_dir/.devcontainer/.host/Xauthority"
echo 'Autenticazione X11 preparata per la sessione Fedora corrente.'
