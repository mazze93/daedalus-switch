#!/usr/bin/env zsh
# DAEDALUS ↔ ContextSynapse Integration
# Saves and loads cognitive state (Bayesian priors, weights) on context switch

_COGNITIVE_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_COGNITIVE_DAEDALUS_HOME="$(cd "${_COGNITIVE_BIN_DIR}/.." && pwd)"
_COGNITIVE_STATE_DIR="${_COGNITIVE_DAEDALUS_HOME}/cognitive"
_CONTEXTSYNAPSE_CS_STORE="${HOME}/Library/Application Support/ContextSynapse/users"

# Colors (safe to re-declare; same values as parent)
_COG_BLUE='\033[0;34m'
_COG_GREEN='\033[0;32m'
_COG_YELLOW='\033[1;33m'
_COG_NC='\033[0m'

# --------------------------------------------------------------------------
# find_contextsynapse_bin
# Returns path to contextsynapse binary, or empty string if not found
# --------------------------------------------------------------------------
find_contextsynapse_bin() {
    # Check PATH first
    if command -v contextsynapse &>/dev/null; then
        command -v contextsynapse
        return 0
    fi
    # Fall back to local build
    local local_build="${HOME}/Code/ContextSynapse/.build/release/contextsynapse"
    if [[ -x "$local_build" ]]; then
        echo "$local_build"
        return 0
    fi
    echo ""
}

# --------------------------------------------------------------------------
# save_cognitive_state <context>
# Exports ContextSynapse state for the given context to DAEDALUS cognitive dir
# --------------------------------------------------------------------------
save_cognitive_state() {
    local context="${1:-}"
    [[ -z "$context" ]] && return 0

    local cs_bin
    cs_bin="$(find_contextsynapse_bin)"
    [[ -z "$cs_bin" ]] && return 0

    local snapshot_dir="${_COGNITIVE_STATE_DIR}/${context}"
    mkdir -p "$snapshot_dir"

    if "$cs_bin" --export "${snapshot_dir}/state.json" --user "$context" \
        --metadata "saved_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --metadata "daedalus_context=$context" &>/dev/null; then
        log_event "COGNITIVE_SAVED" "context=$context"
    else
        log_event "COGNITIVE_SAVE_FAILED" "context=$context"
    fi
    return 0
}

# --------------------------------------------------------------------------
# load_cognitive_state <context>
# Imports ContextSynapse state for incoming context, then shows summary
# --------------------------------------------------------------------------
load_cognitive_state() {
    local context="${1:-}"
    [[ -z "$context" ]] && return 0

    local cs_bin
    cs_bin="$(find_contextsynapse_bin)"
    [[ -z "$cs_bin" ]] && return 0

    local snapshot="${_COGNITIVE_STATE_DIR}/${context}/state.json"

    if [[ -f "$snapshot" ]]; then
        if "$cs_bin" --import "$snapshot" --user "$context" &>/dev/null; then
            log_event "COGNITIVE_LOADED" "context=$context"
        else
            log_event "COGNITIVE_LOAD_FAILED" "context=$context"
        fi
    else
        # No snapshot yet — first time in this context; ContextSynapse
        # will auto-create a fresh profile on next invocation
        log_event "COGNITIVE_INIT" "context=$context reason=no_snapshot"
    fi

    show_cognitive_summary "$context"
    return 0
}

# --------------------------------------------------------------------------
# show_cognitive_summary <context>
# Prints a brief summary of the cognitive state for the incoming context
# --------------------------------------------------------------------------
show_cognitive_summary() {
    local context="${1:-}"
    [[ -z "$context" ]] && return 0

    local profile_file="${_CONTEXTSYNAPSE_CS_STORE}/${context}/profile.json"
    local config_file="${_CONTEXTSYNAPSE_CS_STORE}/${context}/config.json"

    # Only display if we have at least a profile
    [[ ! -f "$profile_file" ]] && return 0

    echo ""
    echo -e "${_COG_BLUE}── Cognitive context: ${_COG_YELLOW}${context}${_COG_BLUE} $(printf '─%.0s' {1..35})${_COG_NC}"

    # Last active time
    local last_active
    last_active="$(python3 -c "
import json, sys
try:
    d = json.load(open('${profile_file}'))
    ts = d.get('lastUsedAt','unknown')
    # Trim to readable format if ISO8601
    print(ts[:16].replace('T',' ') if 'T' in ts else ts)
except:
    print('unknown')
" 2>/dev/null)"
    echo -e "  Last active:  ${last_active}"

    # Top weights per category
    if [[ -f "$config_file" ]]; then
        python3 -c "
import json, sys

try:
    cfg = json.load(open('${config_file}'))
    for cat in ['intents', 'tones', 'domains']:
        weights = cfg.get(cat, {})
        if weights:
            top = max(weights, key=weights.get)
            val = weights[top]
            label = cat.rstrip('s').capitalize()
            print(f'  {label+\":\":<14}{top} ({val:.2f})')
except Exception as e:
    pass
" 2>/dev/null
    fi

    echo -e "${_COG_BLUE}$(printf '─%.0s' {1..53})${_COG_NC}"
    echo ""
    return 0
}
