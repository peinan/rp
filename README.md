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

```console
$ rp dot            # fuzzy match and cd to the best match
$ rp path dot       # print the path instead of cd-ing
$ rp get -w x/y     # clone and open in a new window
```

## Requirements

**Required**

| Command | Used for |
| --- | --- |
| [`ghq`](https://github.com/x-motemen/ghq) | Locating, cloning and listing repositories |
| [`fzf`](https://github.com/junegunn/fzf) | Interactive selection and fuzzy matching |
| `git` | Initializing repositories created with `rp create` |

`rp` reports which of these are missing on first use instead of failing partway
through a subcommand.

**Optional**

| Command | Needed for | Without it |
| --- | --- | --- |
| [`gh`](https://cli.github.com/) | `rp get` with no argument (pick from your remote repos) | Pass a URL to `rp get` explicitly |
| [`eza`](https://github.com/eza-community/eza) | Directory preview inside fzf | Selection still works; the preview pane shows an error |
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
  list, l                 List repositories with fzf selection
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

Running `rp` with no arguments is the same as `rp cd`. A bare word that is not a
subcommand is treated as a fuzzy query, so `rp dot` means `rp cd dot`.

### Multiplexer integration

`-s` and `-w` pick the multiplexer automatically: [herdr](https://herdr.dev) when
`$HERDR_ENV` is set, otherwise tmux.

| Flag | tmux | herdr |
| --- | --- | --- |
| `-s`, `--tmux-session` | New session (reuses an existing one by name) | New workspace (reuses by label) |
| `-w`, `--tmux-window` | New window | New tab |

### Examples

```bash
rp                              # pick a repository and cd into it
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
