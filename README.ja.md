<div align="center">

[English](README.md) ・ 日本語 ・ [简体中文](README.zh-CN.md)

# rp

**手を止めずに、リポジトリへ移動し、クローンし、作成し、開く。**

<!-- demo: a GIF of hub mode goes here (#7) -->

</div>

[ghq](https://github.com/x-motemen/ghq) と [fzf](https://github.com/junegunn/fzf) の上に置いた zsh 関数です。
リポジトリを選んでから何をするかを決めても、先に動作を指定してもかまいません。
どちらの順序でも、ピッカーはひとつです。

```console
$ rp                # pick a repository, then choose an action
$ rp dot            # fuzzy match "dot" and cd there
$ rp get -w x/y     # clone it and open a new window
$ rp path dot       # print the path instead
```

## なぜ rp か

- **`cd` だけではない**：クローン、新規作成、エディタで開く、パスのコピー、削除。結果の送り先も、現在のシェルだけでなく、tmux のセッションやウィンドウ、herdr のワークスペースやタブを選べます
- **ghq ネイティブ**：`ghq list` が唯一の情報源なので、たどり着ける先はクローン済みのものとちょうど一致します。温める必要のある frecency データベースもインポート作業もなく、新しいマシンでも `ghq get` を一度実行した時点で動きます
- **どちらの順序でも**：目的が決まっているなら `rp cd -s foo`、先に選んでからどうするか決めたいなら引数なしの `rp`

zoxide が答えるのは「どこに行ったことがあるか」、`rp` が答えるのは「何をクローンしてあるか」です。
両方を使うのは理にかなっています。
`ghq list | fzf` のシェル関数は `cd` のケースをカバーしますし、その用途ではよくできています。
けれども「これをクローンして新しいワークスペースで開きたい」と思った時点で、操作 × 送り先のマトリクスを自分で書くことになります。
そのマトリクスが `rp` です。

## 必要なもの

[`ghq`](https://github.com/x-motemen/ghq)、**0.63.0 以上**の [`fzf`](https://github.com/junegunn/fzf)（ハブモードが `--footer` を使うため。サブコマンドは古いバージョンでも動きます）、そして `git` です。
`rp` は、サブコマンドの途中で失敗するのではなく、最初に使ったときに足りないコマンドを報告します。

**あえて zsh 専用にしています**。
[よくある質問](#よくある質問)を参照してください。

<details>
<summary>任意のコマンドと、ない場合に失われるもの</summary>

| コマンド | 必要な場面 | ない場合 |
| --- | --- | --- |
| [`gh`](https://cli.github.com/) | 引数なしの `rp get` と、ハブモードの `^G`（リモートのリポジトリから選ぶ） | `rp get` に URL を明示的に渡します。`^G` はハブモードから外れます |
| [`eza`](https://github.com/eza-community/eza) | fzf の中でのディレクトリプレビュー | `ls -la`、または [`RP_PREVIEW_CMD`](#設定) が指定したコマンドにフォールバックします |
| [`tmux`](https://github.com/tmux/tmux) | herdr の外での `-s` / `-w` | `-s` / `-w` を使いません |
| [`herdr`](https://herdr.dev) + [`jq`](https://jqlang.github.io/jq/) | herdr の中での `-s` / `-w` | `-s` / `-w` を使いません |
| `code` / `vim` / `nvim` | `rp open` | `rp open` は [`$RP_EDITOR`、`$VISUAL`、`$EDITOR`](#設定) のあと、この一覧を順にたどります |

</details>

## インストール

Homebrew でインストールすると `ghq` と `fzf` も一緒に入ります。
ほかの方法はシェルのコードだけをインストールするので、先に `brew install ghq fzf`（または各プラットフォームの同等のコマンド）を実行してください。

```bash
brew install peinan/tap/rp
```

```zsh
# .zshrc
source "$(brew --prefix)/share/rp/rp.plugin.zsh"
```

<details>
<summary>sheldon、zinit / znap / zplug、antidote、Oh My Zsh、手動</summary>

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

**手動**

```bash
git clone https://github.com/peinan/rp ~/.local/share/rp
```

```zsh
# .zshrc
source ~/.local/share/rp/rp.plugin.zsh
```

</details>

<details>
<summary>アップグレード</summary>

使っているインストーラが「update」と呼んでいるコマンドを実行します。

| インストール方法 | アップグレード |
| --- | --- |
| Homebrew | `brew update && brew upgrade peinan/tap/rp` |
| sheldon | `sheldon lock --update` |
| zinit | `zinit update peinan/rp` |
| znap | `znap pull` |
| zplug | `zplug update` |
| antidote | `antidote update` |
| Oh My Zsh | `git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/rp" pull` |
| 手動 | `git -C ~/.local/share/rp pull` |

そのあと `exec zsh` を実行してください。
`rp` は autoload されるため、すでに一度実行したシェルは古い関数本体をメモリに保持したまま使い続けます。

</details>

## 使い方

**コマンドリファレンスは `rp help` です**。
すべてのコマンド、実際に割り当てられているハブのキー、`RP_*` 変数を出力します。
下の表は意図的に短くしてあります。
最新に保つべき完全な一覧を、二つではなく一つにするためです。

| コマンド | 動作 |
| --- | --- |
| `rp`, `rp hub` | ハブモード。リポジトリを選び、それから動作を選ぶ |
| `rp <query>` | あいまい一致で、最も近いリポジトリに `cd` する |
| `rp cd, c [-s\|-w] [query]` | リポジトリに `cd` する |
| `rp path, p [query]` | `cd` せずにパスを出力する |
| `rp get, g [-s\|-w] [url]` | クローンする（URL なしなら対話的に選ぶ） |
| `rp create, new, n [-s\|-w]` | `$(ghq root)` 以下に作成して `git init` する |
| `rp open, o [editor]` | エディタで開く |
| `rp list, ls` | リポジトリを一覧表示する |
| `rp remove, rm, r` | 削除する（先に確認する） |
| `rp --version, -v` | バージョンを出力する |

サブコマンドでない裸の語はあいまい検索のクエリとして扱われるので、`rp dot` は `rp cd dot` を意味します。

### 例

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

### ハブモード

引数なしの `rp` はリポジトリを一覧表示し、選んだものをどうするかを尋ねます。
`enter` は引数なしの `rp` が従来やってきたことをそのまま行うので、いつもの経路は変わりません。
ほかのキーは、サブコマンドを打たずに残りの操作へ届きます。

<!-- demo: a GIF of hub mode — pick a repository, then ^O for the action list (#7) -->

| キー | `RP_KEY_*` | 動作 |
| --- | --- | --- |
| `enter` | — | そこに `cd` する |
| `^S` | `RP_KEY_SESSION` | セッションとして開く（tmux のセッション / herdr のワークスペース） |
| `^T` | `RP_KEY_WINDOW` | 新しいウィンドウで開く（tmux のウィンドウ / herdr のタブ） |
| `^O` | `RP_KEY_ACTIONS` | `copy path` や `remove` を含む、すべての動作から選ぶ |
| `^R` | `RP_KEY_NEW` | 入力した文字列を名前としてリポジトリを作成する |
| `^X` | `RP_KEY_REMOVE` | 削除する（先に確認し、クローンしていないものは拒否する） |
| `^G` | `RP_KEY_TOGGLE` | ローカルのリポジトリと GitHub のリポジトリを切り替える |

まだクローンしていないもの（実際には `^G` から来たもの）は、選んだ動作が何であれ先にクローンします。
`enter` 以外のキーはすべて、変更できるデフォルトです（[設定](#設定)を参照）。

<details>
<summary>使い始めてから効いてくる細かい話</summary>

`^O` のメニューはあいまい検索できるので、`^O` のあと `ed` と打てば、何も覚えていなくても「open in editor」に届きます。
そのラベルは、`-s` / `-w` が実際に使うマルチプレクサの呼び方になります。
tmux なら「new session」と「new window」、herdr の中なら「new workspace」と「new tab」です。

`^R` は入力したテキストを名前として受け取るので、`me/newthing` と打って `^R` を押せば作成されます。
名前の検証はディスクに触れる前に行い、送り先はそのあとに選ぶので、キャンセルしても何も残りません。

ここで割り当てたキーは、fzf 自身のそのキーへの割り当てを置き換えます。
デフォルトでは、それが二回起こります。
`^R` は `down-match` を置き換え（矢印キーと `alt-down` は使えます）、`^G` は四つある `abort` キーのうち一つを置き換えます（`esc`、`^C`、`^Q` は残ります）。

</details>

### マルチプレクサ連携

`-s` と `-w` は操作の一部ではなく送り先なので、`cd` でも `get` でも `create` でも同じ意味になります。
マルチプレクサは自動で選びます。
`$HERDR_ENV` が設定されていれば [herdr](https://herdr.dev)、そうでなければ tmux です。

<!-- demo: a GIF of `rp get -w user/repo` — clone straight into a new window / tab (#7) -->

| フラグ | tmux | herdr |
| --- | --- | --- |
| `-s`, `--tmux-session` | 新しいセッション（同名のものがあれば再利用） | 新しいワークスペース（ラベルで再利用） |
| `-w`, `--tmux-window` | 新しいウィンドウ | 新しいタブ |

## 設定

設定はすべて環境変数なので、書く場所は `.zshrc` だけです。
**代入するだけでなく `export` してください**。
herdr のポップアップは、シェルではなく herdr デーモンが起動したプロセスで `rp` を実行するからです。

`rp open` は一本の連鎖をたどり、最初に見つかったコマンドを使います。

```text
rp open <editor>  →  $RP_EDITOR  →  $VISUAL  →  $EDITOR  →  code  →  vim  →  nvim
```

```zsh
export RP_EDITOR="code -n"   # arguments are fine; only the first word is looked up
```

<details>
<summary>プレビュー：<code>RP_PREVIEW_CMD</code>、<code>RP_PREVIEW_REMOTE_CMD</code>、<code>RP_PREVIEW_WINDOW</code></summary>

| 変数 | デフォルト |
| --- | --- |
| `RP_PREVIEW_CMD` | `eza "$RP_ROOT"/{} --color=always`。`eza` がなければ `ls -la "$RP_ROOT"/{}` |
| `RP_PREVIEW_REMOTE_CMD` | `gh repo view {} …`。`^G` と `rp get` の先にある GitHub の一覧で使う |
| `RP_PREVIEW_WINDOW` | 未設定。各ピッカーが自前の値を保つ（`down:3:wrap`、リモートのものは `down:5:wrap`） |

fzf はテンプレートを `$SHELL -c` で実行します。
`{}` は選択中の `host/user/repo`、`$RP_ROOT` は `$(ghq root)` です。
パスに空白が含まれることがあるので、クォートしてください。

```zsh
export RP_PREVIEW_CMD='onefetch "$RP_ROOT"/{} 2>/dev/null || ls -la "$RP_ROOT"/{}'
```

`;;` は書かないでください。
ハブモードは両方のテンプレートをひとつの `case` に埋め込むので、`;;` があるとそこで `case` が閉じてしまいます。

</details>

<details>
<summary>ハブモードのキー：<code>RP_KEY_*</code></summary>

fzf のキー名を使います（`ctrl-s`、`alt-x`、`f5`、`shift-delete` など）。

```zsh
export RP_KEY_REMOVE=f12     # park the destructive key out of reach
export RP_KEY_TOGGLE=alt-g
```

- 名前に使えるのは英字、数字、`-` だけです。これで `ctrl-`、`ctrl-alt-`、`alt-` のすべての組み合わせ、すべてのファンクションキー、すべての名前付きキーをカバーできます。記号のキーが外れるのは、キー名がフッターのテキストにもなるためです
- `enter` は変更できません。ほかの動作を `enter` に割り当てるのは、fzf が黙って捨てる割り当てではなくエラーです。ひとつのキーに二つの動作を割り当てた場合も同じです
- 空の値は「デフォルトを使う」であって「割り当てを外す」ではありません。`^X` をどかすには `RP_KEY_REMOVE=f12` とします
- 単独の一文字（`RP_KEY_NEW=x`）は fzf のキーとしては有効ですが、フィルタ入力欄が使えなくなります。文字が入力される代わりに、キーが発火するためです

`rp` はハブモードの起動時にこれらを検証し、問題のある変数の名前を示すので、打ち間違いが fzf まで届くことはありません。
ほかのサブコマンドはこれらを読まないので、`RP_KEY_*` が壊れていても `rp path` と `rp cd` は動いたままです。

</details>

## herdr プラグイン

[herdr](https://herdr.dev) の中では、どのペインからもキーひとつですべてのリポジトリに届きます。
ポップアップでハブモードが動き、選んだものをワークスペースかタブとして開きます。
プラグインはこのリポジトリに同梱されていて（`herdr-plugin.toml`）、herdr 0.9.0 以降が必要です。

```bash
herdr plugin install peinan/rp
```

herdr のプラグインはキーバインドを同梱できないので、`rp.hub` アクションを自分で割り当てて設定を再読み込みしてください。
キーはマニフェストではなくピッカーの中にあるので、ひとつの割り当てですべてに届きます。
`rp` に操作を足しても、新しいアクションもペインもキーバインドも増えません。

```toml
# ~/.config/herdr/config.toml
[[keys.command]]
key = "prefix+ctrl+r"
type = "plugin_action"
command = "rp.hub"
description = "jump to a ghq repository"
```

<details>
<summary>シェルのプロンプトとの違いと、<code>PATH</code> に必要なもの</summary>

ポップアップはピッカーより長くは生きないので、`cd` する先がありません。
`cd here` は動作メニューから省かれ、`enter` は代わりにワークスペースを開きます。

プラグインは herdr が管理するチェックアウトから `functions/rp` の自前のコピーを実行するので、zsh プラグインがインストールされている必要はありません。
`rp cd` と `rp path` は zsh 専用のままです。
プラグインのプロセスは、シェルのディレクトリを変えられないからです。
`ghq`、`fzf`、`git`、`jq` は herdr を起動したときの `PATH` 上になければならず、`^G` を使うなら `gh` も必要です。
`RP_*` も herdr の環境に入れておく必要があります（[設定](#設定)を参照）。

手を入れるときは、インストールする代わりにチェックアウトをリンクします（`herdr plugin link /path/to/rp`）。

</details>

## よくある質問

**なぜ `rp` は `PATH` 上のバイナリではなくシェル関数なのか？**
`rp cd` が変えるのは、ほかでもない現在のシェルのディレクトリであり、子プロセスは親を `cd` できないからです。

**zsh 専用なのか？ bash と fish はどうなのか？**
あえてそうしていて、理由は上の `cd` の制約ではありません。
あの制約は bash にも fish にも等しく当てはまりますし、どちらも関数を定義できます。
理由は、`functions/rp` が全体として zsh の autoload 関数として書かれていることです。
zsh のパラメータ展開（`${(@f)…}`、`${(qq)…}`、`$+commands[…]`）、`local -a` / `local -i`、動的スコープで呼び出し元のスコープに書き込むヘルパーを使っています。
移植は互換シムではなく、この配管の書き直しになります。
fish はさらに遠いところにあります。
やるとすれば、判断結果を出力するシェル非依存のコアを用意し、各シェルには `cd` だけの薄いラッパーを残す形になります。
その議論は [#10](https://github.com/peinan/rp/issues/10) でしています。

**アップグレードしたのに何も変わらない**
`rp` は autoload されるため、すでに一度実行したシェルは古い関数本体をメモリに保持したままです。
新しいシェルを起動するか、`exec zsh` を実行してください。

## ライセンス

[MIT](./LICENSE)
