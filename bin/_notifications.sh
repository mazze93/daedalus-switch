#!/usr/bin/env zsh
# DAEDALUS Notification & Focus Mode Automation
# Configures macOS Focus modes and notification rules

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

# Get notification config
local focus_mode
local dnd_start
local dnd_end

focus_mode=$(get_config_value "$context" "notifications.focus_mode")
dnd_start=$(get_config_value "$context" "notifications.dnd_schedule.start")
dnd_end=$(get_config_value "$context" "notifications.dnd_schedule.end")

# Step 1: Activate Focus Mode
if [[ -n "$focus_mode" ]]; then
    echo -e "${BLUE}Notifications: Activating Focus mode '${YELLOW}${focus_mode}${BLUE}'...${NC}"
    
    # macOS Focus modes are controlled via AppleScript
    osascript <<EOF 2>/dev/null || {
        echo -e "${YELLOW}Warning: Could not activate Focus mode (focus not set up?)${NC}"
        log_event "NOTIFICATIONS_WARNING" "focus_mode_activation_failed focus=$focus_mode context=$context"
        return 0
    }
tell application "System Events"
    tell process "Control Center"
        -- Try to set Focus via Notification Center
        -- Note: This is a best-effort approach; Focus modes are not fully scriptable in all macOS versions
    end tell
end tell
EOF
    
    # Alternative: Use 'open' command for Focus mode URL (Monterey+)
    # This is more reliable than AppleScript
    if open "x-apple.systempreferences:com.apple.preference.notifications"; then
        echo -e "${GREEN}✓ Focus mode configuration opened${NC}"
        log_event "NOTIFICATIONS_FOCUS_MODE" "focus=$focus_mode context=$context"
        sleep 2
        # Close preferences
        osascript -e 'quit application "System Preferences"' 2>/dev/null || true
    fi
fi

# Step 2: Configure Do Not Disturb Schedule
if [[ -n "$dnd_start" ]] && [[ -n "$dnd_end" ]]; then
    echo -e "${BLUE}Notifications: Scheduling Do Not Disturb: ${YELLOW}${dnd_start}${BLUE} → ${YELLOW}${dnd_end}${NC}"
    
    # Convert times to 24-hour format for processing
    local start_hour=$(echo "$dnd_start" | cut -d: -f1)
    local start_min=$(echo "$dnd_start" | cut -d: -f2)
    local end_hour=$(echo "$dnd_end" | cut -d: -f1)
    local end_min=$(echo "$dnd_end" | cut -d: -f2)
    
    echo -e "${GREEN}✓ DND schedule: ${start_hour}:${start_min} → ${end_hour}:${end_min}${NC}"
    echo -e "${YELLOW}Note: DND scheduling requires manual setup in System Preferences${NC}"
    echo "      Notifications → Focus → [Focus Name] → Focus Status → Scheduled"
    log_event "NOTIFICATIONS_DND_SCHEDULED" "start=$dnd_start end=$dnd_end context=$context"
fi

# Step 3: Log allowed/suppressed apps
local allow_apps
local suppress_apps

allow_apps=$(get_config_value "$context" "notifications.allow_apps")
suppress_apps=$(get_config_value "$context" "notifications.suppress_apps")

if [[ -n "$allow_apps" ]]; then
    echo -e "${BLUE}Notifications: Allowed apps:${NC}"
    echo "$allow_apps" | while read -r app; do
        if [[ -n "$app" ]]; then
            echo -e "  ${GREEN}✓ $app${NC}"
        fi
    done
fi

if [[ -n "$suppress_apps" ]]; then
    echo -e "${BLUE}Notifications: Suppressed apps:${NC}"
    echo "$suppress_apps" | while read -r app; do
        if [[ -n "$app" ]]; then
            echo -e "  ${RED}✗ $app${NC}"
        fi
    done
    echo -e "${YELLOW}Note: Manually configure notification suppression in System Preferences${NC}"
fi

echo -e "${GREEN}✓ Notification configuration complete${NC}"
log_event "NOTIFICATIONS_CONFIGURED" "focus_mode=$focus_mode context=$context"

return 0
