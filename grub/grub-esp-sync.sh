#!/bin/bash
# 同步 GRUB 配置/主题到 ESP。
#
# 两种常见布局都要正确处理：
#   A) /boot 本身就是 ESP（vfat）—— GRUB 直接读 /boot/grub，无需同步
#   B) /boot 是普通目录，/boot/efi 才是 ESP —— 需要把 /boot/grub 复制到 ESP
#
# 脚本幂等，任何情况下都返回 0，避免 pacman hook 因非零退出码中断事务。

set -u

grub_cfg=/boot/grub/grub.cfg
themes_dir=/boot/grub/themes

if [ ! -f "$grub_cfg" ]; then
  echo "grub-esp-sync: $grub_cfg missing, skip" >&2
  exit 0
fi

# 布局 A：/boot 自身就是 ESP，GRUB 已经在读同一份文件
if [ "$(findmnt -n -o FSTYPE /boot 2>/dev/null)" = "vfat" ]; then
  echo "grub-esp-sync: /boot is the ESP itself, nothing to sync"
  exit 0
fi

# 布局 B：需要同步到 /boot/efi
mkdir -p /boot/efi
mountpoint -q /boot/efi || mount /boot/efi 2>/dev/null || true
if ! mountpoint -q /boot/efi; then
  echo "grub-esp-sync: /boot/efi not mounted, skip" >&2
  exit 0
fi

mkdir -p /boot/efi/grub
cp -f "$grub_cfg" /boot/efi/grub/grub.cfg
if [ -d "$themes_dir" ]; then
  mkdir -p /boot/efi/grub/themes
  cp -rf "$themes_dir/." /boot/efi/grub/themes/ 2>/dev/null || true
fi
echo "grub-esp-sync: synced grub.cfg + themes to ESP"
exit 0
