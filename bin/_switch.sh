#!/usr/bin/env zsh
# DAEDALUS Context Switch Orchestrator
# Coordinates all switching steps: VPN → Browser → Terminal → Notifications → Filesystem

set -euo pipefail

DEADALUS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
DEADALUS_BIN="${DAEDALUS_ROOT}/bin"
DEADALUS_CONFIG="${DAEDALUS_ROOT}/config"
DEADALUS_LIB="${DAEDALUS_ROOT}/lib"

source "${DAEDALUS_LIB}/logging.sh"
source "${DAEDALUS_LIB}/config.sh"

# Cognitive integration (non-fatal if missing)
_SW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${_SW_DIR}/../lib/state.sh" ]] && source "${_SW_DIR}/../lib/state.sh"
[[ -f "${_SW_DIR}/_cognitive.sh" ]]   && source "${_SW_DIR}/_cognitive.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

local context="${1}"

echo -e "${BLUE}┌─ Initializing Context Switch${NC}"

# Load context configuration
echo -e "${BLUE}├─ Loading context configuration...${NC}"
if ! load_context_config "$context"; then
    echo -e "${RED}└─ Failed to load context config${NC}"
    return 1
fi
echo -e "${GREEN}├─ ✓ Configuration loaded${NC}"

# Save outgoing cognitive state (non-fatal)
if typeset -f save_cognitive_state &>/dev/null; then
    save_cognitive_state "$(get_current_context)" || true
fi

# Step 1: VPN Connection
echo -e "${BLUE}├─ Configuring VPN...${NC}"
if "${DAEDALUS_BIN}/_vpn.sh" "$context"; then
    echo -e "${GREEN}├─ ✓ VPN configured${NC}"
else
    echo -e "${RED}├─ ✗ VPN configuration failed${NC}"
    log_event "SWITCH_STEP_FAILED" "step=vpn context=$context"
    return 1
fi

# Step 2: Terminal/iTerm2 Profile
echo -e "${BLUE}├─ Configuring terminal...${NC}"
if "${DAEDALUS_BIN}/_terminal.sh" "$context"; then
    echo -e "${GREEN}├─ ✓ Terminal configured${NC}"
else
    echo -e "${RED}├─ ✗ Terminal configuration failed (non-fatal)${NC}"
    log_event "SWITCH_STEP_WARNING" "step=terminal context=$context"
fi

# Step 3: Browser Profile
echo -e "${BLUE}├─ Configuring browser...${NC}"
if "${DAEDALUS_BIN}/_browser.sh" "$context"; then
    echo -e "${GREEN}├─ ✓ Browser ready${NC}"
else
    echo -e "${RED}├─ ✗ Browser configuration failed (non-fatal)${NC}"
    log_event "SWITCH_STEP_WARNING" "step=browser context=$context"
fi

# Step 4: Notifications & Focus Mode
echo -e "${BLUE}├─ Configuring notifications and focus...${NC}"
if "${DAEDALUS_BIN}/_notifications.sh" "$context"; then
    echo -e "${GREEN}├─ ✓ Notifications configured${NC}"
else
    echo -e "${RED}├─ ✗ Notification configuration failed (non-fatal)${NC}"
    log_event "SWITCH_STEP_WARNING" "step=notifications context=$context"
fi

# Step 5: File System Isolation
echo -e "${BLUE}├─ Configuring file system...${NC}"
if "${DAEDALUS_BIN}/_filesystem.sh" "$context"; then
    echo -e "${GREEN}├─ ✓ File system isolated${NC}"
else
    echo -e "${RED}├─ ✗ Filesystem configuration failed (non-fatal)${NC}"
    log_event "SWITCH_STEP_WARNING" "step=filesystem context=$context"
fi

# Load incoming cognitive state and show summary (non-fatal)
if typeset -f load_cognitive_state &>/dev/null; then
    load_cognitive_state "$context" || true
fi

echo -e "${GREEN}└─ Context switch complete${NC}"
echo ""
echo -e "${GREEN}Active Context: ${YELLOW}${context}${GREEN} ✓${NC}"
echo -e "${GREEN}Timestamp: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

return 0
