<div align="center">

# rp

**Jump, clone, create and open repositories without breaking your flow.**

<!-- demo: a GIF of hub mode goes here (#7) -->

</div>

A zsh function over [ghq](https://github.com/x-motemen/ghq) and
[fzf](https://github.com/junegunn/fzf). Pick a repository, then say what to do
with it — or name the action first. Either order, one picker.

```console
$ rp                # pick a repository, then choose an action
$ rp dot            # fuzzy match "dot" and cd there
$ rp get -w x/y     # clone it and open a new window
$ rp path dot       # print the path instead
```

## Why rp?

- **It is not only `cd`.** Clone, create, open in an editor, copy the path,
  remove — and send the result to a tmux session or window, or a herdr
  workspace or tab, instead of only the current shell.
- **ghq-native.** `ghq list` is the source of truth, so what you can reach is
  exactly what you have cloned: no frecency database to warm up, nothing to
  import, and a fresh machine works the moment `ghq get` has run once.
- **Both orderings.** `rp cd -s foo` when you know what you want; bare `rp`
  when you would rather pick first and decide after.

zoxide answers *where have I been*; `rp` answers *what have I cloned*. Using
both is reasonable. A `ghq list | fzf` function covers the `cd` case and covers
it well — but the moment you want "clone this one and open it in a new
workspace" you are writing the operation × destination matrix yourself. That
matrix is what `rp` is.

## Requirements

[`ghq`](https://github.com/x-motemen/ghq),
[`fzf`](https://github.com/junegunn/fzf) **0.63.0+** (hub mode uses `--footer`;
the subcommands work on older versions) and `git`. `rp` names whichever one is
missing on first use rather than failing partway through a subcommand.

**zsh only, and deliberately so** — see the [FAQ](#faq).

<details>
<summary>Optional commands, and what you lose without each</summary>

| Command | Needed for | Without it |
| --- | --- | --- |
| [`gh`](https://cli.github.com/) | `rp get` with no argument, and `^G` in hub mode (pick from your remote repos) | Pass a URL to `rp get` explicitly; `^G` is left out of hub mode |
| [`eza`](https://github.com/eza-community/eza) | Directory preview inside fzf | Falls back to `ls -la`, or whatever [`RP_PREVIEW_CMD`](#configuration) names |
| [`tmux`](https://github.com/tmux/tmux) | `-s` / `-w` outside herdr | Omit `-s` / `-w` |
| [`herdr`](https://herdr.dev) + [`jq`](https://jqlang.github.io/jq/) | `-s` / `-w` inside herdr | Omit `-s` / `-w` |
| `code` / `vim` / `nvim` | `rp open` | `rp open` falls back through the list, after [`$RP_EDITOR`, `$VISUAL` and `$EDITOR`](#configuration) |

</details>

## Installation

Homebrew installs `ghq` and `fzf` too. Every other method installs the shell
code only, so run `brew install ghq fzf` (or your platform's equivalent) first.

```bash
brew install peinan/tap/rp
```

```zsh
# .zshrc
source "$(brew --prefix)/share/rp/rp.plugin.zsh"
```

<details>
<summary>sheldon, zinit / znap / zplug, antidote, Oh My Zsh, manual</summary>

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

**Manual**

```bash
git clone https://github.com/peinan/rp ~/.local/share/rp
```

```zsh
# .zshrc
source ~/.local/share/rp/rp.plugin.zsh
```

</details>

<details>
<summary>Upgrading</summary>

Whatever your installer calls "update":

| Installed with | Upgrade |
| --- | --- |
| Homebrew | `brew update && brew upgrade peinan/tap/rp` |
| sheldon | `sheldon lock --update` |
| zinit | `zinit update peinan/rp` |
| znap | `znap pull` |
| zplug | `zplug update` |
| antidote | `antidote update` |
| Oh My Zsh | `git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/rp" pull` |
| Manual | `git -C ~/.local/share/rp pull` |

Then `exec zsh`. `rp` is autoloaded, so a shell that has already run it holds
the old function body in memory and keeps using it.

</details>

## Usage

**`rp help` is the command reference** — it prints every command, whichever hub
keys are actually bound, and the `RP_*` variables. This table is deliberately
shorter, so there is one full list to keep current rather than two.

| Command | What it does |
| --- | --- |
| `rp`, `rp hub` | Hub mode: pick a repository, then choose an action |
| `rp <query>` | Fuzzy match and `cd` to the best match |
| `rp cd, c [-s\|-w] [query]` | `cd` to a repository |
| `rp path, p [query]` | Print its path instead of `cd`-ing |
| `rp get, g [-s\|-w] [url]` | Clone one (interactive with no URL) |
| `rp create, new, n [-s\|-w]` | Create one and `git init` it under `$(ghq root)` |
| `rp open, o [editor]` | Open one in an editor |
| `rp list, ls` | List repositories |
| `rp remove, rm, r` | Remove one (asks first) |
| `rp --version, -v` | Print the version |

A bare word that is not a subcommand is a fuzzy query, so `rp dot` means
`rp cd dot`.

### Examples

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

### Hub mode

Bare `rp` lists your repositories and then asks what to do with the one you
pick. `enter` does what bare `rp` has always done, so the common path is
unchanged; the other keys reach the rest without a subcommand.

<!-- demo: a GIF of hub mode — pick a repository, then ^O for the action list (#7) -->

| Key | `RP_KEY_*` | Action |
| --- | --- | --- |
| `enter` | — | `cd` to it |
| `^S` | `RP_KEY_SESSION` | Open it as a session (tmux session / herdr workspace) |
| `^T` | `RP_KEY_WINDOW` | Open it in a new window (tmux window / herdr tab) |
| `^O` | `RP_KEY_ACTIONS` | Choose from every action, including `copy path` and `remove` |
| `^R` | `RP_KEY_NEW` | Create the repository named by what you typed |
| `^X` | `RP_KEY_REMOVE` | Delete it (asks first, and refuses anything not cloned) |
| `^G` | `RP_KEY_TOGGLE` | Switch between your local repositories and your GitHub ones |

Anything not cloned yet — anything from `^G`, in practice — is cloned first,
whichever action you chose. Every key but `enter` is a default you can change;
see [Configuration](#configuration).

<details>
<summary>Details worth knowing once you use it</summary>

The `^O` menu is fuzzy-searchable, so `^O` then `ed` reaches "open in editor"
without memorising anything. Its labels name whichever multiplexer `-s` / `-w`
will actually use — "new session" and "new window" under tmux, "new workspace"
and "new tab" inside herdr.

`^R` takes the text you typed as the name, so typing `me/newthing` and pressing
`^R` creates it. Names are checked before anything touches the disk, and the
destination is chosen after, so cancelling leaves nothing behind.

Whatever you bind here replaces fzf's own binding for that key. With the
defaults that happens twice: `^R` replaces `down-match` (arrow keys and
`alt-down` still work), and `^G` replaces one of four `abort` keys (`esc`, `^C`
and `^Q` remain).

</details>

### Multiplexer integration

`-s` and `-w` are a destination rather than part of the operation, so they mean
the same thing on `cd`, `get` and `create`. They pick the multiplexer
automatically: [herdr](https://herdr.dev) when `$HERDR_ENV` is set, otherwise
tmux.

<!-- demo: a GIF of `rp get -w user/repo` — clone straight into a new window / tab (#7) -->

| Flag | tmux | herdr |
| --- | --- | --- |
| `-s`, `--tmux-session` | New session (reuses an existing one by name) | New workspace (reuses by label) |
| `-w`, `--tmux-window` | New window | New tab |

## Configuration

Everything is an environment variable, so `.zshrc` is the only place you need.
**`export` them rather than just setting them**: the herdr popup runs `rp` in a
process the herdr daemon spawned, not in your shell.

`rp open` walks one chain and uses the first command it finds:

```text
rp open <editor>  →  $RP_EDITOR  →  $VISUAL  →  $EDITOR  →  code  →  vim  →  nvim
```

```zsh
export RP_EDITOR="code -n"   # arguments are fine; only the first word is looked up
```

<details>
<summary>Preview — <code>RP_PREVIEW_CMD</code>, <code>RP_PREVIEW_REMOTE_CMD</code>, <code>RP_PREVIEW_WINDOW</code></summary>

| Variable | Default |
| --- | --- |
| `RP_PREVIEW_CMD` | `eza "$RP_ROOT"/{} --color=always`, or `ls -la "$RP_ROOT"/{}` without `eza` |
| `RP_PREVIEW_REMOTE_CMD` | `gh repo view {} …`, for the GitHub listing behind `^G` and `rp get` |
| `RP_PREVIEW_WINDOW` | unset: every picker keeps its own (`down:3:wrap`, `down:5:wrap` for the remote ones) |

fzf runs the template with `$SHELL -c`. `{}` is the selected `host/user/repo`
and `$RP_ROOT` is `$(ghq root)` — quote it, since a path may contain spaces:

```zsh
export RP_PREVIEW_CMD='onefetch "$RP_ROOT"/{} 2>/dev/null || ls -la "$RP_ROOT"/{}'
```

Keep `;;` out of it: hub mode embeds both templates in one `case`, so a `;;`
would close it early.

</details>

<details>
<summary>Hub mode keys — <code>RP_KEY_*</code></summary>

Use fzf's key names — `ctrl-s`, `alt-x`, `f5`, `shift-delete`:

```zsh
export RP_KEY_REMOVE=f12     # park the destructive key out of reach
export RP_KEY_TOGGLE=alt-g
```

- Names are limited to letters, digits and `-`. That covers every `ctrl-`,
  `ctrl-alt-` and `alt-` chord, every function key and every named key; it
  leaves out the punctuation keys, because a key name also becomes footer text.
- `enter` is not configurable, and binding something else to it is an error
  rather than a binding fzf would drop without a word. So is two actions on one
  key.
- Empty means "use the default", not "unbind". `RP_KEY_REMOVE=f12` is how you
  get `^X` out of the way.
- A bare single character (`RP_KEY_NEW=x`) is a valid fzf key but makes the
  filter box unusable: the key fires instead of the character being typed.

`rp` checks these when hub mode starts and names the variable at fault, so a
typo cannot reach fzf. No other subcommand reads them, so a bad `RP_KEY_*`
leaves `rp path` and `rp cd` working.

</details>

## Herdr plugin

Inside [herdr](https://herdr.dev) every repository is one keypress away from any
pane: a popup runs hub mode and opens what you pick as a workspace or a tab. The
plugin ships in this repository (`herdr-plugin.toml`) and needs herdr 0.9.0 or
newer.

```bash
herdr plugin install peinan/rp
```

herdr plugins cannot ship key bindings, so bind the `rp.hub` action yourself and
reload the config. One binding reaches everything, because the keys live inside
the picker rather than in the manifest — adding an operation to `rp` costs no
new action, pane, or key binding.

```toml
# ~/.config/herdr/config.toml
[[keys.command]]
key = "prefix+ctrl+r"
type = "plugin_action"
command = "rp.hub"
description = "jump to a ghq repository"
```

<details>
<summary>What differs from a shell prompt, and what has to be on <code>PATH</code></summary>

A popup does not outlive the picker, so there is nothing to `cd`. `cd here` is
left out of the action menu and `enter` opens a workspace instead.

The plugin runs its own copy of `functions/rp` from the herdr-managed checkout,
so it does not need the zsh plugin installed. `rp cd` and `rp path` stay
zsh-only: a plugin process cannot change your shell's directory. `ghq`, `fzf`,
`git` and `jq` must be on the `PATH` herdr was started with, plus `gh` for `^G`,
and `RP_*` must be in its environment — see [Configuration](#configuration).

To hack on it, link a checkout instead of installing:
`herdr plugin link /path/to/rp`.

</details>

## FAQ

**Why is `rp` a shell function rather than a binary on `PATH`?**
Because `rp cd` has to change the directory of your *current* shell, and a
subprocess cannot `cd` its parent.

**zsh only? What about bash and fish?**
Deliberate, and the `cd` constraint above is not the reason — it applies to
bash and fish equally, and both can define a function. The reason is that
`functions/rp` is a zsh autoload function throughout: zsh parameter expansion
(`${(@f)…}`, `${(qq)…}`, `$+commands[…]`), `local -a` / `local -i`, and helpers
that write into their caller's scope through dynamic scoping. A port is a
rewrite of that plumbing, not a compatibility shim, and fish is further still.
If it happens it will be a shell-agnostic core that prints a decision, leaving
each shell a thin `cd`-only wrapper —
[#10](https://github.com/peinan/rp/issues/10) is where that is discussed.

**I upgraded and nothing changed.**
`rp` is autoloaded, so a shell that has already run it keeps the old function
body in memory. Start a new shell, or `exec zsh`.

## License

[MIT](./LICENSE)
