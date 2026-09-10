#!/bin/zsh
#
# herdr plugin action: open the pane entrypoint named by $1.
#
# Actions run without a TTY (stdout/stderr are piped into the plugin log), so the
# interactive work lives in herdr/pane.zsh; this only asks herdr to open that pane.
# herdr sets HERDR_BIN_PATH and HERDR_PLUGIN_ID for every plugin action.

if [[ -z "${1:-}" ]]; then
    print -u2 "usage: action.zsh <pane-entrypoint-id>"
    exit 2
fi

exec "${HERDR_BIN_PATH:?}" plugin pane open --plugin "${HERDR_PLUGIN_ID:?}" --entrypoint "$1"
