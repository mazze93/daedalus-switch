#!/usr/bin/env zsh
# DAEDALUS Browser Automation
# Launches Safari profile with context-specific settings and URLs

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

# Get browser config
local browser_profile
local browser_engine
local urls
local clear_browsing_data

browser_profile=$(get_config_value "$context" "browser.profile")
browser_engine=$(get_config_value "$context" "browser.engine")
urls=$(get_config_value "$context" "browser.urls_to_open")
clear_browsing_data=$(get_config_value "$context" "browser.clear_browsing_data")

if [[ -z "$browser_profile" ]]; then
    echo -e "${YELLOW}No browser profile configured for $context${NC}"
    return 0
fi

echo -e "${BLUE}Browser: Launching Safari with profile '${YELLOW}${browser_profile}${BLUE}'...${NC}"

# For Safari, we use the standard Safari app
# Safari doesn't have native profiles like Chrome, but we can control it via AppleScript
# and use different user data directories

if [[ "$browser_engine" == "safari" ]]; then
    # Launch Safari (will use default profile/iCloud sync)
    open -a Safari 2>/dev/null || {
        echo -e "${RED}Error: Could not open Safari${NC}"
        log_event "BROWSER_ERROR" "browser=safari context=$context"
        return 1
    }
    
    # Small delay for Safari to start
    sleep 1
    
    # Open specified URLs
    if [[ -n "$urls" ]]; then
        echo -e "${BLUE}Browser: Opening context URLs...${NC}"
        
        # URLs are newline-separated in the YAML
        echo "$urls" | while read -r url; do
            if [[ -n "$url" ]]; then
                echo -e "  ${BLUE}→ $url${NC}"
                # Use AppleScript to open in new tab
                osascript <<EOF 2>/dev/null || true
tell application "Safari"
    activate
    open location "$url"
end tell
EOF
                # Small delay between URL opens
                sleep 0.5
            fi
        done
    fi
    
    echo -e "${GREEN}✓ Safari configured${NC}"
    log_event "BROWSER_CONFIGURED" "engine=safari profile=$browser_profile context=$context"
    
elif [[ "$browser_engine" == "chrome" ]]; then
    # Chrome support: use --profile-directory
    # Chrome data dir is ~/Library/Application Support/Google/Chrome/
    
    local chrome_data_dir="${HOME}/Library/Application Support/Google/Chrome/${browser_profile}"
    
    if [[ ! -d "$chrome_data_dir" ]]; then
        echo -e "${RED}Error: Chrome profile '$browser_profile' not found${NC}"
        echo "Create profile in Chrome: Settings → Manage profiles → Add profile"
        log_event "BROWSER_ERROR" "browser=chrome profile_missing=$browser_profile context=$context"
        return 1
    fi
    
    # Launch Chrome with specific profile
    open -a "Google Chrome" --args --profile-directory="$browser_profile" 2>/dev/null || {
        echo -e "${RED}Error: Could not open Chrome${NC}"
        log_event "BROWSER_ERROR" "browser=chrome context=$context"
        return 1
    }
    
    # Open URLs
    if [[ -n "$urls" ]]; then
        echo -e "${BLUE}Browser: Opening context URLs...${NC}"
        echo "$urls" | while read -r url; do
            if [[ -n "$url" ]]; then
                echo -e "  ${BLUE}→ $url${NC}"
                open "$url" 2>/dev/null || true
                sleep 0.5
            fi
        done
    fi
    
    echo -e "${GREEN}✓ Chrome configured${NC}"
    log_event "BROWSER_CONFIGURED" "engine=chrome profile=$browser_profile context=$context"
else
    echo -e "${RED}Error: Unknown browser engine: $browser_engine${NC}"
    return 1
fi

# Optional: Clear browsing data if configured
if [[ "$clear_browsing_data" == "true" ]]; then
    echo -e "${YELLOW}Note: Clear browsing data requires manual action in browser settings${NC}"
fi

return 0
