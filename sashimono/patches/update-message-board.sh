#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Please run with root privileges (sudo)." && exit 1

repo_owner="chalith"
repo_name="mysimulator"
file="index.js"

export SASHIMONO_BIN=/usr/bin/sashimono
export MB_XRPL_SERVICE="sashimono-mb-xrpl"
export MB_XRPL_USER="sashimbxrpl"
export MB_XRPL_BIN=$SASHIMONO_BIN/mb-xrpl

[ ! -f "$MB_XRPL_BIN/$file" ] && echo "Sashimono is not installed on your machine." && exit 1

echo "Backing up the files.."

timestamp=$(date +%s)
backup_file="$MB_XRPL_BIN/$file-$timestamp.bk"
mv "$MB_XRPL_BIN/$file" "$backup_file"

echo "Updating the files.."

if (! curl "https://raw.githubusercontent.com/$repo_owner/$repo_name/patch/sashimono/patches/resources/mb-xrpl/$file" -o "$MB_XRPL_BIN/$file") && chmod +x "$MB_XRPL_BIN/$file"; then
    echo "Update failed. Restoring.."
    ! cp "$backup_file" "$MB_XRPL_BIN/$file" && echo "Restoring failed." && exit 1
    echo "Restored."
    exit 1
fi

echo "Restarting the message board.."

mb_user_id=$(id -u "$MB_XRPL_USER")
mb_user_runtime_dir="/run/user/$mb_user_id"

! sudo -u "$MB_XRPL_USER" XDG_RUNTIME_DIR="$mb_user_runtime_dir" systemctl --user restart $MB_XRPL_SERVICE && echo "Message board restart failed." && exit 1

echo "Message board successfully updated!"
