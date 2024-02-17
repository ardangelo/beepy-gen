#!/bin/bash -e

. "${BASE_DIR}/config"

# Install additional utilities
install -m 755 files/monoset "${ROOTFS_DIR}/usr/bin/"

# Set default monochrome settings
echo "alias sudo=\"sudo \"" \
        >> ${ROOTFS_DIR}/etc/skel/.profile
echo "alias nmtui=\"monoset 127 nmtui\"" \
        >> ${ROOTFS_DIR}/etc/skel/.profile

on_chroot << EOF

curl -s --compressed "https://ardangelo.github.io/beepy-ppa/KEY.gpg" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/beepy.gpg >/dev/null
curl -s --compressed -o /etc/apt/sources.list.d/beepy.list "https://ardangelo.github.io/beepy-ppa/beepy.list"
apt-get update

apt-get install -y \
	beepy-fw beepy-kbd sharp-drm beepy-symbol-overlay beepy-tmux-menus

# Configure default display cutoff
sed -i 's/^sharp-drm$/sharp-drm mono_cutoff=32/' \
	/etc/modules

EOF
