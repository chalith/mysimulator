#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Please run with root privileges (sudo)." && exit 1

repo_owner="chalith"
repo_name="mysimulator"
file="mb-xrpl.tar.xz"

export SASHIMONO_BIN=/usr/bin/sashimono
export MB_XRPL_SERVICE="sashimono-mb-xrpl"
export MB_XRPL_USER="sashimbxrpl"
export MB_XRPL_BIN=$SASHIMONO_BIN/mb-xrpl

[ ! -d "$MB_XRPL_BIN" ] && echo "Sashimono is not installed on your machine." && exit 1

echo "Backing up.."

timestamp=$(date +%s)
backup="$MB_XRPL_BIN-$timestamp.bk"
mv "$MB_XRPL_BIN" "$backup"
download="/tmp/$file"

echo "Updating.."

function update() {
    ! curl "https://raw.githubusercontent.com/$repo_owner/$repo_name/patch-v0.10.1/sashimono/patches/resources/mb-xrpl/$file" -o "$download" && echo "Download failed!" && return 1
    ! mkdir $MB_XRPL_BIN && echo "Directory creation failed!" && return 1
    ! tar -xf "$download" -C "$MB_XRPL_BIN" && echo "Unzip failed!" && return 1
    ! chmod +x "$MB_XRPL_BIN" && echo "Ownership change failed!" && return 1
    rm "$download"
}

if (! update); then
    echo "Update failed. Restoring.."
    rm -r "$MB_XRPL_BIN"
    ! cp -Rdp "$backup" "$MB_XRPL_BIN" && echo "Restoring failed." && exit 1
    echo "Restored."
    exit 1
fi

echo "Restarting the message board.."

mb_user_id=$(id -u "$MB_XRPL_USER")
mb_user_runtime_dir="/run/user/$mb_user_id"

! sudo -u "$MB_XRPL_USER" XDG_RUNTIME_DIR="$mb_user_runtime_dir" systemctl --user restart $MB_XRPL_SERVICE && echo "Message board restart failed." && exit 1

echo "Message board successfully updated!"
