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

# Add drivers repo
curl -s --compressed "https://ardangelo.github.io/beepy-ppa/KEY.gpg" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/beepy.gpg >/dev/null
curl -s --compressed -o /etc/apt/sources.list.d/beepy.list "https://ardangelo.github.io/beepy-ppa/beepy.list"

# Add log2ram repo
echo "deb http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
curl -s https://azlux.fr/repo.gpg.key | sudo apt-key add -

# Update repos
apt-get update

# Install drivers and log2ram
apt-get install -y \
	beepy-fw beepy-kbd sharp-drm beepy-symbol-overlay log2ram

# Install userspace
apt-get install -y \
	git tmux beepy-tmux-menus beepy-gomuks

EOF
