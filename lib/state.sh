#!/usr/bin/env zsh
# DAEDALUS State Management
# Tracks the currently active context across sessions

_STATE_DIR="${HOME}/.daedalus/state"
_STATE_FILE="${_STATE_DIR}/current"

get_current_context() {
    if [[ -f "${_STATE_FILE}" ]]; then
        cat "${_STATE_FILE}"
    else
        echo ""
    fi
}

set_current_context() {
    local context="${1:-}"
    [[ -z "$context" ]] && return 0
    mkdir -p "${_STATE_DIR}"
    echo "$context" > "${_STATE_FILE}"
    chmod 600 "${_STATE_FILE}"
}
