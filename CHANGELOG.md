# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `rp --version` / `rp -v` prints the version. It is carried in the function as
  `RP_VERSION`, so it is right for every install path, and it prints without
  `ghq`, `fzf` or `git` — a diagnostic has to work on the machine that is
  missing something. (#16)
- `RP_EDITOR`, `RP_PREVIEW_CMD`, `RP_PREVIEW_REMOTE_CMD`, `RP_PREVIEW_WINDOW`
  and `RP_KEY_SESSION` / `RP_KEY_WINDOW` / `RP_KEY_ACTIONS` / `RP_KEY_NEW` /
  `RP_KEY_REMOVE` / `RP_KEY_TOGGLE` make the editor, the fzf previews and every
  hub key but `enter` configurable. `RP_KEY_*` is validated when hub mode
  starts, naming the variable at fault, so a typo cannot reach fzf and cannot
  break `rp path` in a script. (#17, closes #5)
- Hub mode fails with a clear message when the `fzf` it finds is older than
  0.63.0. Hub mode uses `--footer`, and fzf treats an unknown option as a hard
  error, so on an older fzf every bare `rp` died with `unknown option:
  --footer` on stderr — which reads as "rp does nothing". Only hub mode checks
  the floor; the subcommands pass nothing newer and stay usable on an old fzf.
  (#16, closes #6)

### Changed

- **`rp open` now honours `$VISUAL` and `$EDITOR`.** It walks
  `rp open <editor>` → `$RP_EDITOR` → `$VISUAL` → `$EDITOR` → `code` → `vim` →
  `nvim` and uses the first one found on `PATH`, where it used to go straight
  to `code`. So if you have `EDITOR=vim` set and no `RP_EDITOR`, `rp open` now
  opens vim where it previously opened `code`. (#17)

### Fixed

- `rp` runs under zsh's own options rather than inheriting the caller's. Under
  `ksh_arrays` it failed with `rp:41: bad output format specification` instead
  of its own messages: the required-command check could not report which
  dependency was missing, `rp help` printed an empty key label, and `rp cd` did
  not `cd`. (#20, closes #19)
- The preview pane falls back to `ls -la` without `eza` in the five non-hub
  pickers too, and quotes `$(ghq root)`. They hardcoded `eza`, so the
  documented fallback only ever applied to hub mode and the pane printed
  `command not found` everywhere else. (#17)

### Docs

- The README was restructured so what `rp` does comes before how to install it,
  and it now answers "why not zoxide, or `ghq list | fzf`?" and states the
  zsh-only stance. (#9, #10, #14)

## [0.3.0] - 2026-09-11

### Added

- `rp` ships as a herdr plugin (`herdr-plugin.toml`), so every repository is one
  keypress away from any pane: a popup runs hub mode and opens what you pick as
  a workspace or a tab. Install it with `herdr plugin install peinan/rp`. herdr
  plugins cannot ship key bindings, so bind the `rp.hub` action yourself in
  `~/.config/herdr/config.toml`. Requires herdr 0.9.0 or newer, with `ghq`,
  `fzf`, `git` and `jq` on the `PATH` herdr was started with, plus `gh` for
  `^G`. The Homebrew formula still installs the zsh plugin only; both resolve
  to this tag.
- One action reaches everything, because hub mode keeps its keys inside the
  picker rather than in the manifest. The one difference from a prompt: a popup
  does not outlive the picker, so there is nothing to `cd` — `cd here` is left
  out of the action menu and `enter` opens a workspace instead, with the footer
  saying so.

### Fixed

- `-s` / `-w` inside herdr propagate a failed `herdr workspace focus` /
  `workspace create` / `tab create` instead of reporting success.

### Removed

- The six per-operation herdr actions from the plugin pre-release
  (`rp.cd-workspace`, `rp.cd-tab`, `rp.get-workspace`, `rp.get-tab`,
  `rp.create-workspace`, `rp.create-tab`), replaced by the single `rp.hub`.
  Existing bindings need the new name.

## [0.2.1] - 2026-09-11

### Changed

- The `list` alias is now `ls`, not `l`. `l` is gone rather than kept
  alongside, so `rp l` is a bare word like any other: a fuzzy `cd` query. This
  is the only behavioural change in the release.
- The hub is called *hub mode* throughout the help and the README.
- Help no longer lists `hub` as if it were a command you had to type. The row
  leads with the empty invocation and names `hub` as the other spelling, the
  way every other row lists its aliases.
- Hub mode's footer keys are coloured — keys bold green, labels dim, in the
  picker and the `^O` menu alike. They were one flat colour, so there was
  nothing for the eye to land on.

### Docs

- The README documents how to upgrade, one row per installer; it covered eight
  ways to install and none to update. It also notes why a running shell keeps
  the old behaviour until you `exec zsh`: `rp` is autoloaded, so the function
  body is already in memory.

## [0.2.0] - 2026-09-11

### Added

- Bare `rp` is now a hub: it lists your repositories first and then asks what
  to do with the one you pick, instead of requiring the operation up front.
  `enter` does what bare `rp` has always done, so the common path is unchanged;
  `^S` opens a session, `^T` a new window, `^O` the full action list (including
  `copy path` and `remove`), `^R` creates the repository named by what you
  typed, `^X` deletes it after asking, and `^G` switches between your local
  repositories and your GitHub ones.
- Picking something that is not cloned yet — anything from `^G` — clones it
  first, whichever action you chose. The `^O` menu is fuzzy-searchable, and its
  labels name whichever multiplexer `-s` / `-w` will actually use.

### Changed

- fzf 0.63.0 or newer is now required, for `--footer`.
- `create` prints "Created and initialized" before it `cd`s.

### Fixed

- `-s` / `-w` fail with a clear message when `tmux`, or `herdr` plus `jq`, is
  missing. `rp cd -s` without tmux failed obscurely, and a missing `jq` was
  swallowed and then created a duplicate workspace.
- The fzf preview falls back to `ls -la` when `eza` is absent, instead of
  showing an error.
- `get` without `-s` / `-w` propagates a failed `cd`.

## [0.1.0] - 2026-09-09

Initial public release. Earlier commits in the history are the same function
under its previous name, `repo`.

### Added

- `rp <command>` wraps `ghq` and `fzf` into one entry point for everything you
  do with a local clone: `list`, `cd`, `path`, `remove`, `get`, `create`,
  `open` and `help`, each with short aliases. Bare `rp` selects a repository
  with fzf and `cd`s to it.
- A bare word that is not a subcommand is treated as a fuzzy query, so `rp dot`
  means `rp cd dot`. `rp path` prints the path instead of `cd`-ing, which makes
  it usable in command substitution.
- `-s` / `--tmux-session` and `-w` / `--tmux-window` on `cd`, `get` and
  `create` open the repository in a new session or window. They pick the
  multiplexer automatically: herdr when `$HERDR_ENV` is set, otherwise tmux.
- Short repository paths are expanded, so `user/repo` means
  `github.com/user/repo`.
- `rp` reports which of `ghq`, `fzf` and `git` are missing on first use,
  instead of failing partway through a subcommand.
- `rp.plugin.zsh`, an entry point for zsh plugin managers.
- README and LICENSE (MIT).

[Unreleased]: https://github.com/peinan/rp/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/peinan/rp/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/peinan/rp/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/peinan/rp/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/peinan/rp/releases/tag/v0.1.0
