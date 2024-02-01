#!/bin/bash -e

. "${BASE_DIR}/config"

on_chroot << EOF
curl -s --compressed "https://ardangelo.github.io/beepy-ppa/KEY.gpg" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/beepy.gpg >/dev/null
curl -s --compressed -o /etc/apt/sources.list.d/beepy.list "https://ardangelo.github.io/beepy-ppa/beepy.list"
apt-get update

apt-get install -y raspberrypi-kernel-headers

# If this fails, may need to hardcode in config
KERNEL_VER=\$(zgrep -oPm 1 "Linux version \K(.*)$" /usr/share/doc/raspberrypi-kernel-headers/changelog.Debian.gz)
KERNEL_BUILD_DIR=\$(ls -d /lib/modules/${KERNEL_VER}*/build | head -n1)
LINUX_DIR="\${KERNEL_BUILD_DIR}" apt-get install -y \
	beepy-fw beepy-kbd sharp-drm beepy-symbol-overlay beepy-tmux-menus
EOF
