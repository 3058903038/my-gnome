#!/usr/bin/env bash
# ============================================================
# 安装 GRUB tela 主题（幂等，可重复执行）
#
# 只改 GRUB_THEME 一行，绝不触碰：
#   - GRUB_CMDLINE_LINUX*
#   - 任何 UUID / 分区引用
#   - /etc/fstab、/etc/mkinitcpio.conf
# 这些仍由目标机器自己的 grub-mkconfig 与硬件决定。
# ============================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="$HERE/themes/tela"
THEME_DST="/boot/grub/themes/tela"
THEME_TXT="/boot/grub/themes/tela/theme.txt"

log() { echo "==> $*"; }
err() { echo "!! $*" >&2; }

[ -d "$THEME_SRC" ] || { err "仓库里没有 grub/themes/tela"; exit 1; }
[ -f /etc/default/grub ] || { err "找不到 /etc/default/grub"; exit 1; }

# 1) 复制主题文件
log "安装主题到 $THEME_DST"
sudo mkdir -p /boot/grub/themes
sudo rm -rf "$THEME_DST"
sudo cp -r "$THEME_SRC" "$THEME_DST"
sudo chmod -R u+rwX,go+rX "$THEME_DST"
[ -f "$THEME_TXT" ] || { err "theme.txt 复制失败"; exit 1; }
log "主题文件就绪（$(find "$THEME_DST" -type f | wc -l) 个文件）"

# 2) 幂等写入 GRUB_THEME（保留文件其余内容）
THEME_LINE="GRUB_THEME=\"$THEME_TXT\""
if grep -qE '^[[:space:]]*GRUB_THEME=' /etc/default/grub; then
  if grep -qF "GRUB_THEME=\"$THEME_TXT\"" /etc/default/grub; then
    log "GRUB_THEME 已是目标值，跳过"
  else
    log "更新 /etc/default/grub 中的 GRUB_THEME"
    sudo sed -i "s|^[[:space:]]*GRUB_THEME=.*|$THEME_LINE|" /etc/default/grub
  fi
else
  log "向 /etc/default/grub 追加 GRUB_THEME"
  printf '\n# GRUB 主题（由 my-gnome 仓库安装）\n%s\n' "$THEME_LINE" | sudo tee -a /etc/default/grub >/dev/null
fi

# 3) 重新生成 grub.cfg（UUID/内核参数由本机自己生成，安全）
log "生成 grub.cfg"
if command -v grub-mkconfig >/dev/null 2>&1; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 \
    && log "grub.cfg 已更新" || err "grub-mkconfig 失败"
else
  err "未找到 grub-mkconfig，跳过生成"
fi

# 4) 部署 ESP 同步脚本 + pacman 钩子
if [ -f "$HERE/grub-esp-sync.sh" ]; then
  log "部署 ESP 同步脚本"
  sudo install -Dm755 "$HERE/grub-esp-sync.sh" /usr/local/bin/grub-esp-sync.sh
  if [ -f "$HERE/zz-grub-esp-sync.hook" ]; then
    sudo install -Dm644 "$HERE/zz-grub-esp-sync.hook" /etc/pacman.d/hooks/zz-grub-esp-sync.hook
  fi
  sudo /usr/local/bin/grub-esp-sync.sh 2>/dev/null || true
fi

log "完成。下次启动即可看到 tela 主题。"
