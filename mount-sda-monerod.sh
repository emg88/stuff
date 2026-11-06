#!/usr/bin/env bash
# Prep a blank disk for monerod: partition, format ext4, mount, add to fstab,
# and create a data directory owned by a dedicated "monero" user.
#
# Usage: sudo ./mount-sda-monerod.sh [device] [mountpoint]
# Example: sudo ./mount-sda-monerod.sh /dev/sda /mnt/monero
#
# Refuses to touch a disk that already has partitions or a filesystem.
# To override (DESTROYS ALL DATA ON THE DISK): sudo FORCE=1 ./mount-sda-monerod.sh

set -euo pipefail

DEV="${1:-/dev/sda}"
MNT="${2:-/mnt/monero}"
PART="${DEV}1"
[[ "$DEV" =~ (nvme|mmcblk) ]] && PART="${DEV}p1"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (use sudo)." >&2
  exit 1
fi

if [[ ! -b "$DEV" ]]; then
  echo "$DEV is not a block device. Check lsblk." >&2
  exit 1
fi

# Don't touch the disk holding the root filesystem
ROOT_SRC="$(findmnt -n -o SOURCE /)"
if [[ "$ROOT_SRC" == "$DEV"* ]]; then
  echo "$DEV holds the root filesystem. Aborting." >&2
  exit 1
fi

# Safety check: refuse if the disk already has partitions/filesystems
if [[ -n "$(lsblk -n -o FSTYPE "$DEV" | tr -d '[:space:]')" || "$(lsblk -n "$DEV" | wc -l)" -gt 1 ]]; then
  if [[ "${FORCE:-0}" != "1" ]]; then
    echo "$DEV already has partitions or a filesystem:" >&2
    lsblk -f "$DEV" >&2
    echo "Re-run with FORCE=1 to wipe it. ALL DATA WILL BE LOST." >&2
    exit 1
  fi
  echo "FORCE=1 set: wiping $DEV"
  umount "${DEV}"* 2>/dev/null || true
  wipefs -a "$DEV"
fi

echo "==> Partitioning $DEV"
parted -s "$DEV" mklabel gpt mkpart primary ext4 0% 100%
partprobe "$DEV"
sleep 2

echo "==> Formatting $PART as ext4 (no reserved blocks)"
mkfs.ext4 -m 0 -L monerod "$PART"

echo "==> Mounting at $MNT"
mkdir -p "$MNT"
UUID="$(blkid -s UUID -o value "$PART")"
if ! grep -q "$UUID" /etc/fstab; then
  echo "UUID=$UUID $MNT ext4 defaults,noatime,nofail 0 2" >> /etc/fstab
fi
mount "$MNT"

echo "==> Creating monero user and data directory"
id monero &>/dev/null || useradd --system --home-dir "$MNT" --shell /usr/sbin/nologin monero
mkdir -p "$MNT/blockchain"
chown -R monero:monero "$MNT"

echo
df -h "$MNT"
echo
echo "Done. Point monerod at it, e.g.:"
echo "  monerod --data-dir $MNT/blockchain --prune-blockchain"
echo "or set data-dir=$MNT/blockchain in monerod.conf"
