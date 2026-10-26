# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─────────────────────────────────────────────────────────────
# ~/.zshrc  —  Oh My Zsh + Powerlevel10k + 常用插件
# ─────────────────────────────────────────────────────────────

# 如果不是交互式 shell，直接返回
[[ $- != *i* ]] && return

# ── 基础环境变量（从 .bashrc 保留） ─────────────────────────
export PATH=/home/ailun/.opencode/bin:$PATH

# 中文输入法 (ibus)
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export SDL_IM_MODULE=ibus

# ── 历史记录 ───────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY          # 多终端共享历史
setopt HIST_IGNORE_DUPS       # 忽略连续重复命令
setopt HIST_IGNORE_ALL_DUPS   # 删除旧的重复命令
setopt HIST_IGNORE_SPACE      # 忽略空格开头的命令
setopt HIST_REDUCE_BLANKS     # 去除多余空格
setopt INC_APPEND_HISTORY     # 立即写入历史

# ── Oh My Zsh ──────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

# 主题：Powerlevel10k（首次运行 zsh 会自动启动 p10k 配置向导）
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件（Oh My Zsh 自带的 + 系统 zsh 包）
# git:       git 别名与提示
# sudo:      按两下 ESC 自动加 sudo
# extract:   `extract xxx.tar.gz` 智能解压
# z:         智能目录跳转（基于历史）
# colored-man-pages: man 页面彩色化
# command-not-found: 命令找不到时提示安装包
plugins=(
  git
  sudo
  extract
  z
  colored-man-pages
  command-not-found
)

source $ZSH/oh-my-zsh.sh

# ── 系统 zsh 插件（pacman 装的，source 它们的 .zsh） ──────
# 自动建议（灰色幽灵命令，按 → 接受）
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
# 语法高亮（必须放最后）
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
# 额外补全定义（zsh-completions 装在 site-functions 下，zsh 默认会扫到，这里显式确保）
fpath=(/usr/share/zsh/site-functions $fpath)

# ── fzf（Ctrl+R 历史搜索 / Ctrl+T 文件 / Alt+C 目录） ─────
source /usr/share/fzf/key-bindings.zsh 2>/dev/null
source /usr/share/fzf/completion.zsh 2>/dev/null
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ── 常用别名 ───────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'

# ── fastfetch 开屏（每次开终端显示系统信息） ───────────────
# 注释掉下面这行可关闭开屏
# fastfetch 2>/dev/null

# ── Powerlevel10k 实例化（如果生成了配置则加载） ───────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# To customize prompt, run `p10k configure` or install Powerlevel10k
# 首次进入 zsh 时，p10k 会自动启动配置向导；也可手动运行 `p10k configure`
