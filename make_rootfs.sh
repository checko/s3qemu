:wq#!/usr/bin/env bash
set -euo pipefail

BB_VER="${BB_VER:-1.36.1}"
ROOTDIR="$(pwd)/rootfs"
[ -d "$ROOTDIR" ] && rm -rf "$ROOTDIR"
mkdir -p "$ROOTDIR"

# BusyBox
if [ ! -d busybox-$BB_VER ]; then
  wget -q https://busybox.net/downloads/busybox-$BB_VER.tar.bz2
  tar xf busybox-$BB_VER.tar.bz2
fi

pushd busybox-$BB_VER
make defconfig
# static is simplest; switch off if you prefer dynamic + musl
sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make -j"$(nproc)"
make CONFIG_PREFIX="$ROOTDIR" install
popd

# Minimal dirs
mkdir -p "$ROOTDIR"/{proc,sys,dev,etc}
mkdir -p "$ROOTDIR"/etc/init.d

# /init (PID 1)
cat > "$ROOTDIR/init" <<'EOF'
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs devtmpfs /dev

# Helpful knobs
echo 1 > /sys/power/pm_debug_messages 2>/dev/null || true
echo 1 > /sys/power/pm_print_times   2>/dev/null || true

# Spawn a shell on the serial console
exec /bin/sh
EOF
chmod +x "$ROOTDIR/init"

# Pack initramfs
pushd "$ROOTDIR"
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../rootfs.cpio.gz
popd

echo "Built initramfs: $(realpath rootfs.cpio.gz)"

