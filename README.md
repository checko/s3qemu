# S3 Suspend Exploration with QEMU

This repository documents and automates an end-to-end lab for studying ACPI S3 (suspend to RAM) on x86 using upstream Linux, BusyBox, and QEMU. The provided scripts build a minimal environment, boot it under QEMU with S3 enabled, and collect tracing data while the guest suspends and resumes via the RTC.

## Prerequisites

- Linux host with `bash`, `git`, `make`, `gcc`, `binutils`, `bc`, `flex`, `bison`, `openssl` headers, and other kernel build dependencies.
- User-space tools: `qemu-system-x86_64`, `wget`, `cpio`, `gzip`, `rsync` (optional but convenient).
- At least ~15 GB of free disk space and a few GB of RAM for kernel compilation.
- Internet access to fetch the Linux source tree and BusyBox tarball.

## Quick Start

0. Install dependencies (requires sudo):
   ```sh
   sudo ./install_deps.sh
   ```

1. Make the helper scripts executable:
   ```sh
   chmod +x build_kernel_x86.sh make_rootfs.sh run_qemu_s3.sh
   ```
2. Build the kernel (defaults to `v6.10` unless you set `KVER`):
   ```sh
   ./build_kernel_x86.sh
   ```
3. Build the BusyBox-based initramfs:
   ```sh
   ./make_rootfs.sh
   ```
4. Boot the environment with QEMU and S3 exposed:
   ```sh
   ./run_qemu_s3.sh
   ```
   Use `GDB=1 ./run_qemu_s3.sh` if you want the VM to pause at reset with a gdbstub on `:1234`.

## Inside the Guest

Once you have a BusyBox shell on the serial console:

- Copy the helper scripts into the guest. Easiest options:
  - Mount the auto-exported 9p share from the host (set up by `run_qemu_s3.sh`):
  ```sh
  mkdir -p /mnt/host
  mount -t 9p -o trans=virtio s3repo /mnt/host
  ```
  Copy any helper scripts you need, then make them executable inside the guest:
  ```sh
  cp /mnt/host/guest_helper.sh .
  cp /mnt/host/suspend_rtc.sh .
  chmod +x guest_helper.sh suspend_rtc.sh
  ```

- Alternatively, paste the snippets from `how_to_test.txt`, which use `cat > ... <<'EOF'` to synthesize the scripts inline.

- Run the tracing helper:
  ```sh
  ./guest_helper.sh
  ```
  You should see the available sleep states (expect `[s2idle] deep`). The helper switches to `deep`, enables function-graph tracing for PM paths, and turns on suspend timing logs.

- Trigger a suspend/resume cycle driven by the RTC:
  ```sh
  ./suspend_rtc.sh 5
  ```
  The script clears any previous wake alarms, arms `rtc0` for the requested delay, writes `mem` to `/sys/power/state`, and copies the trace to `/tmp/pm.trace` for inspection. Pass a different value (e.g. `./suspend_rtc.sh 10`) to change the delay.

## Debugging Tips

- `gdb_kernel.txt` contains breakpoints for core suspend call paths (`state_store`, `pm_suspend`, `suspend_devices_and_enter`). Start QEMU with `GDB=1` and attach with:
  ```sh
  gdb linux/vmlinux
  (gdb) target remote :1234
  ```
- `wake_from_monitor.txt` captures useful QEMU monitor commands (`help`, `system_wakeup`). Access the monitor via QEMU’s `Ctrl+a c` sequence when using `-serial mon:stdio`.
- `suspend_rtc.sh` shows how to narrow suspend testing using `/sys/power/pm_test` (commented examples in the script).

## Customization

- `build_kernel_x86.sh` respects `KVER` and `JOBS`; adjust them to test other kernel versions or limit parallel builds.
- `run_qemu_s3.sh` accepts `MACHINE` (`pc` or `q35`), `KERNEL`, and `INITRD` overrides. When using `q35`, S3/S4 toggles switch to the ICH9 LPC controller.
- `make_rootfs.sh` builds BusyBox `1.36.1` statically by default. Edit the script if you need dynamic binaries or additional packages.

## Repository Layout

- `build_kernel_x86.sh` – Clone/configure/build an upstream kernel with suspend tracing options.
- `make_rootfs.sh` – Assemble a minimal BusyBox initramfs with an interactive shell.
- `run_qemu_s3.sh` – Launch QEMU with S3 exposed and optional gdbstub.
- `guest_helper.sh`, `suspend_rtc.sh` – Guest-side utilities for tracing and RTC-driven suspend.
- `gdb_kernel.txt`, `how_to_run.txt`, `how_to_test.txt`, `wake_from_monitor.txt` – Notes and runbooks for common workflows.

## License

This project is licensed under the [MIT License](./LICENSE).
