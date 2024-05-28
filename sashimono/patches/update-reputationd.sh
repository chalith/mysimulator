#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Please run with root privileges (sudo)." && exit 1

repo_owner="chalith"
repo_name="mysimulator"
file="index.js"

export SASHIMONO_BIN=/usr/bin/sashimono
export REPUTATIOND_SERVICE="sashimono-reputationd"
export REPUTATIOND_USER="sashireputationd"
export REPUTATIOND_BIN=$SASHIMONO_BIN/reputationd

[ ! -f "$REPUTATIOND_BIN/$file" ] && echo "Reputationd is not opted in on your machine." && exit 1

echo "Backing up the files.."

timestamp=$(date +%s)
backup_file="$REPUTATIOND_BIN/$file-$timestamp.bk"
mv "$REPUTATIOND_BIN/$file" "$backup_file"

echo "Updating the files.."

if (! curl "https://raw.githubusercontent.com/$repo_owner/$repo_name/patch/sashimono/patches/resources/reputationd/$file" -o "$REPUTATIOND_BIN/$file") && chmod +x "$REPUTATIOND_BIN/$file"; then
    echo "Update failed. Restoring.."
    ! cp "$backup_file" "$REPUTATIOND_BIN/$file" && echo "Restoring failed." && exit 1
    echo "Restored."
    exit 1
fi

if [ -f "/home/$REPUTATIOND_USER/.config/systemd/user/$REPUTATIOND_SERVICE.service" ]; then
    reputationd_user_id=$(id -u "$REPUTATIOND_USER")
    reputationd_user_runtime_dir="/run/user/$reputationd_user_id"
    evernode_reputationd_status=$(sudo -u "$REPUTATIOND_USER" XDG_RUNTIME_DIR="$reputationd_user_runtime_dir" systemctl --user is-active $REPUTATIOND_SERVICE)
    if [ "$evernode_reputationd_status" == "active" ]; then
        echo "Restarting the ReputationD.."
        ! sudo -u "$REPUTATIOND_USER" XDG_RUNTIME_DIR="$reputationd_user_runtime_dir" systemctl --user restart $REPUTATIOND_SERVICE && echo "ReputationD restart failed." && exit 1
    fi
fi

echo "ReputationD successfully updated!"
