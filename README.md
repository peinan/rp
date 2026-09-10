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
or run bare `rp` to pick the repository first and then choose what to do with it.

```console
$ rp                # pick a repository, then choose an action
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
| [`gh`](https://cli.github.com/) | `rp get` with no argument, and `^G` in the hub (pick from your remote repos) | Pass a URL to `rp get` explicitly; `^G` is left out of the hub |
| [`eza`](https://github.com/eza-community/eza) | Directory preview inside fzf | Falls back to `ls -la` |
| [`tmux`](https://github.com/tmux/tmux) | `-s` / `-w` outside herdr | Omit `-s` / `-w` |
| [`herdr`](https://herdr.dev) + [`jq`](https://jqlang.github.io/jq/) | `-s` / `-w` inside herdr | Omit `-s` / `-w` |
| `code` / `vim` / `nvim` | `rp open` | `rp open` falls back through the list |

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

## Usage

```text
Usage: rp <command> [args]

Commands:
  hub                     Pick a repository first, then choose an action (default)
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

### The hub

Running `rp` with no arguments lists your repositories and then asks what to do
with the one you pick. `enter` does what bare `rp` has always done, so the common
path is unchanged; the other keys reach the rest without needing a subcommand.

| Key | Action |
| --- | --- |
| `enter` | `cd` to it |
| `^S` | Open it as a session (tmux session / herdr workspace) |
| `^T` | Open it in a new window (tmux window / herdr tab) |
| `^O` | Choose from every action, including `copy path` and `remove` |
| `^R` | Create the repository named by what you typed |
| `^X` | Delete it (asks first, and refuses anything not cloned) |
| `^G` | Switch between your local repositories and your GitHub ones |

Picking something that is not cloned yet — anything from `^G`, in practice —
clones it first, whichever action you chose. The action menu behind `^O` is
fuzzy-searchable, so `^O` then `ed` reaches "open in editor" without memorising
anything. Its labels name whichever multiplexer `-s` / `-w` will actually use —
"new session" and "new window" under tmux, "new workspace" and "new tab" inside
herdr.

`^R` takes the text you typed as the name, so typing `me/newthing` and pressing
`^R` creates it. Names are checked before anything touches the disk, and the
destination is chosen after, so cancelling leaves nothing behind.

Two of these override an fzf default: `^R` replaces `down-match` (arrow keys and
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
rp                              # pick a repository, then choose an action
rp dot                          # fuzzy match "dot" and cd to the best match
rp cd -s dot                    # same, but in a new session / workspace
cd "$(rp path dot)"             # use the path in command substitution
rp get github.com/user/repo     # clone by URL
rp get -w user/repo             # clone and open in a new window / tab
rp create user/new-repo         # mkdir + git init under $(ghq root)
rp open nvim                    # pick a repository and open it in neovim
rp remove                       # pick a repository and delete it (asks first)
```

## License

[MIT](./LICENSE)
