# 未备份的扩展（幽灵扩展）

以下 8 个扩展在当前系统的 dconf `enabled-extensions` 中标记为「已启用」，
但全盘搜索 `/usr/share/gnome-shell/extensions/`、`~/.local/share/gnome-shell/extensions/`、`~/.local/share/flatpak/`
以及 `pacman -Ql` 均找不到其文件，属于 **残留的启用记录**，实际并未运行。

它们的状态已随 `gnome-settings.conf`（dconf dump）保存，
新系统执行 `dconf load /` 后会自动恢复「启用」。

## 清单

| # | UUID | 作用 |
|---|------|------|
| 1 | `forge@jmmaranan.com` | 平铺窗口管理器（类似 i3 自动平铺） |
| 2 | `appmenu-is-back@fthx` | 把应用菜单放回顶栏 |
| 3 | `appnameindicator@dev64.xyz` | 顶栏显示当前应用名称 |
| 4 | `active-app-indicator@morhenac` | 顶栏显示当前应用图标 |
| 5 | `lunarcal@ailin.nemui` | 日历显示农历 |
| 6 | `system-monitor-next@paradoxxx.zero.gmail.com` | 顶栏系统监视器（CPU/内存/网络） |
| 7 | `battery-usage-wattmeter@halfmexicanhalfamazing.gmail.com` | 顶栏显示电池功率（瓦特） |
| 8 | `kimpanel@kde.org` | KDE 输入法面板支持（配合 kimpanel 使用） |

## 如何补装

新系统还原后，打开 **Extension Manager**（已在 restore.sh 中安装），
逐个搜索上面的扩展名安装即可；装好后会自动处于启用状态（dconf 已记录）。

> 注意：以上扩展并非「备份遗漏」，而是当前系统本就不存在其文件。
> 已实际备份并会还原的是另外 17 个扩展，见 `extensions/enabled.txt` 与 `extensions/files/`。
