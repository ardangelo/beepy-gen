#!/bin/bash -e

# Apply config patches
patch "${ROOTFS_DIR}/boot/firmware/config.txt" files/config.patch
patch "${ROOTFS_DIR}/boot/firmware/cmdline.txt" files/cmdline.patch

# Install post-boot services
install -m 755 files/config.toml    "${ROOTFS_DIR}/boot/"
install -m 644 files/post-boot.target	"${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/load-brcmfmac.service	"${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/mount-boot.service	"${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/disable-cursor-blink.service	"${ROOTFS_DIR}/etc/systemd/system/"
install -m 755 files/blacklist-brcmfmac.conf	"${ROOTFS_DIR}/etc/modprobe.d/"

# Remove MOTD on login
sed -i '/^session .* pam_motd\.so .*/s/^/# /' \
	${ROOTFS_DIR}/etc/pam.d/login

# Run log2ram sync in background
sed -i '/^\s*rsync/ s/$/ \&/' \
	${ROOTFS_DIR}/usr/local/bin/log2ram
sed -i 's/^MAIL=true$/MAIL=false/' \
	${ROOTFS_DIR}/etc/log2ram.conf

# Start getty immediately
sed -i 's/Type=idle/Type=simple/' \
	${ROOTFS_DIR}/lib/systemd/system/getty@.service

# Populate default bash profile
cat << EOF >> ${ROOTFS_DIR}/etc/skel/.profile
# Run these commands when not logged on through SSH
if [ -z "\$SSH_CLIENT" ]; then

	# xterm-old can force some programs to render monochrome
	export TERM=xterm-old

	# Start tmux
	if [ -z \$TMUX ]; then
		tmux -u
	fi
fi
EOF

# Populate default tmux profile
cat << EOF >> ${ROOTFS_DIR}/etc/skel/.tmux.conf
# Keybinds
bind-key b send-keys C-b
bind-key C-b last-window
bind-key e run-shell "/usr/share/beepy-tmux-menus/items/main.sh"

# Status bar
set -g status-position top
set -g status-left ""
set -g status-right "_ [#(cat /sys/firmware/beepy/battery_percent)] %H:%M"
set -g status-interval 30
set -g window-status-separator '_'
set -g @menus_location_x 'R'
set -g @menus_location_y 'T'
EOF

on_chroot << EOF

export POST_BOOT_SERVICES="avahi-daemon ModemManager networking NetworkManager sshswitch wpa_supplicant ssh dphys-swapfile triggerhappy"
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

# Remove network user lookup service as prerequisite for login
sed -i 's/After=remote-fs.target nss-user-lookup.target network.target home.mount/After=home.mount/' \
	/lib/systemd/system/systemd-user-sessions.service
sed -i 's/After=nss-user-lookup.target user.slice modprobe@drm.service/After=user.slice modprobe@drm.service/' \
	/lib/systemd/system/systemd-logind.service
sed -i 's/After=remote-fs.target nss-user-lookup.target network.target home.mount/After=home.mount/' \
	/lib/systemd/system/systemd-user-sessions.service
sed -i 's/After=nss-user-lookup.target user.slice modprobe@drm.service/After=user.slice modprobe@drm.service/' \
	/lib/systemd/system/dbus-org.freedesktop.login1.service

# Enable post-boot services
for srv in \$POST_BOOT_SERVICES; do
	systemctl enable \$srv
done
for trg in \$POST_BOOT_TARGETS; do
	systemctl enable \$trg.target
done
systemctl enable systemd-timesyncd
systemctl enable load-brcmfmac
systemctl enable mount-boot
systemctl enable disable-cursor-blink

# Disable assorted blocking services
systemctl disable rc-local
chmod -x /etc/rc.local
systemctl disable nss-user-lookup.target
systemctl disable sshswitch

EOF
