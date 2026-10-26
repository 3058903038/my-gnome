# my-gnome

个人 **Arch Linux + GNOME 51** 桌面环境完整备份，可一键还原成当前状态
（桌面环境 / 软件包 / 扩展 / 主题 / 输入法 / 配置 / 壁纸）。

仓库地址：<https://gitee.com/kw3058903038/my-gnome>

## 一键恢复（新机器上）

前提：已装好 Arch Linux 基础系统（能联网、有 git）。

```bash
sudo pacman -S --needed git
git clone https://gitee.com/kw3058903038/my-gnome.git
cd my-gnome
bash restore.sh
```

跑完后 **注销并重新登录**（或重启），让扩展、主题、输入法生效。

> 过程中会要求 sudo 密码（用于 pacman 安装软件包）。
> 不要用 root 直接运行脚本（makepkg 不允许 root）。

## restore.sh 做了什么（11 步）

| 步骤 | 内容 |
|------|------|
| 1 | 安装 GNOME 桌面环境 + gdm 显示管理器 |
| 2 | 恢复 pacman 源配置（archlinuxcn，装 clash-verge-rev 等必需） |
| 3 | 安装 136 个官方源软件包 |
| 4 | 安装 8 个 AUR 包（自动先装 yay） |
| 5 | 安装 **Extension Manager** + 恢复并启用 17 个 GNOME 扩展 |
| 6 | 恢复 dconf 全部设置（主题、顶栏、Openbar、输入法、窗口按钮等） |
| 7 | 恢复 shell 配置（zsh + Oh My Zsh + Powerlevel10k） |
| 8 | 恢复 `~/.config`（输入法环境变量、GTK、systemd user、默认应用、中文目录名） |
| 9 | 恢复主题（AZ-OS-3D 图标 / MacOSX 光标 / WhiteSur GTK）+ 桌面壁纸 |
| 10 | 恢复 Rime 输入法配置 + 用户词库 |
| 11 | 设置电池充电上限 85% + 启用系统服务（蓝牙、iwd、snapper 等） |

## 仓库内容

| 路径 | 说明 |
|------|------|
| `restore.sh` | 一键恢复脚本（核心） |
| `gnome-settings.conf` | dconf 导出的全部 GNOME 设置 |
| `packages/pacman-explicit.txt` | 显式安装的官方包 |
| `packages/aur.txt` | AUR 包清单 |
| `packages/all.txt` | 全部已安装包（含依赖，参考用） |
| `extensions/enabled.txt` | 已启用的扩展清单 |
| `extensions/files/` | 扩展代码本体（从用户目录备份） |
| `extensions/MISSING-extensions.md` | 未备份扩展清单（见下方备注） |
| `config/` | `~/.config` 下关键配置 + 壁纸 `background` + Rime 词库 |
| `system/` | pacman 源配置、已启用系统服务列表 |
| `home/` | `.zshrc` / `.p10k.zsh` / `.bashrc` / `.bash_profile` |
| `themes/MacOSX.tar.gz` | macOS 光标主题 |
| `themes/WhiteSur.tar.gz` | WhiteSur GTK 主题（窗口外观） |
| `themes/parts/` | AZ-OS-3D 图标主题（34 个 1MB 分片，脚本自动拼接） |

## 备注

### 1. 关于主题分片

AZ-OS-3D 图标主题原始压缩包 34MB，超过 Gitee 单次推送限制，因此被切成
34 个 1MB 分片存放在 `themes/parts/`。`restore.sh` 会自动用 `cat` 拼接还原，
**无需手动处理**。

### 2. 8 个「幽灵扩展」需要手动补装

以下扩展在当前系统的 dconf 中标记为「已启用」，但系统中实际**不存在其文件**
（属于残留记录，当前并未真正运行）。它们的启用状态已保存在
`gnome-settings.conf` 中，新系统 `dconf load` 后会被标记为启用；
**但需要你手动从 Extension Manager 安装对应扩展，才会真正生效**：

| # | UUID | 作用 |
|---|------|------|
| 1 | `forge@jmmaranan.com` | 平铺窗口管理器（自动平铺窗口） |
| 2 | `appmenu-is-back@fthx` | 把应用菜单放回顶栏 |
| 3 | `appnameindicator@dev64.xyz` | 顶栏显示当前应用名称 |
| 4 | `active-app-indicator@morhenac` | 顶栏显示当前应用图标 |
| 5 | `lunarcal@ailin.nemui` | 日历显示农历 |
| 6 | `system-monitor-next@paradoxxx.zero.gmail.com` | 顶栏系统监视器（CPU/内存/网络） |
| 7 | `battery-usage-wattmeter@halfmexicanhalfamazing.gmail.com` | 顶栏显示电池功率（瓦特） |
| 8 | `kimpanel@kde.org` | KDE 输入法面板支持 |

补装方法：打开 **Extension Manager**（restore.sh 已安装）逐个搜索安装即可。

> 已完整备份并会自动还原的是另外 **17 个实际运行的扩展**，
> 见 `extensions/enabled.txt` 与 `extensions/files/`。

### 3. 不备份的内容（故意）

- `/etc/fstab`、`/etc/default/grub`、`/etc/mkinitcpio.conf`：分区 UUID、引导配置与具体硬件绑定，跨机还原会导致**无法开机**
- Rime 的 `build/` 目录：部署时自动重新生成
- 缓存、日志、临时文件

### 4. 适用性

- 仅适用于 **Arch Linux + GNOME**
- 用户名默认为 `ailun`，脚本会用当前登录用户名自动适配家目录
- 仓库包含用户级配置（部分配置里含用户名路径）
