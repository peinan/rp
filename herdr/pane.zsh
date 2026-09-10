#!/bin/zsh
#
# herdr plugin pane: run rp's hub mode inside the popup herdr opened for it.
#
# herdr sets HERDR_PLUGIN_ROOT and HERDR_ENV=1 for plugin panes, so the autoloaded
# `rp` takes its herdr branch (`herdr workspace create` / `herdr tab create`)
# exactly as it does from a zsh prompt inside herdr. The popup closes when this
# script exits.
#
# Arguments are passed through, so an older binding that still names a pane
# entrypoint (`pane.zsh cd -s`) keeps working; with none, rp enters hub mode.

emulate -L zsh

fpath=("${HERDR_PLUGIN_ROOT:?}/functions" $fpath)
autoload -Uz rp

# This popup does not outlive the picker, so cd-ing it changes nothing the user
# can see. rp drops `cd here` and makes enter open a workspace instead.
# $HERDR_ENV is the wrong signal for this: it is set for every shell inside
# herdr, including a real prompt where `cd here` is exactly what you want.
export RP_NO_CD=1

# rp sizes fzf for inline use at a prompt (--height=~20% / 50%). This popup exists
# only for the picker, so let fzf fill it: fzf honours the last --height it sees.
fzf() { command fzf "$@" --height=100% }

if ! rp "$@"; then
    # Keep the popup open so the error stays readable; herdr closes it on exit.
    print -u2 ""
    read -k1 -s 'reply?Press any key to close'
    exit 1
fi
