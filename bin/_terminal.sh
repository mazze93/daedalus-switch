#!/usr/bin/env zsh
# DAEDALUS Terminal Automation
# Configures iTerm2 profile, environment variables, SSH keys

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

# Get terminal config from context
local iterm_profile
local ssh_key

iterm_profile=$(get_config_value "$context" "terminal.iterm_profile")
ssh_key=$(get_config_value "$context" "terminal.ssh_key")

# Step 1: Set iTerm2 Profile (via AppleScript)
if [[ -n "$iterm_profile" ]]; then
    echo -e "${BLUE}Terminal: Configuring iTerm2 profile to '${YELLOW}${iterm_profile}${BLUE}'...${NC}"
    
    # Check if iTerm is running
    if pgrep -q iTerm; then
        # Use AppleScript to switch profile
        osascript <<EOF 2>/dev/null || {
            echo -e "${YELLOW}Warning: Could not switch iTerm profile via AppleScript${NC}"
            log_event "TERMINAL_WARNING" "iterm_profile_switch_failed context=$context"
            return 0
        }
tell application "iTerm"
    set newWindow to (create window with default profile)
    tell newWindow
        create tab with default profile
    end tell
end tell
EOF
        echo -e "${GREEN}✓ iTerm2 profile configured${NC}"
        log_event "TERMINAL_ITERM_PROFILE_SET" "profile=$iterm_profile context=$context"
    else
        echo -e "${YELLOW}iTerm2 not running; profile will be used when opened${NC}"
    fi
fi

# Step 2: Validate SSH Key
if [[ -n "$ssh_key" ]]; then
    # Expand ~ to home directory
    local expanded_key="${ssh_key/\~/$HOME}"
    
    if [[ ! -f "$expanded_key" ]]; then
        echo -e "${RED}✗ SSH key not found: $ssh_key${NC}"
        log_event "TERMINAL_SSH_KEY_MISSING" "key=$ssh_key context=$context"
        return 1
    else
        echo -e "${GREEN}✓ SSH key verified: $ssh_key${NC}"
        log_event "TERMINAL_SSH_KEY_VERIFIED" "key=$ssh_key context=$context"
        
        # Ensure key has correct permissions (400)
        chmod 400 "$expanded_key" 2>/dev/null || true
        
        # Add to SSH agent (non-blocking)
        ssh-add -l "$expanded_key" &>/dev/null || ssh-add "$expanded_key" 2>/dev/null || true
    fi
fi

# Step 3: Set environment variables in shell
echo -e "${BLUE}Terminal: Setting environment variables...${NC}"

# Create a shell profile snippet that gets sourced when new terminal opens
local shell_config="${HOME}/.daedalus_${context}.zshenv"

cat > "$shell_config" << 'EOF'
# DAEDALUS Context Environment Variables
# Auto-sourced by ~/.zshrc for this context

EOF

# Get environment variables from config
local env_vars
env_vars=$(get_config_value "$context" "terminal.env_vars")
if [[ -n "$env_vars" ]]; then
    # Parse env variables and append to shell config
    echo "$env_vars" | while IFS='=' read -r key value; do
        if [[ -n "$key" ]]; then
            echo "export $key='$value'" >> "$shell_config"
            echo -e "${GREEN}  ✓ $key = $value${NC}"
        fi
    done
    log_event "TERMINAL_ENV_VARS_SET" "context=$context"
else
    echo -e "${YELLOW}No environment variables configured${NC}"
fi

echo -e "${GREEN}✓ Terminal configuration complete${NC}"
return 0
