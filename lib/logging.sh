#!/usr/bin/env zsh
# DAEDALUS Logging Library
# Provides audit trail functionality with timestamps

DEADALUS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
DAEDALUS_LOGS="${DAEDALUS_ROOT}/logs"

# Ensure logs directory exists
mkdir -p "${DAEDALUS_LOGS}"

# ============================================================================
# log_event <event_type> <event_details>
# ============================================================================
log_event() {
    local event_type="${1:-UNKNOWN}"
    local event_details="${2:-}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local log_entry="[${timestamp}] ${event_type} ${event_details}"
    
    # Append to audit log (only user-readable, no world-readable)
    echo "$log_entry" >> "${DAEDALUS_LOGS}/audit.log"
    
    # Ensure log file permissions are restrictive
    chmod 600 "${DAEDALUS_LOGS}/audit.log" 2>/dev/null || true
}

return 0
