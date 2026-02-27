#!/usr/bin/env zsh
# DAEDALUS VPN Automation
# Handles Proton VPN CLI connection management

set -euo pipefail

DEADALUS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
DEADALUS_LIB="${DAEDALUS_ROOT}/lib"

source "${DAEDALUS_LIB}/config.sh"
source "${DAEDALUS_LIB}/logging.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

local context="${1}"

# Check if protonvpn-cli is installed
if ! command -v protonvpn &> /dev/null; then
    echo -e "${RED}Error: protonvpn-cli not installed${NC}"
    echo "Install via: brew install protonvpn-cli"
    log_event "VPN_ERROR" "protonvpn_cli_not_installed context=$context"
    return 1
fi

# Get VPN server from context
local vpn_server
local vpn_profile
local kill_switch
local auto_connect

vpn_server=$(get_config_value "$context" "vpn.server")
vpn_profile=$(get_config_value "$context" "vpn.profile_name")
auto_connect=$(get_config_value "$context" "vpn.auto_connect")
kill_switch=$(get_config_value "$context" "vpn.kill_switch")

if [[ -z "$vpn_server" ]]; then
    echo -e "${YELLOW}Warning: No VPN server configured for $context${NC}"
    log_event "VPN_WARNING" "no_server_configured context=$context"
    return 0
fi

echo -e "${BLUE}VPN: Disconnecting current connection...${NC}"
# Safe disconnect (won't error if not connected)
protonvpn disconnect 2>/dev/null || true

echo -e "${BLUE}VPN: Connecting to ${YELLOW}${vpn_server}${NC}..."
if protonvpn connect --servername "$vpn_server" 2>/dev/null; then
    echo -e "${GREEN}✓ VPN connected: $vpn_server${NC}"
    log_event "VPN_CONNECTED" "server=$vpn_server context=$context"
    
    # Enable kill switch if configured
    if [[ "$kill_switch" == "true" ]]; then
        echo -e "${BLUE}VPN: Enabling kill switch...${NC}"
        protonvpn killswitch on 2>/dev/null || true
        log_event "VPN_KILLSWITCH_ENABLED" "context=$context"
    fi
    
    return 0
else
    echo -e "${RED}✗ Failed to connect to VPN${NC}"
    echo "Troubleshooting:"
    echo "  1. Check Proton credentials: protonvpn config"
    echo "  2. List available servers: protonvpn connect --help"
    echo "  3. Verify connectivity: ping 8.8.8.8"
    log_event "VPN_FAILED" "server=$vpn_server context=$context"
    return 1
fi
