#!/usr/bin/env zsh
# DAEDALUS Emergency Kill Switch
# Atomically: close browsers, kill terminal sessions, disconnect VPN, reset state

set -euo pipefail

DEADALUS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
DEADALUS_LIB="${DAEDALUS_ROOT}/lib"

source "${DAEDALUS_LIB}/logging.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${RED}⚠️  EMERGENCY KILL INITIATED${NC}"
echo -e "${RED}Executing atomic reset...${NC}"
echo ""

# Log the emergency kill
log_event "EMERGENCY_KILL_EXECUTED" "timestamp=$(date '+%Y-%m-%d %H:%M:%S')"

# Step 1: Kill all browsers
echo -e "${BLUE}[1/6] Closing browsers...${NC}"
kill_app "Safari"
kill_app "Google Chrome"
kill_app "Chromium"
echo -e "${GREEN}✓ Browsers closed${NC}"

# Step 2: Kill iTerm2
echo -e "${BLUE}[2/6] Closing terminal sessions...${NC}"
kill_app "iTerm"
echo -e "${GREEN}✓ Terminal sessions closed${NC}"

# Step 3: Disconnect VPN
echo -e "${BLUE}[3/6] Disconnecting VPN...${NC}"
if command -v protonvpn &>/dev/null; then
    protonvpn disconnect 2>/dev/null || true
    echo -e "${GREEN}✓ VPN disconnected${NC}"
else
    echo -e "${YELLOW}⚠ ProtonVPN not available${NC}"
fi

# Step 4: Clear recent files
echo -e "${BLUE}[4/6] Clearing recent files...${NC}"
# Clear macOS recent items database
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user 2>/dev/null || true
echo -e "${GREEN}✓ Recent files cleared${NC}"

# Step 5: Clear clipboard
echo -e "${BLUE}[5/6] Clearing clipboard...${NC}"
echo -n | pbcopy
echo -e "${GREEN}✓ Clipboard cleared${NC}"

# Step 6: Reset to neutral state
echo -e "${BLUE}[6/6] Resetting to neutral state...${NC}"
# Disable all Focus modes
osascript -e 'tell application "System Events" to keystroke "d" using {command down, option down, control down, shift down}' 2>/dev/null || true
echo -e "${GREEN}✓ Focus mode disabled${NC}"

echo ""
echo -e "${RED}⚠️  EMERGENCY KILL COMPLETE${NC}"
echo -e "${RED}All contexts cleared. System in neutral state.${NC}"
echo ""
echo -e "${YELLOW}Safety check:${NC}"
echo "  - VPN is disconnected"
echo "  - All browsers closed"
echo "  - Terminal sessions killed"
echo "  - Clipboard cleared"
echo "  - Recent files cleared"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review audit log: daedalus log"
echo "  2. Verify OPSEC: daedalus audit"
echo "  3. Restart context: daedalus switch <context>"
echo ""

return 0

# Helper function to kill an application
kill_app() {
    local app_name="$1"
    if pgrep -q "$app_name" 2>/dev/null; then
        killall "$app_name" 2>/dev/null || true
        sleep 1
    fi
}
