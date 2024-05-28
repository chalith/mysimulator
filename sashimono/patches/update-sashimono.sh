#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Please run with root privileges (sudo)." && exit 1

repo_owner="chalith"
repo_name="mysimulator"
file="sagent"

export SASHIMONO_BIN=/usr/bin/sashimono
export SASHIMONO_SERVICE="sashimono-agent"

[ ! -f "$SASHIMONO_BIN/$file" ] && echo "Sashimono is not installed on your machine." && exit 1

echo "Backing up the files.."

timestamp=$(date +%s)
backup_file="$SASHIMONO_BIN/$file-$timestamp.bk"
mv "$SASHIMONO_BIN/$file" "$backup_file"

echo "Updating the files.."

if (! curl "https://raw.githubusercontent.com/$repo_owner/$repo_name/patch/sashimono/patches/resources/sashimono/$file" -o "$SASHIMONO_BIN/$file") || (! chmod +x "$SASHIMONO_BIN/$file"); then
    echo "Update failed. Restoring.."
    ! cp "$backup_file" "$SASHIMONO_BIN/$file" && echo "Restoring failed." && exit 1
    echo "Restored."
    exit 1
fi

echo "Restarting Sashimono.."
! sudo systemctl restart $SASHIMONO_SERVICE && echo "Sashimono restart failed." && exit 1

echo "Sashimono successfully updated!"
