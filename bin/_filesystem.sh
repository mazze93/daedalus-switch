#!/usr/bin/env zsh
# DAEDALUS File System Isolation
# Manages context-specific directory visibility and mounting

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

echo -e "${BLUE}File System: Configuring directory visibility...${NC}"

# Get filesystem config
local mount_paths
local hide_dirs
local spotlight_ignore

mount_paths=$(get_config_value "$context" "filesystem.mount_paths")
hide_dirs=$(get_config_value "$context" "filesystem.hide_directories")
spotlight_ignore=$(get_config_value "$context" "filesystem.spotlight_ignore")

# Step 1: Manage directory visibility in Finder
if [[ -n "$hide_dirs" ]]; then
    echo -e "${BLUE}File System: Hiding context-sensitive directories...${NC}"
    
    echo "$hide_dirs" | while read -r dir; do
        if [[ -n "$dir" ]]; then
            # Expand ~ to home directory
            local expanded_dir="${dir/\~/$HOME}"
            
            if [[ -d "$expanded_dir" ]]; then
                # Set directory as hidden (macOS uses . prefix, but we can also use extended attributes)
                # Use chflags hidden on macOS
                if chflags hidden "$expanded_dir" 2>/dev/null; then
                    echo -e "  ${GREEN}✓ Hidden: $dir${NC}"
                    log_event "FILESYSTEM_DIR_HIDDEN" "dir=$dir context=$context"
                else
                    echo -e "  ${YELLOW}⚠ Could not hide: $dir${NC}"
fi
            else
                echo -e "  ${YELLOW}⚠ Directory not found: $dir${NC}"
            fi
        fi
    done
fi

# Step 2: Configure Spotlight exclusion
if [[ -n "$spotlight_ignore" ]]; then
    echo -e "${BLUE}File System: Configuring Spotlight exclusions...${NC}"
    
    echo "$spotlight_ignore" | while read -r path; do
        if [[ -n "$path" ]]; then
            local expanded_path="${path/\~/$HOME}"
            
            if [[ -d "$expanded_path" ]]; then
                # Add to Spotlight exclusion list
                # Use mdutil to disable Spotlight indexing for the path
                if mdutil -i off "$expanded_path" 2>/dev/null; then
                    echo -e "  ${GREEN}✓ Spotlight excluded: $path${NC}"
                    log_event "FILESYSTEM_SPOTLIGHT_EXCLUDED" "path=$path context=$context"
                else
                    echo -e "  ${YELLOW}⚠ Could not exclude from Spotlight: $path${NC}"
                fi
            fi
        fi
    done
fi

# Step 3: Unhide other contexts' directories
echo -e "${BLUE}File System: Showing active context directories...${NC}"

local daedalus_dir="${HOME}/.daedalus"

for other_context in daedalus personal creator organizer; do
    if [[ "$other_context" != "$context" ]]; then
        local context_dir="${daedalus_dir}/${other_context}"
        if [[ -d "$context_dir" ]]; then
            # Unhide it (in case it was hidden from another context)
            chflags nohidden "$context_dir" 2>/dev/null || true
        fi
    fi
done

# Ensure current context directory is visible
if [[ -d "${daedalus_dir}/${context}" ]]; then
    chflags nohidden "${daedalus_dir}/${context}" 2>/dev/null || true
    echo -e "${GREEN}✓ Context directory visible: ~/.daedalus/${context}${NC}"
fi

echo -e "${GREEN}✓ File system configuration complete${NC}"
log_event "FILESYSTEM_CONFIGURED" "context=$context"

return 0
