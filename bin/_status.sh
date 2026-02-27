#!/usr/bin/env zsh
# DAEDALUS Status Command
# Shows current context and system state verification

set -euo pipefail

DEADALUS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
DEADALUS_CONFIG="${DAEDALUS_ROOT}/config"
DEADALUS_LIB="${DAEDALUS_ROOT}/lib"

source "${DAEDALUS_LIB}/config.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}┌───────────── DAEDALUS Status ─────────────┌${NC}"

# Detect active context from environment variable or last log
local active_context="unknown"

if [[ -n "${DAEDALUS_CONTEXT:-}" ]]; then
    active_context="$DAEDALUS_CONTEXT"
elif [[ -f "${DAEDALUS_ROOT}/logs/audit.log" ]]; then
    # Find the most recent successful switch
    active_context=$(grep "SWITCH_SUCCESS" "${DAEDALUS_ROOT}/logs/audit.log" 2>/dev/null | tail -1 | grep -oP 'context=\K[^ ]*' || echo "unknown")
fi

echo -e "${BLUE}├─ Active Context:${NC}"
echo -e "${YELLOW}  ${active_context}${NC}"

echo ""
echo -e "${BLUE}├─ System Status:${NC}"

# VPN Status
echo -n -e "${BLUE}  VPN: ${NC}"
if pgrep -q openvpn 2>/dev/null || pgrep -q protonvpn 2>/dev/null; then
    echo -e "${GREEN}✓ Connected${NC}"
    # Try to get VPN info
    if command -v protonvpn &>/dev/null; then
        local vpn_info=$(protonvpn status 2>/dev/null | grep -i "status\|server" | head -2 || echo "")
        if [[ -n "$vpn_info" ]]; then
            echo "$vpn_info" | while read -r line; do
                echo -e "      ${BLUE}$line${NC}"
            done
        fi
    fi
else
    echo -e "${RED}✗ Disconnected${NC}"
fi

# iTerm2 Status
echo -n -e "${BLUE}  iTerm2: ${NC}"
if pgrep -q iTerm; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
fi

# Safari Status
echo -n -e "${BLUE}  Safari: ${NC}"
if pgrep -q Safari; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${YELLOW}⚠ Not running${NC}"
fi

# Chrome Status
echo -n -e "${BLUE}  Chrome: ${NC}"
if pgrep -q "Google Chrome"; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${YELLOW}⚠ Not running${NC}"
fi

echo ""
echo -e "${BLUE}├─ Last Switch:${NC}"

if [[ -f "${DAEDALUS_ROOT}/logs/audit.log" ]]; then
    local last_switch=$(grep "SWITCH_SUCCESS" "${DAEDALUS_ROOT}/logs/audit.log" 2>/dev/null | tail -1 || echo "No switches recorded")
    if [[ -n "$last_switch" ]]; then
        echo -e "  ${YELLOW}${last_switch}${NC}"
    fi
else
    echo -e "  ${YELLOW}No switches recorded yet${NC}"
fi

echo ""
echo -e "${BLUE}├─ Available Contexts:${NC}"

for config_file in "${DAEDALUS_CONFIG}"/*.yaml; do
    if [[ -f "$config_file" ]]; then
        local config_name=$(basename "$config_file" .yaml)
        if [[ "$config_name" == "$active_context" ]]; then
            echo -e "  ${GREEN}✓ $config_name${NC}"
        else
            echo -e "  ${YELLOW}⚠ $config_name${NC}"
        fi
    fi
done

echo ""
echo -e "${BLUE}└────────────────────────────────────└${NC}"
echo ""
echo -e "${YELLOW}Run 'daedalus audit' to verify OPSEC integrity${NC}"
echo -e "${YELLOW}Run 'daedalus log' to view switch history${NC}"

echo ""

return 0
