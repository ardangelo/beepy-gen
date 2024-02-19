#!/bin/bash -e

. "${BASE_DIR}/config"

# Install additional utilities
install -m 755 files/monoset "${ROOTFS_DIR}/usr/bin/"

# Set default monochrome settings
cat << EOF >> ${ROOTFS_DIR}/etc/skel/.profile

# Start nmtui with a monochrome cutoff of 127
alias sudo="sudo "
alias nmtui="monoset 127 nmtui"
EOF

on_chroot << EOF

curl -s --compressed "https://ardangelo.github.io/beepy-ppa/KEY.gpg" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/beepy.gpg >/dev/null
curl -s --compressed -o /etc/apt/sources.list.d/beepy.list "https://ardangelo.github.io/beepy-ppa/beepy.list"
apt-get update

apt-get install -y \
	beepy-fw beepy-kbd sharp-drm beepy-symbol-overlay \
	tmux beepy-tmux-menus beepy-gomuks

# Add Beepy hardware group
groupadd beepy_fw

EOF
