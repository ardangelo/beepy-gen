#!/bin/bash -e

. "${BASE_DIR}/config"

on_chroot << EOF

curl -s --compressed "https://ardangelo.github.io/beepy-ppa/KEY.gpg" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/beepy.gpg >/dev/null
curl -s --compressed -o /etc/apt/sources.list.d/beepy.list "https://ardangelo.github.io/beepy-ppa/beepy.list"
apt-get update

apt-get install -y \
	beepy-fw beepy-kbd sharp-drm beepy-symbol-overlay beepy-tmux-menus

EOF
