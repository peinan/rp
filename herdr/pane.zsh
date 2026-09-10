#!/bin/zsh
#
# herdr plugin pane: run one rp invocation inside the popup herdr opened for it.
#
#   pane.zsh cd -s | cd -w | get -s | get -w | create -s | create -w
#
# herdr sets HERDR_PLUGIN_ROOT and HERDR_ENV=1 for plugin panes, so the autoloaded
# `rp` takes its herdr branch (`herdr workspace create` / `herdr tab create`)
# exactly as it does from a zsh prompt inside herdr. The popup closes when this
# script exits.

emulate -L zsh

fpath=("${HERDR_PLUGIN_ROOT:?}/functions" $fpath)
autoload -Uz rp

# rp sizes fzf for inline use at a prompt (--height=~20% / 50%). This popup exists
# only for the picker, so let fzf fill it: fzf honours the last --height it sees.
fzf() { command fzf "$@" --height=100% }

typeset -a args=("$@")
if [[ "${1:-}" == "create" ]]; then
    # `rp create` needs a repository path; the popup is the dialog that asks for it.
    typeset name=""
    read -r 'name?Repository (user/repo): ' || exit 0
    [[ -n "$name" ]] || exit 0
    args+=("$name")
fi

if ! rp "${args[@]}"; then
    # Keep the popup open so the error stays readable; herdr closes it on exit.
    print -u2 ""
    read -k1 -s 'reply?Press any key to close'
    exit 1
fi
