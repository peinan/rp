<div align="center">

# rp

Jump between your [ghq](https://github.com/x-motemen/ghq)-managed repositories with [fzf](https://github.com/junegunn/fzf).

</div>

`rp` is a zsh function that wraps `ghq` and `fzf` into a single entry point for
everything you do with a local clone: switching to it, printing its path,
cloning a new one, creating one, opening it in an editor, or removing it.

Because `rp cd` has to change the directory of your *current* shell, `rp` is a
shell function rather than an executable on `PATH` — a subprocess cannot `cd`
its parent.

It works in both directions. Name the action first and then pick the repository,
or run bare `rp` — hub mode — to pick the repository first and then choose what
to do with it.

```console
$ rp                # hub mode: pick a repository, then choose an action
$ rp dot            # fuzzy match and cd to the best match
$ rp path dot       # print the path instead of cd-ing
$ rp get -w x/y     # clone and open in a new window
```

## Requirements

**Required**

| Command | Used for |
| --- | --- |
| [`ghq`](https://github.com/x-motemen/ghq) | Locating, cloning and listing repositories |
| [`fzf`](https://github.com/junegunn/fzf) **0.63.0+** | Interactive selection and fuzzy matching |
| `git` | Initializing repositories created with `rp create` |

`rp` reports which of these are missing on first use instead of failing partway
through a subcommand.

**Optional**

| Command | Needed for | Without it |
| --- | --- | --- |
| [`gh`](https://cli.github.com/) | `rp get` with no argument, and `^G` in hub mode (pick from your remote repos) | Pass a URL to `rp get` explicitly; `^G` is left out of hub mode |
| [`eza`](https://github.com/eza-community/eza) | Directory preview inside fzf | Falls back to `ls -la`, or whatever [`RP_PREVIEW_CMD`](#configuration) names |
| [`tmux`](https://github.com/tmux/tmux) | `-s` / `-w` outside herdr | Omit `-s` / `-w` |
| [`herdr`](https://herdr.dev) + [`jq`](https://jqlang.github.io/jq/) | `-s` / `-w` inside herdr | Omit `-s` / `-w` |
| `code` / `vim` / `nvim` | `rp open` | `rp open` falls back through the list, after [`$RP_EDITOR`, `$VISUAL` and `$EDITOR`](#configuration) |

## Installation

Installing via Homebrew also installs `ghq` and `fzf`. Every other method
installs the shell code only, so run `brew install ghq fzf` (or your platform's
equivalent) yourself first.

### Homebrew

```bash
brew install peinan/tap/rp
```

Then add to your `.zshrc`:

```zsh
source "$(brew --prefix)/share/rp/rp.plugin.zsh"
```

### sheldon

```toml
[plugins.rp]
github = "peinan/rp"
```

### zinit / znap / zplug

```zsh
zinit light peinan/rp
znap source peinan/rp
zplug "peinan/rp"
```

### antidote

```text
# ~/.zsh_plugins.txt
peinan/rp
```

### Oh My Zsh

```bash
git clone https://github.com/peinan/rp \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/rp"
```

```zsh
# .zshrc
plugins=(... rp)
```

### Manual

```bash
git clone https://github.com/peinan/rp ~/.local/share/rp
```

```zsh
# .zshrc
source ~/.local/share/rp/rp.plugin.zsh
```

## Upgrading

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

Then start a new shell, or `exec zsh`. `rp` is autoloaded, so a shell that has
already run it holds the old function body in memory and keeps using it.

## Usage

```text
Usage: rp <command> [args]

Commands:
  (no command), hub       Hub mode: pick a repository first, then choose an action
  list, ls                List repositories with fzf selection
  cd, c [-s|-w] [query]   Change directory to selected repository
                          If query is given, fuzzy match and cd to best match
                          Use -s, --tmux-session to open a session (tmux session / herdr workspace)
                          Use -w, --tmux-window to open in a new window (tmux window / herdr tab)
  path, p [query]         Print path of selected repository (no cd)
                          If query is given, fuzzy match and print best match
  remove, rm, r           Remove selected repository (with confirmation)
  get, g [-s|-w] [url]    Clone repository (interactive if no url)
  create, new, n [-s|-w]  Create and initialize a new repository
  open, o [editor]        Open repository in editor (default: code)
  help, h                 Show this help message
```

A bare word that is not a subcommand is treated as a fuzzy query, so `rp dot`
means `rp cd dot`.

### Hub mode

Running `rp` with no arguments puts you in hub mode: it lists your repositories
and then asks what to do with the one you pick. `enter` does what bare `rp` has
always done, so the common path is unchanged; the other keys reach the rest
without needing a subcommand. `rp hub` is the same thing, spelled out.

Every key but `enter` is a default you can change — see
[Configuration](#configuration). `rp help` prints whichever keys are actually
bound.

| Key | `RP_KEY_*` | Action |
| --- | --- | --- |
| `enter` | — | `cd` to it |
| `^S` | `RP_KEY_SESSION` | Open it as a session (tmux session / herdr workspace) |
| `^T` | `RP_KEY_WINDOW` | Open it in a new window (tmux window / herdr tab) |
| `^O` | `RP_KEY_ACTIONS` | Choose from every action, including `copy path` and `remove` |
| `^R` | `RP_KEY_NEW` | Create the repository named by what you typed |
| `^X` | `RP_KEY_REMOVE` | Delete it (asks first, and refuses anything not cloned) |
| `^G` | `RP_KEY_TOGGLE` | Switch between your local repositories and your GitHub ones |

Picking something that is not cloned yet — anything from `^G`, in practice —
clones it first, whichever action you chose. The action menu behind `^O` is
fuzzy-searchable, so `^O` then `ed` reaches "open in editor" without memorising
anything. Its labels name whichever multiplexer `-s` / `-w` will actually use —
"new session" and "new window" under tmux, "new workspace" and "new tab" inside
herdr.

`^R` takes the text you typed as the name, so typing `me/newthing` and pressing
`^R` creates it. Names are checked before anything touches the disk, and the
destination is chosen after, so cancelling leaves nothing behind.

Whatever you bind here replaces fzf's own binding for that key. With the
defaults that happens twice: `^R` replaces `down-match` (arrow keys and
`alt-down` still work), and `^G` replaces one of four `abort` keys (`esc`, `^C`
and `^Q` remain).

### Multiplexer integration

`-s` and `-w` pick the multiplexer automatically: [herdr](https://herdr.dev) when
`$HERDR_ENV` is set, otherwise tmux.

| Flag | tmux | herdr |
| --- | --- | --- |
| `-s`, `--tmux-session` | New session (reuses an existing one by name) | New workspace (reuses by label) |
| `-w`, `--tmux-window` | New window | New tab |

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

## Configuration

Everything is an environment variable, so `.zshrc` is the only place you need.
**`export` them rather than just setting them**: the herdr popup runs `rp` in a
process the herdr daemon spawned, not in your shell, so a plain assignment
reaches your prompt but not the popup — and an `export` only reaches herdr if
herdr was started after it.

### Editor

`rp open` walks one chain and uses the first command it finds:

```text
rp open <editor>  →  $RP_EDITOR  →  $VISUAL  →  $EDITOR  →  code  →  vim  →  nvim
```

```zsh
export RP_EDITOR="code -n"   # arguments are fine; only the first word is looked up
```

A value may be an absolute path, and a stale one does not dead-end the chain —
`rp` moves on to the next candidate.

### Preview

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

### Hub mode keys

Use fzf's key names — `ctrl-s`, `alt-x`, `f5`, `shift-delete`:

```zsh
export RP_KEY_REMOVE=f12     # park the destructive key out of reach
export RP_KEY_TOGGLE=alt-g
```

- Names are limited to letters, digits and `-`. That covers every `ctrl-`,
  `ctrl-alt-` and `alt-` chord, every function key and every named key; it
  leaves out the punctuation keys, because a key name also becomes footer text.
- `enter` is not configurable, and binding something else to it is an error
  rather than a binding fzf would drop without a word.
- So is two actions on one key, for the same reason.
- Empty means "use the default", not "unbind" — there is no way to remove a
  key. `RP_KEY_REMOVE=f12` is how you get `^X` out of the way.
- A bare single character (`RP_KEY_NEW=x`) is a valid fzf key but makes the
  filter box unusable: the key fires instead of the character being typed.

`rp` checks these when hub mode starts and names the variable at fault, so a
typo cannot reach fzf. No other subcommand reads them, so a bad `RP_KEY_*`
leaves `rp path` and `rp cd` working.

## Herdr plugin

Inside [herdr](https://herdr.dev) every repository is one keypress away from any
pane: a popup runs hub mode and opens what you pick as a workspace or a tab. The
plugin ships in this repository (`herdr-plugin.toml`) and needs herdr 0.9.0 or
newer.

```bash
herdr plugin install peinan/rp
```

herdr plugins cannot ship key bindings, so bind the action in
`~/.config/herdr/config.toml` and reload the config:

```toml
[[keys.command]]
key = "prefix+ctrl+r"
type = "plugin_action"
command = "rp.hub"
description = "jump to a ghq repository"
```

| Action | What it does |
| --- | --- |
| `rp.hub` | Opens hub mode in a popup: pick a repository, then choose what to do with it |

One binding reaches everything, because the keys live inside the picker rather
than in the manifest — with the defaults, `enter` opens a workspace, `^T` a tab,
`^O` the full action list, `^R` creates, `^X` deletes, `^G` switches to your
GitHub repositories. See [Hub mode](#hub-mode). Adding an operation to `rp`
costs no new action, pane, or key binding.

The one difference from a prompt: a popup does not outlive the picker, so there
is nothing to `cd`. `cd here` is left out and `enter` opens a workspace instead.

The plugin runs its own copy of `functions/rp` from the herdr-managed checkout, so
it does not need the zsh plugin to be installed. `rp cd` and `rp path` stay
zsh-only: a plugin process cannot change your shell's directory. `ghq`, `fzf`,
`git` and `jq` must be on the `PATH` herdr was started with, plus `gh` for `^G`.
`RP_*` must be in its environment too — see
[Configuration](#configuration).

To hack on it, link a checkout instead of installing: `herdr plugin link /path/to/rp`.

## License

[MIT](./LICENSE)
