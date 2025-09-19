#!/usr/bin/env bash
set -euo pipefail

LINUX_DIR="${LINUX_DIR:-linux}"
KERNEL="${KERNEL:-$LINUX_DIR/arch/x86/boot/bzImage}"
INITRD="${INITRD:-rootfs.cpio.gz}"

# S3 is disabled by default in many machine models—explicitly enable it.
# Use i440fx/PIIX4 (pc) or q35/ICH9; both shown below. Pick ONE.

MACHINE="${MACHINE:-pc}"  # change to q35 if you prefer
GLOBAL_S3_S4_ARGS=()

if [ "$MACHINE" = "pc" ]; then
  GLOBAL_S3_S4_ARGS+=( -global PIIX4_PM.disable_s3=0 -global PIIX4_PM.disable_s4=0 )
else
  GLOBAL_S3_S4_ARGS+=( -global ICH9-LPC.disable_s3=0 -global ICH9-LPC.disable_s4=0 )
fi

# Add -s -S to stop at reset & open gdbstub on :1234
GDB="${GDB:-0}"  # set to 1 to enable
GDB_ARGS=()
[ "$GDB" -eq 1 ] && GDB_ARGS=( -s -S )

qemu-system-x86_64 \
  -machine "$MACHINE",i8042=on \
  -m 2048 -smp 2 \
  -kernel "$KERNEL" \
  -initrd "$INITRD" \
  -append "console=ttyS0 earlyprintk=serial,ttyS0,115200 no_console_suspend ignore_loglevel initcall_debug pm_debug_messages" \
  -serial mon:stdio -display none \
  "${GLOBAL_S3_S4_ARGS[@]}" \
  "${GDB_ARGS[@]}"

