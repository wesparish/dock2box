#!/bin/ash

set -eu

REL=$1
TS="$2"

#
# Add applications and configuration
#

# Add repositories
cat << EOF >/etc/apk/repositories
http://nl.alpinelinux.org/alpine/v3.4/main
http://nl.alpinelinux.org/alpine/edge/community
EOF

# Add pre-reqs
apk update
apk add pv

# Add repositories
cat << EOF >/etc/apk/repositories
http://nl.alpinelinux.org/alpine/v3.4/main
http://nl.alpinelinux.org/alpine/v3.4/community
EOF

# Add pre-reqs
apk update
apk add pciutils \
        parted \
        mdadm \
        lvm2 \
        gptfdisk \
        openssh \
        openssl \
        openssh-client \
        sudo \
        curl \
        udev \
        sfdisk \
        iptables \
        ca-certificates \
        tar \
        coreutils \
        jq \
        cmake \
        v86d \
        ncurses \
        util-linux

# Setup root passwd
grep -v 'root:' /usr/share/mkinitfs/passwd >/tmp/passwd
echo 'root:$6$BaHYi8W6U.pAapmr$AfxQe39FlxKZh1EiFbNeROwiUWadGFUbgHs.ZZK0RNi8M4giXhDDnX/SukpZRXelKPt8B3ZJHcVAsHD.qroTw1:0:0:root:/root:/bin/ash' >/usr/share/mkinitfs/passwd
cat /tmp/passwd >>/usr/share/mkinitfs/passwd

# Add initramfs-init script
cp scripts/init /usr/share/mkinitfs/initramfs-init

# Copy scripts to root
cp scripts/functions*.sh /
cp scripts/dock2box-rebuild /
cp scripts/config /

# Add CA certificates
mkdir -p /usr/local/share/ca-certificates/
[ -n "$(ls certs)" ] && cp certs/* /usr/local/share/ca-certificates/

# Add SSH keys
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown -R root:root /root/.ssh
touch /root/.ssh/authorized_keys
[ -n "$(ls sshkeys)" ] && cat sshkeys/*.rsa >>/root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Only allow public key login
cat << EOF >>/etc/ssh/sshd_config
PasswordAuthentication yes
PermitRootLogin yes
RSAAuthentication yes
PubkeyAuthentication yes
EOF

# Copy splash screen
cp dock2box.ppm /etc

# Default uvesafb mode
echo "options uvesafb mode_option=800x600-32 scroll=ywrap" >/etc/modprobe.d/uvesafb.conf

#
# Files to include in initrd
#

echo 'features="network ata base ide scsi usb virtio ext4 dhcp lspci sshd dock2box parted ca-certificates tar chroot curl lvm sgdisk sfdisk udevadm mkfs jq v86d pv ncurses tput setterm"' >/etc/mkinitfs/mkinitfs.conf
echo "/usr/share/udhcpc/default.script" >>/etc/mkinitfs/features.d/dhcp.files
echo "kernel/net/packet/af_packet.ko" >>/etc/mkinitfs/features.d/dhcp.modules

# bnx2x module is included by default, but depends on crc32c which is not included by default
echo 'kernel/arch/x86/crypto/crc32c-intel.ko' >>/etc/mkinitfs/features.d/network.modules

cat << EOF >>/etc/mkinitfs/features.d/base.files
/etc/keymap/us.bmap.gz
EOF

cat << EOF >/etc/mkinitfs/features.d/lspci.files
/usr/share/hwdata/pci.ids
/usr/sbin/lspci
EOF

# Add motd
printf "dock2box, release: ${REL} (${TS})\n" >/etc/motd

cat << EOF >/etc/mkinitfs/features.d/sshd.files
/usr/bin/ssh-keygen
/etc/ssh/sshd_config
/usr/sbin/sshd
/usr/lib/ssh/ssh-pkcs11-helper
/etc/motd
/usr/bin/scp
EOF

cat << EOF >/etc/mkinitfs/features.d/parted.files
/usr/sbin/partprobe
/usr/sbin/parted
/lib/ld-musl-x86_64.so.1
/usr/lib/libparted.so.2
/usr/lib/libreadline.so.6
/usr/lib/libncursesw.so.6
EOF

cat << EOF >/etc/mkinitfs/features.d/ca-certificates.files
/usr/share/ca-certificates/mozilla
/usr/local/share/ca-certificates
/etc/ca-certificates.conf
/usr/sbin/update-ca-certificates
/etc/ca-certificates/update.d/c_rehash
/usr/bin/c_rehash
EOF

cat << EOF >/etc/mkinitfs/features.d/dock2box.files
/root/.ssh/authorized_keys
/functions*.sh
/dock2box-rebuild
/config
/etc/dock2box.ppm
EOF

cat << EOF >/etc/mkinitfs/features.d/chroot.modules
/usr/sbin/chroot
EOF

cat << EOF >/etc/mkinitfs/features.d/tar.modules
/usr/bin/tar
EOF

cat << EOF >/etc/mkinitfs/features.d/curl.files
/usr/bin/curl
/usr/lib/libcurl.so.4
/usr/lib/libssh2.so.1
EOF

cat << EOF >/etc/mkinitfs/features.d/lvm.files
/sbin/vgs
/sbin/lvs
/sbin/pvs
/sbin/vgscan
/sbin/lvscan
/sbin/pvscan
/sbin/vgcreate
/sbin/lvcreate
/sbin/pvcreate
/sbin/vgremove
/sbin/lvremove
/sbin/pvremove
/lib/libdevmapper-event.so.1.02
EOF

cat << EOF >/etc/mkinitfs/features.d/sgdisk.files
/usr/bin/sgdisk
/lib/ld-musl-x86_64.so.1
/lib/libpopt.so.0
/usr/lib/libstdc++.so.6
/usr/lib/libgcc_s.so.1
EOF

cat << EOF >/etc/mkinitfs/features.d/sfdisk.files
/sbin/sfdisk
/lib/libfdisk.so.1
/lib/libsmartcols.so.1
EOF

cat << EOF >/etc/mkinitfs/features.d/udevadm.files
/sbin/udevadm
EOF

cat << EOF >/etc/mkinitfs/features.d/mkfs.files
/sbin/mkfs.ext4
/lib/libext2fs.so.2
/lib/libcom_err.so.2
/lib/libe2p.so.2
/sbin/mkswap
EOF

cat << EOF >/etc/mkinitfs/features.d/jq.files
/usr/bin/jq
EOF

cat << EOF >/etc/mkinitfs/features.d/ttylog.files
/usr/sbin/ttylog
EOF

cat << EOF >/etc/mkinitfs/features.d/v86d.files
/sbin/v86d
/etc/modprobe.d/uvesafb.conf
EOF

cat << EOF >/etc/mkinitfs/features.d/v86d.modules
kernel/drivers/video/console/fbcon.ko
kernel/drivers/video/fbdev/uvesafb.ko
EOF

cat << EOF >/etc/mkinitfs/features.d/pv.files
/usr/bin/pv
EOF

cat << EOF >/etc/mkinitfs/features.d/ncurses.files
/usr/lib/libncursesw.so.6
/etc/terminfo
EOF

cat << EOF >/etc/mkinitfs/features.d/tput.files
/usr/bin/tput
EOF

cat << EOF >/etc/mkinitfs/features.d/setterm.files
/usr/bin/setterm
EOF

# Build initrd and copy kernel
kver=$( ls /lib/modules | tail -1 )
mkinitfs -o initrd $kver
cp /boot/vmlinuz-grsec kernel
