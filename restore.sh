#!/usr/bin/env bash
# ============================================================
# my-gnome 一键恢复脚本
# 从干净的 Arch Linux 恢复到完整 GNOME 桌面环境
# 用法：bash restore.sh
# ============================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="$(id -un)"
HOME_DIR="$(eval echo ~$USER_NAME)"

log() { echo; echo "==> $*"; }
err() { echo "!! $*" >&2; }
pause() { echo; read -rp "按回车继续（或 Ctrl+C 中止）..." _ || true; }

# ---------- 0. 环境检查 ----------
if ! command -v pacman >/dev/null 2>&1; then
  err "这不是 Arch Linux（找不到 pacman）。本脚本仅支持 Arch Linux。"
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  err "请不要用 root 运行本脚本（makepkg 不允许 root）。用普通用户运行，需要时会提示 sudo。"
  exit 1
fi

log "=== my-gnome 一键恢复 ==="
echo "仓库目录：$REPO_DIR"
echo "用户名：  $USER_NAME"
echo "家目录：  $HOME_DIR"
echo
echo "本脚本会："
echo "  1. 安装 GNOME 桌面环境（若未安装）"
echo "  2. 安装所有软件包（pacman + AUR）"
echo "  3. 安装并启用所有 GNOME 扩展（含扩展管理器）"
echo "  4. 恢复 dconf 全部设置"
echo "  5. 恢复主题（图标/光标/GTK）"
echo "  6. 恢复 shell 配置（zsh/Oh My Zsh/Powerlevel10k）"
echo "  7. 恢复输入法（ibus-rime 雾凇拼音）"
echo "  8. 设置电池充电阈值"
pause

# ---------- 1. 安装 GNOME 桌面 ----------
log "第 1 步：安装 GNOME 桌面环境"
if ! pacman -Qq gnome-shell >/dev/null 2>&1; then
  log "未检测到 GNOME，安装 gnome 组（约 5-10 分钟）"
  sudo pacman -S --needed --noconfirm gnome gnome-tweaks gdm \
    || err "GNOME 安装失败（可手动：sudo pacman -S gnome gnome-tweaks gdm）"
  # 启用 gdm 显示管理器
  sudo systemctl enable gdm.service 2>/dev/null || true
else
  log "GNOME 已安装，跳过"
fi

# 确保基础工具存在
for pkg in base-devel git curl tar; do
  pacman -Qq "$pkg" >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm "$pkg" || true
done

# ---------- 2. 安装软件包 ----------
log "第 2 步：安装软件包（官方源）"
if [ -f "$REPO_DIR/packages/pacman-explicit.txt" ]; then
  # 过滤掉 gnome 组相关的包（已在第1步装好）
  PKGS="$(grep -vE '^\s*#|^\s*$' "$REPO_DIR/packages/pacman-explicit.txt" | tr '\n' ' ')"
  if [ -n "${PKGS// /}" ]; then
    sudo pacman -S --needed --noconfirm $PKGS || err "部分官方包安装失败（继续执行）"
  fi
fi

# ---------- 3. AUR 包 ----------
log "第 3 步：安装 AUR 包"
if [ -f "$REPO_DIR/packages/aur.txt" ] && [ -s "$REPO_DIR/packages/aur.txt" ]; then
  AUR_HELPER=""
  command -v yay >/dev/null 2>&1 && AUR_HELPER=yay
  [ -z "$AUR_HELPER" ] && command -v paru >/dev/null 2>&1 && AUR_HELPER=paru

  if [ -z "$AUR_HELPER" ]; then
    log "安装 yay"
    YAY_BUILD="$(mktemp -d)"
    if git clone --depth=1 https://aur.archlinux.org/yay.git "$YAY_BUILD" 2>/dev/null; then
      ( cd "$YAY_BUILD" && makepkg -si --noconfirm ) || err "yay 编译失败"
      command -v yay >/dev/null 2>&1 && AUR_HELPER=yay
    fi
    rm -rf "$YAY_BUILD" 2>/dev/null
  fi

  if [ -n "$AUR_HELPER" ]; then
    AURPKGS="$(grep -vE '^\s*#|^\s*$' "$REPO_DIR/packages/aur.txt" | tr '\n' ' ')"
    if [ -n "${AURPKGS// /}" ]; then
      $AUR_HELPER -S --needed --noconfirm $AURPKGS || err "部分 AUR 包安装失败（继续执行）"
    fi
  else
    err "yay 安装失败，跳过 AUR 包"
  fi
fi

# ---------- 4. 扩展管理器 + GNOME 扩展 ----------
log "第 4 步：安装扩展管理器并恢复所有 GNOME 扩展"

# 4a. 扩展管理器（必须，否则无法图形化管理扩展）
if ! pacman -Qq extension-manager >/dev/null 2>&1; then
  log "安装 Extension Manager（GNOME 扩展管理器）"
  sudo pacman -S --needed --noconfirm extension-manager || err "extension-manager 安装失败"
fi

# 4b. 复制备份的扩展文件到用户目录
ENABLED_FILE="$REPO_DIR/extensions/enabled.txt"
EXT_FILES_DIR="$REPO_DIR/extensions/files"
USER_EXT_DIR="$HOME_DIR/.local/share/gnome-shell/extensions"
mkdir -p "$USER_EXT_DIR"

if [ -d "$EXT_FILES_DIR" ]; then
  for extdir in "$EXT_FILES_DIR"/*/; do
    [ -d "$extdir" ] || continue
    ext="$(basename "$extdir")"
    if [ ! -d "$USER_EXT_DIR/$ext" ]; then
      cp -r "$extdir" "$USER_EXT_DIR/" 2>/dev/null && log "已安装扩展文件：$ext"
    fi
  done
fi

# 4c. 启用扩展（写入 dconf 的 enabled-extensions）
if [ -f "$ENABLED_FILE" ]; then
  log "记录启用的扩展列表（注销重登后生效）"
  # 用 python 安全构造 GVariant 数组
  if command -v python3 >/dev/null 2>&1; then
    EXT_LIST="$(grep -vE '^\s*#|^\s*$' "$ENABLED_FILE")"
    python3 - "$EXT_LIST" <<'PYEOF'
import subprocess, sys
exts = [e.strip() for e in sys.argv[1].splitlines() if e.strip()]
val = "[" + ",".join(f"'{e}'" for e in exts) + "]"
subprocess.run(["gsettings", "set", "org.gnome.shell", "enabled-extensions", val])
PYEOF
  fi
fi

# ---------- 5. 恢复 dconf 设置 ----------
log "第 5 步：恢复 GNOME 全部设置（dconf）"
if [ -f "$REPO_DIR/gnome-settings.conf" ]; then
  dconf load / < "$REPO_DIR/gnome-settings.conf" && log "dconf 恢复完成" || err "dconf 恢复失败"
fi

# ---------- 6. 恢复用户配置文件 ----------
log "第 6 步：恢复用户配置文件（shell）"
for f in .bashrc .bash_profile .zshrc .p10k.zsh; do
  if [ -f "$REPO_DIR/home/$f" ]; then
    cp -v "$REPO_DIR/home/$f" "$HOME_DIR/$f"
  fi
done

# zsh + Oh My Zsh + Powerlevel10k
pacman -Qq zsh >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm zsh

if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
  log "安装 Oh My Zsh"
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME_DIR/.oh-my-zsh" 2>/dev/null \
    || err "Oh My Zsh 克隆失败"
fi
if [ ! -d "$HOME_DIR/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
  log "安装 Powerlevel10k 主题"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$HOME_DIR/.oh-my-zsh/custom/themes/powerlevel10k" 2>/dev/null || err "Powerlevel10k 克隆失败"
fi

# 默认 shell 改 zsh
if [ -x /usr/bin/zsh ]; then
  grep -qx /usr/bin/zsh /etc/shells 2>/dev/null || echo /usr/bin/zsh | sudo tee -a /etc/shells >/dev/null
  if [ "$(getent passwd "$USER_NAME" | cut -d: -f7)" != /usr/bin/zsh ]; then
    chsh -s /usr/bin/zsh "$USER_NAME" 2>/dev/null || err "chsh 失败（可手动：chsh -s /usr/bin/zsh）"
  fi
fi

# ---------- 7. 恢复 ~/.config ----------
log "第 7 步：恢复 ~/.config 配置"
copy_config() {
  local src="$1" dst="$2"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    cp -r "$src/." "$dst/" 2>/dev/null || true
  fi
}
copy_config "$REPO_DIR/config/environment.d" "$HOME_DIR/.config/environment.d"
copy_config "$REPO_DIR/config/ibus"          "$HOME_DIR/.config/ibus"
copy_config "$REPO_DIR/config/systemd/user"  "$HOME_DIR/.config/systemd/user"
copy_config "$REPO_DIR/config/gtk-3.0"       "$HOME_DIR/.config/gtk-3.0"
copy_config "$REPO_DIR/config/gtk-4.0"       "$HOME_DIR/.config/gtk-4.0"
copy_config "$REPO_DIR/config/gnome-shell"   "$HOME_DIR/.config/gnome-shell"

if [ -f "$REPO_DIR/config/user-dirs/user-dirs.dirs" ]; then
  mkdir -p "$HOME_DIR/.config/user-dirs"
  cp -f "$REPO_DIR/config/user-dirs/user-dirs.dirs"   "$HOME_DIR/.config/user-dirs/" 2>/dev/null || true
  cp -f "$REPO_DIR/config/user-dirs/user-dirs.locale" "$HOME_DIR/.config/user-dirs/" 2>/dev/null || true
fi
[ -f "$REPO_DIR/config/mimeapps.list" ] && cp -f "$REPO_DIR/config/mimeapps.list" "$HOME_DIR/.config/" 2>/dev/null || true

# ---------- 8. 恢复主题 ----------
log "第 8 步：恢复主题（光标 / 图标 / GTK）"

# 8a. 光标 + 图标主题（tar.gz 解压）
if [ -d "$REPO_DIR/themes" ]; then
  mkdir -p "$HOME_DIR/.local/share/icons"
  for tarball in "$REPO_DIR/themes"/*.tar.gz; do
    [ -f "$tarball" ] || continue
    tname="$(basename "$tarball" .tar.gz)"
    log "解压主题：$tname"
    tar -xzf "$tarball" -C "$HOME_DIR/.local/share/icons/" 2>/dev/null \
      || err "解压 $tname 失败"
  done
fi

# 8b. WhiteSur GTK 主题（从 GitHub 安装）
if [ ! -d "$HOME_DIR/.themes/WhiteSur-Light" ] && [ ! -d "$HOME_DIR/.themes/WhiteSur-Dark" ]; then
  log "安装 WhiteSur GTK 主题"
  WS_BUILD="$(mktemp -d)"
  if git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$WS_BUILD" 2>/dev/null; then
    ( cd "$WS_BUILD" && yes | ./install.sh >/dev/null 2>&1 ) || err "WhiteSur 安装失败"
  elif curl -fsSL https://codeload.github.com/vinceliuice/WhiteSur-gtk-theme/tar.gz/refs/heads/master -o "$WS_BUILD/ws.tar.gz" 2>/dev/null; then
    tar -xzf "$WS_BUILD/ws.tar.gz" -C "$WS_BUILD" --strip-components=1 2>/dev/null
    ( cd "$WS_BUILD" && yes | ./install.sh >/dev/null 2>&1 ) || err "WhiteSur 安装失败"
  else
    err "WhiteSur 下载失败（需联网）"
  fi
  rm -rf "$WS_BUILD" 2>/dev/null
fi

# ---------- 9. Rime 输入法 ----------
log "第 9 步：恢复 Rime 输入法配置"
if [ -d "$REPO_DIR/config/ibus-rime" ]; then
  mkdir -p "$HOME_DIR/.config/ibus/rime"
  for f in default.custom.yaml installation.yaml user.yaml; do
    [ -f "$REPO_DIR/config/ibus-rime/$f" ] && cp -f "$REPO_DIR/config/ibus-rime/$f" "$HOME_DIR/.config/ibus/rime/" 2>/dev/null || true
  done
  # 重建 ibus 缓存
  ibus write-cache 2>/dev/null || true
fi

# ---------- 10. 电池充电阈值 ----------
log "第 10 步：设置电池充电上限 85%"
if [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
  sudo tee /etc/systemd/system/battery-charge-threshold.service >/dev/null <<'EOF'
[Unit]
Description=Set battery charge threshold to 85%
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo 85 > /sys/class/power_supply/BAT0/charge_control_end_threshold'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl enable --now battery-charge-threshold.service 2>/dev/null || true
  echo 85 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold >/dev/null 2>&1 || true
else
  log "未检测到电池，跳过"
fi

# ---------- 完成 ----------
log "全部完成！"
echo
echo "=========================================="
echo "  恢复完成，最后一步："
echo "=========================================="
echo
echo "  注销并重新登录（或重启），让以下生效："
echo "    - GNOME 扩展（$USER_NAME 个）"
echo "    - dconf 设置（主题、顶栏、Openbar 等）"
echo "    - 输入法（ibus-rime 雾凇拼音）"
echo "    - 默认 shell（zsh）"
echo
echo "  重登后验证："
echo "    gnome-extensions list --enabled"
echo "    gsettings get org.gnome.desktop.interface gtk-theme"
echo
echo "  如需图形化管理扩展：打开 Extension Manager"
echo
