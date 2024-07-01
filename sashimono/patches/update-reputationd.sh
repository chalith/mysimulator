#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Please run with root privileges (sudo)." && exit 1

repo_owner="chalith"
repo_name="mysimulator"
file="reputationd.tar.xz"

export SASHIMONO_BIN=/usr/bin/sashimono
export REPUTATIOND_SERVICE="sashimono-reputationd"
export REPUTATIOND_USER="sashireputationd"
export REPUTATIOND_BIN=$SASHIMONO_BIN/reputationd

[ ! -d "$REPUTATIOND_BIN" ] && echo "Reputationd is not opted in on your machine." && exit 1

echo "Backing up.."

timestamp=$(date +%s)
backup="$REPUTATIOND_BIN-$timestamp.bk"
mv "$REPUTATIOND_BIN" "$backup"
download="/tmp/$file"

echo "Updating.."

function update() {
    ! curl "https://raw.githubusercontent.com/$repo_owner/$repo_name/patch-v0.9.1/sashimono/patches/resources/reputationd/$file" -o "$download" && echo "Download failed!" && return 1
    ! mkdir $REPUTATIOND_BIN && echo "Directory creation failed!" && return 1
    ! tar -xf "$download" -C "$REPUTATIOND_BIN" && echo "Unzip failed!" && return 1
    ! chmod +x "$REPUTATIOND_BIN" && echo "Ownership change failed!" && return 1
    rm "$download"
}

if (! update); then
    echo "Update failed. Restoring.."
    rm -r "$REPUTATIOND_BIN"
    ! cp -Rdp "$backup" "$REPUTATIOND_BIN" && echo "Restoring failed." && exit 1
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
