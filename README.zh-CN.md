<div align="center">

[English](README.md) ・ [日本語](README.ja.md) ・ 简体中文

# rp

**每个仓库，每项操作，一键可达。**

<!-- demo: a GIF of hub mode goes here (#7) -->

</div>

`rp` 是一个 zsh 函数，它把 `ghq` 和 `fzf` 包装成一个统一入口，覆盖你对本地克隆仓库所做的一切：切换过去、打印路径、克隆一个新的、创建一个新的、用编辑器打开，或者删除。

因为 `rp cd` 必须改变你*当前* shell 的工作目录，`rp` 是一个 shell 函数，而不是 `PATH` 上的可执行文件——子进程无法 `cd` 自己的父进程。

它在两个方向上都能用：先指定动作，再选仓库；或者直接运行不带参数的 `rp`——也就是 hub 模式——先选仓库，再决定拿它做什么。

```console
$ rp                # hub mode: pick a repository, then choose an action
$ rp dot            # fuzzy match and cd to the best match
$ rp path dot       # print the path instead of cd-ing
$ rp get -w x/y     # clone and open in a new window
```

## 为什么用 rp？

`ghq` 已经知道你磁盘上每个仓库在哪里。`rp` 是在这份列表上执行操作的前端。

- **原生基于 ghq**。`ghq list` 和 `ghq root` 就是唯一的事实来源，所以你能到达的，正是你已经克隆下来的。没有需要预热的 frecency 数据库，也没有任何东西要导入；一台新机器只要运行过一次 `ghq get` 就能用。zoxide 回答的是*我去过哪里*，`rp` 回答的是*我克隆了什么*。这是两个不同的问题，两个都用是合理的。
- **不只是 `cd`**。克隆、创建、用编辑器打开、复制路径、删除——而且可以把结果送到 tmux 的会话或窗口、herdr 的工作区或标签页，而不只是送到当前 shell。
- **两种顺序都支持**。已经知道要哪个仓库时，用 `rp cd -s foo`；更想先选仓库、之后再决定做什么时，就直接运行 `rp`。

一个 `ghq list | fzf` 的 shell 函数——大多数人手上已经有了——能覆盖 `cd` 这个场景，而且覆盖得很好。但只要你想要“克隆这一个，然后在新工作区里打开它”，你就得自己把“操作 × 目标”这张矩阵写出来。`rp` 就是这张矩阵。

## 环境要求

**刻意只支持 zsh**。原因不是上面那条 `cd` 限制——它对 bash 和 fish 同样成立，而且两者都能定义函数。真正的原因是 `functions/rp` 从头到尾都是一个 zsh autoload 函数：zsh 的参数展开（`${(@f)…}`、`${(qq)…}`、`$+commands[…]`）、`local -a` / `local -i`，以及通过动态作用域写入调用者作用域的辅助函数。移植到 bash 是把这套管道重写一遍，而不是加一层兼容垫片，fish 就更远了。如果真要做，它会是一个与 shell 无关的核心，只负责输出一个决策，让每种 shell 只剩一层仅负责 `cd` 的薄包装——相关讨论在 [#10](https://github.com/peinan/rp/issues/10)。

**必需**

| 命令 | 用途 |
| --- | --- |
| [`ghq`](https://github.com/x-motemen/ghq) | 定位、克隆和列出仓库 |
| [`fzf`](https://github.com/junegunn/fzf) | 交互式选择与模糊匹配。hub 模式需要 **0.63.0+**（它用到了 `--footer`）；各子命令在更旧的版本上也能工作 |
| `git` | 初始化由 `rp create` 创建的仓库 |

`rp` 会在首次使用时报告这些命令缺了哪些，而不是等子命令跑到一半才失败；如果找到的 fzf 太旧，hub 模式也会明说。

**可选**

| 命令 | 用于 | 没有它时 |
| --- | --- | --- |
| [`gh`](https://cli.github.com/) | 不带参数的 `rp get`，以及 hub 模式里的 `^G`（从你的远程仓库中挑选） | 显式给 `rp get` 传一个 URL；hub 模式中不提供 `^G` |
| [`eza`](https://github.com/eza-community/eza) | fzf 内的目录预览 | 回退到 `ls -la`，或 [`RP_PREVIEW_CMD`](#配置) 指定的命令 |
| [`tmux`](https://github.com/tmux/tmux) | 在 herdr 之外使用 `-s` / `-w` | 只能省略 `-s` / `-w` |
| [`herdr`](https://herdr.dev) + [`jq`](https://jqlang.github.io/jq/) | 在 herdr 之内使用 `-s` / `-w` | 只能省略 `-s` / `-w` |
| `code` / `vim` / `nvim` | `rp open` | `rp open` 在 [`$RP_EDITOR`、`$VISUAL` 和 `$EDITOR`](#配置) 之后，沿这份列表逐个回退 |

## 安装

通过 Homebrew 安装会一并装上 `ghq` 和 `fzf`。其他方式只安装 shell 代码，所以请先自己运行 `brew install ghq fzf`（或你所在平台的等价命令）。

### Homebrew

```bash
brew install peinan/tap/rp
```

然后在 `.zshrc` 中加入：

```zsh
source "$(brew --prefix)/share/rp/rp.plugin.zsh"
```

<details>
<summary>其他方式——sheldon、zinit / znap / zplug、antidote、Oh My Zsh、手动</summary>

**sheldon**

```toml
[plugins.rp]
github = "peinan/rp"
```

**zinit / znap / zplug**

```zsh
zinit light peinan/rp
znap source peinan/rp
zplug "peinan/rp"
```

**antidote**

```text
# ~/.zsh_plugins.txt
peinan/rp
```

**Oh My Zsh**

```bash
git clone https://github.com/peinan/rp \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/rp"
```

```zsh
# .zshrc
plugins=(... rp)
```

**手动**

```bash
git clone https://github.com/peinan/rp ~/.local/share/rp
```

```zsh
# .zshrc
source ~/.local/share/rp/rp.plugin.zsh
```

</details>

## 升级

用你的安装方式所谓的“更新”命令即可：

| 安装方式 | 升级命令 |
| --- | --- |
| Homebrew | `brew update && brew upgrade peinan/tap/rp` |
| sheldon | `sheldon lock --update` |
| zinit | `zinit update peinan/rp` |
| znap | `znap pull` |
| zplug | `zplug update` |
| antidote | `antidote update` |
| Oh My Zsh | `git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/rp" pull` |
| 手动 | `git -C ~/.local/share/rp pull` |

然后开一个新 shell，或者执行 `exec zsh`。`rp` 是 autoload 的，已经运行过它的 shell 会把旧的函数体留在内存里继续用。

## 用法

**命令参考以 `rp help` 为准**。它会打印所有命令、实际绑定的 hub 按键，以及 `RP_*` 变量。下面这张表是刻意写得更短的，这样需要保持更新的完整命令列表只有一份，而不是两份。

| 命令 | 作用 |
| --- | --- |
| `rp`, `rp hub` | hub 模式：先选仓库，再选动作 |
| `rp <query>` | 模糊匹配并 `cd` 到最佳匹配 |
| `rp cd, c [-s\|-w] [query]` | `cd` 到某个仓库 |
| `rp path, p [query]` | 打印它的路径，而不是 `cd` 过去 |
| `rp get, g [-s\|-w] [url]` | 克隆一个（不给 URL 时进入交互式选择） |
| `rp create, new, n [-s\|-w]` | 创建一个，并在 `$(ghq root)` 下 `git init` |
| `rp open, o [editor]` | 用编辑器打开一个 |
| `rp list, ls` | 列出仓库 |
| `rp remove, rm, r` | 删除一个（会先确认） |
| `rp --version, -v` | 打印版本号 |

`-s` 和 `-w` 表示的是目标位置，而不是操作的一部分，所以它们在 `cd`、`get` 和 `create` 上含义相同——见[终端复用器集成](#终端复用器集成)。

不是子命令的裸词会被当作模糊查询，所以 `rp dot` 等同于 `rp cd dot`。

### Hub 模式

不带参数运行 `rp` 就进入 hub 模式：它列出你的仓库，然后询问要拿选中的那个做什么。`enter` 做的仍然是不带参数的 `rp` 一直以来做的事，所以常用路径没有变化；其余按键让你不用子命令也能到达别的操作。`rp hub` 是同一件事的显式写法。

除 `enter` 之外的每个按键都只是可以改的默认值——见[配置](#配置)。`rp help` 会打印实际绑定的按键。

| 按键 | `RP_KEY_*` | 动作 |
| --- | --- | --- |
| `enter` | — | `cd` 过去 |
| `^S` | `RP_KEY_SESSION` | 作为会话打开（tmux 会话 / herdr 工作区） |
| `^T` | `RP_KEY_WINDOW` | 在新窗口中打开（tmux 窗口 / herdr 标签页） |
| `^O` | `RP_KEY_ACTIONS` | 从全部动作中选择，包括 `copy path` 和 `remove` |
| `^R` | `RP_KEY_NEW` | 用你输入的内容作为名字创建仓库 |
| `^X` | `RP_KEY_REMOVE` | 删除它（会先确认，并拒绝未克隆的条目） |
| `^G` | `RP_KEY_TOGGLE` | 在本地仓库和 GitHub 仓库之间切换 |

选中一个尚未克隆的条目——实际上就是来自 `^G` 的那些——会先把它克隆下来，无论你选的是哪个动作。`^O` 背后的动作菜单支持模糊搜索，所以按 `^O` 再输入 `ed` 就能到达“open in editor”，什么都不用记。菜单标签会写明 `-s` / `-w` 实际会用哪个复用器——在 tmux 下是“new session”和“new window”，在 herdr 里是“new workspace”和“new tab”。

`^R` 把你输入的文本当作名字，所以输入 `me/newthing` 再按 `^R` 就会创建它。名字会在任何东西落到磁盘之前先检查，目标位置则在之后才选，所以中途取消不会留下任何残留。

你在这里绑定的按键会取代 fzf 自己对该键的绑定。用默认值时这种情况会发生两次：`^R` 取代了 `down-match`（方向键和 `alt-down` 仍然可用），`^G` 取代了四个 `abort` 键中的一个（`esc`、`^C` 和 `^Q` 还在）。

### 终端复用器集成

`-s` 和 `-w` 会自动选择复用器：设置了 `$HERDR_ENV` 时用 [herdr](https://herdr.dev)，否则用 tmux。

| 选项 | tmux | herdr |
| --- | --- | --- |
| `-s`, `--tmux-session` | 新建会话（按名字复用已有的） | 新建工作区（按标签复用） |
| `-w`, `--tmux-window` | 新建窗口 | 新建标签页 |

### 示例

```bash
rp                              # hub mode: pick a repository, then choose an action
rp dot                          # fuzzy match "dot" and cd to the best match
rp cd -s dot                    # same, but in a new session / workspace
cd "$(rp path dot)"             # use the path in command substitution
rp get github.com/user/repo     # clone by URL
rp get -w user/repo             # clone and open in a new window / tab
rp create user/new-repo         # mkdir + git init under $(ghq root)
rp open nvim                    # pick a repository and open it in neovim
rp remove                       # pick a repository and delete it (asks first)
```

## 配置

所有配置都是环境变量，所以你只需要改 `.zshrc` 这一个地方。**请 `export` 它们，而不是只做普通赋值**：herdr 弹窗是在 herdr 守护进程派生的进程里运行 `rp` 的，不是在你的 shell 里，所以普通赋值能影响你的提示符，却影响不到弹窗——而且 `export` 也只有在 herdr 于它之后启动时才能传到 herdr。

### 编辑器

`rp open` 会沿着一条链依次查找，使用找到的第一个命令：

```text
rp open <editor>  →  $RP_EDITOR  →  $VISUAL  →  $EDITOR  →  code  →  vim  →  nvim
```

```zsh
export RP_EDITOR="code -n"   # arguments are fine; only the first word is looked up
```

取值可以是绝对路径；即使它已经失效，这条链也不会就此断掉——`rp` 会继续看下一个候选。

### 预览

| 变量 | 默认值 |
| --- | --- |
| `RP_PREVIEW_CMD` | `eza "$RP_ROOT"/{} --color=always`，没有 `eza` 时为 `ls -la "$RP_ROOT"/{}` |
| `RP_PREVIEW_REMOTE_CMD` | `gh repo view {} …`，用于 `^G` 和 `rp get` 背后的 GitHub 列表 |
| `RP_PREVIEW_WINDOW` | 未设置：每个选择器各用各的（`down:3:wrap`，远程列表为 `down:5:wrap`） |

fzf 用 `$SHELL -c` 运行这些模板。`{}` 是选中的 `host/user/repo`，`$RP_ROOT` 是 `$(ghq root)`——记得加引号，因为路径里可能有空格：

```zsh
export RP_PREVIEW_CMD='onefetch "$RP_ROOT"/{} 2>/dev/null || ls -la "$RP_ROOT"/{}'
```

不要在里面出现 `;;`：hub 模式把两个模板嵌在同一个 `case` 里，`;;` 会让它提前结束。

### Hub 模式按键

用 fzf 的按键名称——`ctrl-s`、`alt-x`、`f5`、`shift-delete`：

```zsh
export RP_KEY_REMOVE=f12     # park the destructive key out of reach
export RP_KEY_TOGGLE=alt-g
```

- 名称只能由字母、数字和 `-` 组成。这覆盖了所有 `ctrl-`、`ctrl-alt-` 和 `alt-` 组合键、所有功能键和所有具名键；标点符号键不在其中，因为按键名同时也会成为 footer 上的文字。
- `enter` 不可配置，把别的动作绑到它上面会直接报错，而不是变成一个被 fzf 悄无声息丢掉的绑定。
- 把两个动作绑到同一个键上也一样会报错，原因相同。
- 空值表示“用默认值”，不是“解除绑定”——没有办法去掉某个键。想让 `^X` 不碍事，做法是 `RP_KEY_REMOVE=f12`。
- 单个裸字符（`RP_KEY_NEW=x`）在 fzf 里是合法按键，但会让筛选框没法用：按下去触发的是动作，而不是输入这个字符。

hub 模式启动时 `rp` 会检查这些变量，并指出出问题的是哪一个，所以拼写错误传不到 fzf。其他子命令都不读它们，所以一个错误的 `RP_KEY_*` 不会影响 `rp path` 和 `rp cd`。

## Herdr 插件

在 [herdr](https://herdr.dev) 里，每个仓库都离任意窗格只有一键之遥：弹窗运行 hub 模式，把你选中的东西作为工作区或标签页打开。插件就在本仓库里（`herdr-plugin.toml`），需要 herdr 0.9.0 或更新的版本。

```bash
herdr plugin install peinan/rp
```

herdr 插件不能自带按键绑定，所以请在 `~/.config/herdr/config.toml` 里绑定这个动作，然后重新加载配置：

```toml
[[keys.command]]
key = "prefix+ctrl+r"
type = "plugin_action"
command = "rp.hub"
description = "jump to a ghq repository"
```

| 动作 | 作用 |
| --- | --- |
| `rp.hub` | 在弹窗中打开 hub 模式：先选仓库，再决定拿它做什么 |

一个绑定就能到达全部功能，因为按键定义在选择器内部，而不是在插件清单里——用默认值时，`enter` 打开工作区，`^T` 打开标签页，`^O` 打开完整动作列表，`^R` 创建，`^X` 删除，`^G` 切换到你的 GitHub 仓库。见 [Hub 模式](#hub-模式)。给 `rp` 增加一个操作，不需要新增动作、窗格或按键绑定。

与在 shell 提示符下使用的唯一区别：弹窗不会比选择器活得更久，所以没有可以 `cd` 的对象。`cd here` 因此被去掉，`enter` 改为打开工作区。

插件从 herdr 管理的检出目录里运行它自己那份 `functions/rp`，所以不需要先安装 zsh 插件。`rp cd` 和 `rp path` 仍然只支持 zsh：插件进程无法改变你 shell 的工作目录。`ghq`、`fzf`、`git` 和 `jq` 必须在 herdr 启动时的 `PATH` 上，要用 `^G` 还需要 `gh`。`RP_*` 也必须在它的环境里——见[配置](#配置)。

想动手改它的话，不要安装，而是链接一份本地检出：`herdr plugin link /path/to/rp`。

## 许可证

[MIT](./LICENSE)
