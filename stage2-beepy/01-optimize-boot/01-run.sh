#!/bin/bash -e

# Apply config patches
patch "${ROOTFS_DIR}/boot/firmware/config.txt" files/config.patch
patch "${ROOTFS_DIR}/boot/firmware/cmdline.txt" files/cmdline.patch

# Install post-boot services
install -m 755 files/config.toml    "${ROOTFS_DIR}/boot/"
install -m 644 files/post-boot.target	"${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/defer-systemd-timesyncd.service	"${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/load-brcmfmac.service	"${ROOTFS_DIR}/etc/systemd/system/"
install -m 755 files/blacklist-brcmfmac.conf	"${ROOTFS_DIR}/etc/modprobe.d/"

on_chroot << EOF

export POST_BOOT_SERVICES="avahi-daemon ModemManager networking NetworkManager sshswitch wpa_supplicant ssh"
export POST_BOOT_TARGETS="nfs-client remote-fs"

# Remove from multi-user target
systemctl disable systemd-timesyncd
for srv in \$POST_BOOT_SERVICES; do
	systemctl disable \$srv
done
for trg in \$POST_BOOT_TARGETS; do
	systemctl disable \$trg.target
done

# Change nonessential services to run post-boot
for srv in \$POST_BOOT_SERVICES; do
	sed -i 's/WantedBy=multi-user.target/WantedBy=post-boot.target/' \
		/lib/systemd/system/\$srv.service
done
for trg in \$POST_BOOT_TARGETS; do
	sed -i 's/WantedBy=multi-user.target/WantedBy=post-boot.target/' \
		/lib/systemd/system/\$trg.target
done
sed -i 's/WantedBy=sysinit.target/WantedBy=network-online.target/' \
	/lib/systemd/system/systemd-timesyncd.service
sed -i 's/Before=time-set.target sysinit.target shutdown.target/Before=time-set.target shutdown.target/' \
	/lib/systemd/system/systemd-timesyncd.service

sed -i 's/After=remote-fs.target nss-user-lookup.target network.target home.mount/After=home.mount/' \
	/lib/systemd/system/systemd-user-sessions.service

# Disable rc.local
systemctl disable rc-local
chmod -x /etc/rc.local

# Enable post-boot services
for srv in \$POST_BOOT_SERVICES; do
	systemctl enable \$srv
done
for trg in \$POST_BOOT_TARGETS; do
	systemctl enable \$trg.target
done
systemctl enable systemd-timesyncd
systemctl enable load-brcmfmac

EOF
