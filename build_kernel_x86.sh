#!/usr/bin/env bash
set -euo pipefail

# Kernel version to pull (change if you like)
KVER="${KVER:-v6.10}"
JOBS="${JOBS:-$(nproc)}"

if [ ! -d linux ]; then
  git clone --depth=1 --branch "$KVER" https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

cd linux

# Base config
make x86_64_defconfig

# Power mgmt + tracing + symbols
scripts/config \
  --enable CONFIG_PM \
  --enable CONFIG_PM_SLEEP \
  --enable CONFIG_PM_DEBUG \
  --enable CONFIG_SUSPEND \
  --enable CONFIG_HIBERNATION \
  --enable CONFIG_MAGIC_SYSRQ \
  --enable CONFIG_KALLSYMS \
  --enable CONFIG_KALLSYMS_ALL \
  --enable CONFIG_FUNCTION_TRACER \
  --enable CONFIG_FUNCTION_GRAPH_TRACER \
  --enable CONFIG_FTRACE_SYSCALLS \
  --enable CONFIG_DYNAMIC_DEBUG \
  --enable CONFIG_DEVTMPFS \
  --enable CONFIG_DEVTMPFS_MOUNT \
  --enable CONFIG_BLK_DEV_INITRD \
  --enable CONFIG_SERIAL_8250 \
  --enable CONFIG_SERIAL_8250_CONSOLE

# Optional: make menuconfig  # uncomment if you want to tweak
# make menuconfig

make -j"$JOBS" bzImage
echo "Built kernel: $(realpath arch/x86/boot/bzImage)"

