#!/bin/bash -e

# Apply config patches
sed -i 's@ExecStart=/usr/lib/userconf-pi/userconf-service@ExecStart=/usr/lib/userconf-pi/beepy-userconf-service@' \
	${ROOTFS_DIR}/lib/systemd/system/userconfig.service

# Install first-boot services
install -m 755 files/post-boot-target.sh    "${ROOTFS_DIR}/etc/profile.d/"
install -m 755 files/beepy-userconf-service    "${ROOTFS_DIR}/usr/lib/userconf-pi/"
install -m 755 files/beepy-firstboot-update    "${ROOTFS_DIR}/usr/lib/userconf-pi/"
rm ${ROOTFS_DIR}/usr/bin/impala
install -m 755 files/impala    "${ROOTFS_DIR}/usr/bin/impala"

# Resize for smaller screen
for path in \
	${ROOTFS_DIR}/usr/lib/raspi-config/init_resize.sh \
	${ROOTFS_DIR}/usr/lib/raspberrypi-sys-mods/firstboot \
	${ROOTFS_DIR}/usr/lib/raspi-config/init_resize.sh \
	${ROOTFS_DIR}/usr/lib/userconf-pi/userconf-service; do

	sed -i 's/\(whiptail .* 20 \)60/\140/g' $path
done

on_chroot << EOF

EOF
