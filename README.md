# my-gnome(51)

个人 Arch Linux + GNOME 桌面环境备份，可一键恢复整套配置（软件包 / GNOME 设置 / 扩展 / 用户配置）。

## 一键恢复（新机器上）

```bash
# 方式 1：克隆仓库后运行
git clone https://github.com/zkw3058903038/my-gnome.git
cd my-gnome
bash restore.sh

# 方式 2：一行命令直接跑（不用先克隆）
bash <(curl -fsSL https://raw.githubusercontent.com/zkw3058903038/my-gnome/main/restore.sh)
```

> 运行过程中会要求输入 sudo 密码（用于 pacman 安装软件包）。

## 仓库内容

| 路径 | 说明 |
|------|------|
| `packages/all.txt` | 所有已安装包（含依赖） |
| `packages/aur.txt` | AUR 包 |
| `packages/pacman-explicit.txt` | 显式安装的官方包（恢复时用这个） |
| `gnome-settings.conf` | dconf 导出的全部 GNOME 设置 |
| `extensions/all.txt` | 所有扩展 |
| `extensions/enabled.txt` | 启用的扩展（恢复时启用这些） |
| `config/` | `~/.config` 下的关键配置（环境变量、ibus、systemd user） |
| `home/.bashrc` | 用户 shell 配置 |
| `restore.sh` | 一键恢复脚本 |

## 恢复后

1. **注销并重新登录** —— 让 GNOME 设置、扩展、环境变量生效
2. 检查扩展：`gnome-extensions list --enabled`
3. 如有扩展没自动装上，去 https://extensions.gnome.org 手动安装

## 备注

- 仅适用于 **Arch Linux + GNOME**
- GNOME 扩展的**代码本身**需要从 extensions.gnome.org 或 AUR 安装；本仓库只备份扩展**清单 + 设置**，`restore.sh` 会尝试启用已存在的扩展
- 仓库为个人使用，包含用户级配置（路径中含用户名 `ailun`）
probe 1793017308
