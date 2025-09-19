#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Please run this script with sudo or as root." >&2
  exit 1
fi

apt-get update
apt-get install -y \
  build-essential \
  git \
  bc \
  flex \
  bison \
  libssl-dev \
  libelf-dev \
  libncurses-dev \
  wget \
  cpio \
  gzip \
  tar \
  rsync \
  qemu-system-x86
