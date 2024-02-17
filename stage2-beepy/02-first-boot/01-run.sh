#!/bin/bash -e

# Apply config patches
sed -i 's@ExecStart=/usr/lib/userconf-pi/userconf-service@ExecStart=/usr/lib/userconf-pi/beepy-userconf-service@' \
	${ROOTFS_DIR}/lib/systemd/system/userconfig.service

# Install first-boot services
install -m 755 files/post-boot-target.sh    "${ROOTFS_DIR}/etc/profile.d/"
install -m 755 files/beepy-userconf-service    "${ROOTFS_DIR}/usr/lib/userconf-pi/"

on_chroot << EOF

EOF
