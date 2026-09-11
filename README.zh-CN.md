<div align="center">

[English](README.md) ・ [日本語](README.ja.md) ・ 简体中文

# rp

**跳转、克隆、新建、打开仓库，不打断心流。**

<!-- demo: a GIF of hub mode goes here (#7) -->

</div>

一个架在 [ghq](https://github.com/x-motemen/ghq) 和 [fzf](https://github.com/junegunn/fzf) 之上的 zsh 函数。先选仓库，再告诉它要做什么——也可以先指定动作。两种顺序，同一个选择器。

## 环境要求

[`ghq`](https://github.com/x-motemen/ghq)、[`fzf`](https://github.com/junegunn/fzf) **0.63.0+**（hub 模式用到了 `--footer`；各子命令在更旧的版本上也能工作）和 `git`。`rp` 会在首次使用时指出缺的是哪一个，而不是等子命令跑到一半才失败。

**刻意只支持 zsh**——见[常见问题](#常见问题)。

<details>
<summary>可选命令，以及少了各自会失去什么</summary>

| 命令 | 用于 | 没有它时 |
| --- | --- | --- |
| [`gh`](https://cli.github.com/) | 不带参数的 `rp get`，以及 hub 模式里的 `^G`（从你的远程仓库中挑选） | 显式给 `rp get` 传一个 URL；hub 模式中不提供 `^G` |
| [`eza`](https://github.com/eza-community/eza) | fzf 内的目录预览 | 回退到 `ls -la`，或 [`RP_PREVIEW_CMD`](#配置) 指定的命令 |
| [`tmux`](https://github.com/tmux/tmux) | 在 herdr 之外使用 `-s` / `-w` | 只能省略 `-s` / `-w` |
| [`herdr`](https://herdr.dev) + [`jq`](https://jqlang.github.io/jq/) | 在 herdr 之内使用 `-s` / `-w` | 只能省略 `-s` / `-w` |
| `code` / `vim` / `nvim` | `rp open` | `rp open` 在 [`$RP_EDITOR`、`$VISUAL` 和 `$EDITOR`](#配置) 之后，沿这份列表逐个回退 |

</details>

## 安装

通过 Homebrew 安装会一并装上 `ghq` 和 `fzf`。其他方式只安装 shell 代码，所以请先运行 `brew install ghq fzf`（或你所在平台的等价命令）。

```bash
brew install peinan/tap/rp
```

```zsh
# .zshrc
source "$(brew --prefix)/share/rp/rp.plugin.zsh"
```

<details>
<summary>sheldon、zinit / znap / zplug、antidote、Oh My Zsh、手动</summary>

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

<details>
<summary>升级</summary>

用你的安装方式所谓的“更新”命令即可：

| 安装方式 | 升级 |
| --- | --- |
| Homebrew | `brew update && brew upgrade peinan/tap/rp` |
| sheldon | `sheldon lock --update` |
| zinit | `zinit update peinan/rp` |
| znap | `znap pull` |
| zplug | `zplug update` |
| antidote | `antidote update` |
| Oh My Zsh | `git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/rp" pull` |
| 手动 | `git -C ~/.local/share/rp pull` |

然后执行 `exec zsh`。`rp` 是 autoload 的，已经运行过它的 shell 会把旧的函数体留在内存里继续用。

</details>

## 用法

**命令参考以 `rp help` 为准**——它会打印所有命令、实际绑定的 hub 按键，以及 `RP_*` 变量。下面这张表是刻意写短的，这样需要保持更新的完整列表只有一份，而不是两份。

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

不是子命令的裸词会被当作模糊查询，所以 `rp dot` 等同于 `rp cd dot`。

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

### Hub 模式

不带参数的 `rp` 会列出你的仓库，然后询问要拿选中的那个做什么。`enter` 做的仍然是不带参数的 `rp` 一直以来做的事，所以常用路径没有变化；其余按键不用子命令也能到达别的操作。

<!-- demo: a GIF of hub mode — pick a repository, then ^O for the action list (#7) -->

| 按键 | `RP_KEY_*` | 动作 |
| --- | --- | --- |
| `enter` | — | `cd` 过去 |
| `^S` | `RP_KEY_SESSION` | 作为会话打开（tmux 会话 / herdr 工作区） |
| `^T` | `RP_KEY_WINDOW` | 在新窗口中打开（tmux 窗口 / herdr 标签页） |
| `^O` | `RP_KEY_ACTIONS` | 从全部动作中选择，包括 `copy path` 和 `remove` |
| `^R` | `RP_KEY_NEW` | 用你输入的内容作为名字创建仓库 |
| `^X` | `RP_KEY_REMOVE` | 删除它（会先确认，并拒绝未克隆的条目） |
| `^G` | `RP_KEY_TOGGLE` | 在本地仓库和 GitHub 仓库之间切换 |

尚未克隆的条目——实际上就是来自 `^G` 的那些——无论你选的是哪个动作，都会先被克隆下来。除 `enter` 之外的每个按键都是可以改的默认值，见[配置](#配置)。

<details>
<summary>用起来之后值得知道的细节</summary>

`^O` 菜单支持模糊搜索，所以按 `^O` 再输入 `ed` 就能到达“open in editor”，什么都不用记。它的标签会写明 `-s` / `-w` 实际会用哪个复用器——在 tmux 下是“new session”和“new window”，在 herdr 里是“new workspace”和“new tab”。

`^R` 把你输入的文本当作名字，所以输入 `me/newthing` 再按 `^R` 就会创建它。名字会在任何东西落到磁盘之前先检查，目标位置则在之后才选，所以中途取消不会留下任何残留。

你在这里绑定的按键会取代 fzf 自己对该键的绑定。用默认值时这种情况会发生两次：`^R` 取代了 `down-match`（方向键和 `alt-down` 仍然可用），`^G` 取代了四个 `abort` 键中的一个（`esc`、`^C` 和 `^Q` 还在）。

</details>

### 终端复用器集成

`-s` 和 `-w` 表示的是目标位置，而不是操作的一部分，所以它们在 `cd`、`get` 和 `create` 上含义相同。它们会自动选择复用器：设置了 `$HERDR_ENV` 时用 [herdr](https://herdr.dev)，否则用 tmux。

<!-- demo: a GIF of `rp get -w user/repo` — clone straight into a new window / tab (#7) -->

| 选项 | tmux | herdr |
| --- | --- | --- |
| `-s`, `--tmux-session` | 新建会话（按名字复用已有的） | 新建工作区（按标签复用） |
| `-w`, `--tmux-window` | 新建窗口 | 新建标签页 |

## 配置

所有配置都是环境变量，所以你只需要改 `.zshrc` 这一个地方。**请 `export` 它们，而不是只做普通赋值**：herdr 弹窗是在 herdr 守护进程派生的进程里运行 `rp` 的，不是在你的 shell 里。

`rp open` 会沿着一条链依次查找，使用找到的第一个命令：

```text
rp open <editor>  →  $RP_EDITOR  →  $VISUAL  →  $EDITOR  →  code  →  vim  →  nvim
```

```zsh
export RP_EDITOR="code -n"   # arguments are fine; only the first word is looked up
```

<details>
<summary>预览：<code>RP_PREVIEW_CMD</code>、<code>RP_PREVIEW_REMOTE_CMD</code>、<code>RP_PREVIEW_WINDOW</code></summary>

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

</details>

<details>
<summary>Hub 模式按键：<code>RP_KEY_*</code></summary>

用 fzf 的按键名称——`ctrl-s`、`alt-x`、`f5`、`shift-delete`：

```zsh
export RP_KEY_REMOVE=f12     # park the destructive key out of reach
export RP_KEY_TOGGLE=alt-g
```

- 名称只能由字母、数字和 `-` 组成。这覆盖了所有 `ctrl-`、`ctrl-alt-` 和 `alt-` 组合键、所有功能键和所有具名键；标点符号键不在其中，因为按键名同时也会成为 footer 上的文字。
- `enter` 不可配置，把别的动作绑到它上面会直接报错，而不是变成一个被 fzf 悄无声息丢掉的绑定。把两个动作绑到同一个键上也一样会报错。
- 空值表示“用默认值”，不是“解除绑定”。想让 `^X` 不碍事，做法是 `RP_KEY_REMOVE=f12`。
- 单个裸字符（`RP_KEY_NEW=x`）在 fzf 里是合法按键，但会让筛选框没法用：按下去触发的是动作，而不是输入这个字符。

hub 模式启动时 `rp` 会检查这些变量，并指出出问题的是哪一个，所以拼写错误传不到 fzf。其他子命令都不读它们，所以一个错误的 `RP_KEY_*` 不会影响 `rp path` 和 `rp cd`。

</details>

## Herdr 插件

在 [herdr](https://herdr.dev) 里，每个仓库都离任意窗格只有一键之遥：弹窗运行 hub 模式，把你选中的东西作为工作区或标签页打开。插件就在本仓库里（`herdr-plugin.toml`），需要 herdr 0.9.0 或更新的版本。

```bash
herdr plugin install peinan/rp
```

herdr 插件不能自带按键绑定，所以请自己绑定 `rp.hub` 这个动作，然后重新加载配置。一个绑定就能到达全部功能，因为按键定义在选择器内部，而不是在插件清单里——给 `rp` 增加一个操作，不需要新增动作、窗格或按键绑定。

```toml
# ~/.config/herdr/config.toml
[[keys.command]]
key = "prefix+ctrl+r"
type = "plugin_action"
command = "rp.hub"
description = "jump to a ghq repository"
```

<details>
<summary>与 shell 提示符下有什么不同，以及哪些命令必须在 <code>PATH</code> 上</summary>

弹窗不会比选择器活得更久，所以没有可以 `cd` 的对象。动作菜单里因此没有 `cd here`，`enter` 改为打开工作区。

插件从 herdr 管理的检出目录里运行它自己那份 `functions/rp`，所以不需要先安装 zsh 插件。`rp cd` 和 `rp path` 仍然只支持 zsh：插件进程无法改变你 shell 的工作目录。`ghq`、`fzf`、`git` 和 `jq` 必须在 herdr 启动时的 `PATH` 上，要用 `^G` 还需要 `gh`，`RP_*` 也必须在它的环境里——见[配置](#配置)。

想动手改它的话，不要安装，而是链接一份本地检出：`herdr plugin link /path/to/rp`。

</details>

## 常见问题

<details>
<summary><b><code>rp</code> 是什么？为什么叫这个名字？</b></summary>

是“repo”的缩写——这个函数在被缩短之前就叫这个名字，它内部的辅助函数至今也还这么叫（`_repo_hub_pick`、`_repo_open_dest` 等等）。

它是一个统一入口，覆盖你对已克隆仓库所做的一切：`cd` 过去、打印它的路径、克隆一个新的、创建一个新的、用编辑器打开、复制路径、删除。它是一个架在 [ghq](https://github.com/x-motemen/ghq) 和 [fzf](https://github.com/junegunn/fzf) 之上的 zsh 函数，所以你挑选的那份列表就是 `ghq list`，挑选这件事则由 fzf 来做。

两个方向都能用。先指定动作再选仓库（`rp cd -s foo`），或者直接运行不带参数的 `rp`——也就是 hub 模式——先选仓库，之后再决定拿它做什么。

结果在哪里打开是第三个选择，和前两者互相独立：当前这个 shell、tmux 的会话或窗口、herdr 的工作区或标签页，或者一个编辑器。

</details>

<details>
<summary><b>它和 zoxide、<code>ghq list | fzf</code> 相比有什么不同？</b></summary>

`ghq` 已经知道你磁盘上每个仓库在哪里。`rp` 是在这份列表上执行操作的前端，真正称得上不同的有三点：

- **原生基于 ghq**。`ghq list` 就是唯一的事实来源，所以你能到达的正是你已经克隆下来的：没有需要预热的 frecency 数据库，没有东西要导入，一台新机器只要运行过一次 `ghq get` 就能用。zoxide 回答的是“我去过哪里”，`rp` 回答的是“我克隆了什么”。这是两个不同的问题，两个都用是合理的。
- **不只是 `cd`**。克隆、创建、用编辑器打开、复制路径、删除——而且可以把结果送到 tmux 的会话或窗口、herdr 的工作区或标签页，而不只是当前 shell。
- **两种顺序都行**。已经知道要哪个时用 `rp cd -s foo`；更想先选、之后再决定时就用不带参数的 `rp`。

`ghq list | fzf` 的 shell 函数能覆盖 `cd` 这个场景，而且覆盖得很好，所以大多数人手上都已经有一个了。但只要你想要“克隆这一个，然后在新工作区里打开它”，你就得自己把操作 × 目标这张矩阵写出来。`rp` 就是这张矩阵。

</details>

<details>
<summary><b><code>rp</code> 和 <code>rp hub</code> 有什么区别？</b></summary>

没有区别。`rp hub` 只是把不带参数的 `rp` 写全——hub 模式是默认入口，不是一条你必须敲的命令。

</details>

<details>
<summary><b><code>-s</code> 和 <code>-w</code> 到底做什么？</b></summary>

它们指定的是目标位置，不是操作，所以在 `cd`、`get` 和 `create` 上含义相同：`-s` 打开一个会话，`-w` 打开一个窗口。至于是哪个复用器，会自动替你决定——设置了 `$HERDR_ENV` 时用 [herdr](https://herdr.dev)，否则用 tmux——而且 `-s` 会复用同名的已有会话或工作区，不会堆出一堆重复的。见[终端复用器集成](#终端复用器集成)。

</details>

<details>
<summary><b>选中一个还没克隆的仓库会怎样？</b></summary>

它会先被克隆下来，然后你选的那个动作再对它执行。实际上这种情况出现在 `^G` 上——它把 hub 列表从你的本地仓库切换到你的 GitHub 仓库。

</details>

<details>
<summary><b><code>rp open</code> 用的是哪个编辑器？</b></summary>

沿着 `rp open <editor>` → `$RP_EDITOR` → `$VISUAL` → `$EDITOR` → `code` → `vim` → `nvim` 找到的第一个。取值可以带参数（`RP_EDITOR="code -n"`），也可以是绝对路径；即使它已经不存在，这条链也不会就此断掉——`rp` 会继续看下一个候选。见[配置](#配置)。

</details>

<details>
<summary><b>hub 模式的按键能改吗？</b></summary>

除 `enter` 之外都能改，用 `RP_KEY_*`，按 fzf 的按键名称来写。它们会在 hub 模式启动时被检查，`rp` 会指出出问题的是哪一个变量，所以拼写错误传不到 fzf。没有办法解除某个键的绑定——只能把它挪到够不着的地方，`RP_KEY_REMOVE=f12` 就是干这个用的。见[配置](#配置)。

</details>

<details>
<summary><b>能在脚本里用吗？</b></summary>

`rp path` 打印路径而不是 `cd` 过去，所以 `cd "$(rp path dot)"` 是可行的；带上查询词时，它根本不用打开选择器就能解析出结果。`rp path` 和 `rp cd` 都不读 `RP_KEY_*`，所以错误的按键绑定弄不坏它们。

</details>

<details>
<summary><b>在 herdr 里能用吗？</b></summary>

能。只要设置了 `$HERDR_ENV`，`-s` / `-w` 就会自动解析到 herdr，不管你有没有另外装什么。在此之上，`rp` 还以 herdr 插件的形式发布，所以一个按键绑定就能在弹窗里打开 hub 模式，并从那里到达每一个操作——见 [Herdr 插件](#herdr-插件)。

</details>

<details>
<summary><b>为什么 <code>rp</code> 是 shell 函数，而不是 <code>PATH</code> 上的可执行文件？</b></summary>

因为 `rp cd` 要改的，正是你当前这个 shell 的工作目录，而子进程无法 `cd` 自己的父进程。这也是升级为什么传不到一个已经运行过 `rp` 的 shell——见下文。

</details>

<details>
<summary><b>只支持 zsh？bash 和 fish 呢？</b></summary>

这是刻意的，原因不是上面那条 `cd` 限制——它对 bash 和 fish 同样成立，而且两者都能定义函数。真正的原因是 `functions/rp` 从头到尾都是一个 zsh autoload 函数：zsh 的参数展开（`${(@f)…}`、`${(qq)…}`、`$+commands[…]`）、`local -a` / `local -i`，以及通过动态作用域写入调用者作用域的辅助函数。移植是把这套管道重写一遍，而不是加一层兼容垫片，fish 就更远了——它的函数模型和引号规则完全是另一套。

如果真要做，它会是一个与 shell 无关的核心，只负责输出一个决策，让每种 shell 只剩一层仅负责 `cd` 的薄包装。hub 模式内部已经是这个形状了，因为它的第一阶段就是打印一个 token，再由调用方据此行动。相关讨论在 [#10](https://github.com/peinan/rp/issues/10)。

</details>

<details>
<summary><b>不带参数的 <code>rp</code> 没有反应，或者打印 <code>unknown option: --footer</code></b></summary>

你的 `fzf` 比 0.63.0 旧。hub 模式用到了 `--footer`，而 fzf 对无法识别的选项是直接报错而不是忽略，所以每次调用都会失败。现在的 `rp` 会把这件事直接说出来。只有 hub 模式有这道门槛：动词加名词形式的子命令没有传任何这么新的东西，在老得多的 fzf 上照样能用。

</details>

<details>
<summary><b>升级了，但什么都没变</b></summary>

`rp` 是 autoload 的，已经运行过它的 shell 会把旧的函数体留在内存里。开一个新 shell，或者执行 `exec zsh`。

</details>

<details>
<summary><b>预览窗格是空的，或者显示报错</b></summary>

没有 [`eza`](https://github.com/eza-community/eza) 时，预览会回退到 `ls -la`。如果你设置了 `RP_PREVIEW_CMD`，注意：fzf 用 `$SHELL -c` 运行这个模板；`{}` 是选中的 `host/user/repo`，`$RP_ROOT` 是 `$(ghq root)` 且需要加引号；模板里的 `;;` 会让 hub 模式的 `case` 提前结束。见[配置](#配置)。

</details>

## 许可证

[MIT](./LICENSE)
