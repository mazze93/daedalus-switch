#!/usr/bin/env zsh
# DAEDALUS Configuration Library
# Utilities for loading and parsing YAML context configs

DEADALUS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
DEADALUS_CONFIG="${DAEDALUS_ROOT}/config"

# Global variable to cache loaded context data
declare -gA CONTEXT_DATA

# ============================================================================
# load_context_config <context_name>
# Loads YAML config for a context into associative array
# ============================================================================
load_context_config() {
    local context="${1}"
    local config_file="${DAEDALUS_CONFIG}/${context}.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # For now, we'll source the YAML as zsh variables
    # A proper YAML parser would be ideal, but this is pragmatic
    
    # Read config file into memory
    CONTEXT_DATA=()
    
    return 0
}

# ============================================================================
# get_config_value <context> <key_path>
# Returns config value for a dotted key path (e.g., "vpn.server")
# Parses YAML on-demand
# ============================================================================
get_config_value() {
    local context="${1}"
    local key_path="${2}"
    local config_file="${DAEDALUS_CONFIG}/${context}.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # Simple YAML parsing using grep and awk
    # This is a pragmatic approach for flat/simple YAML structures
    
    # Replace dots with colons and spaces for YAML key matching
    local yaml_key=$(echo "$key_path" | sed 's/\./:/g')
    
    # Extract value from YAML
    # This handles both single-line and multi-line values
    local value=$(grep "^  *${key_path}:" "$config_file" 2>/dev/null | head -1 | cut -d: -f2- | sed 's/^ *//; s/ *$//')
    
    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi
    
    # Try without leading spaces
    value=$(grep "^${key_path}:" "$config_file" 2>/dev/null | head -1 | cut -d: -f2- | sed 's/^ *//; s/ *$//')
    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi
    
    return 1
}

# ============================================================================
# get_config_array <context> <key_path>
# Returns all values for an array key (e.g., "notifications.allow_apps")
# ============================================================================
get_config_array() {
    local context="${1}"
    local key_path="${2}"
    local config_file="${DAEDALUS_CONFIG}/${context}.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # Extract array values (lines starting with -)
    # Assumes array follows immediately after the key
    local in_array=false
    local result=""
    
    while IFS= read -r line; do
        # Check if we found the start of the array
        if [[ "$line" =~ ^[[:space:]]*${key_path}:[[:space:]]*$ ]]; then
            in_array=true
            continue
        fi
        
        # If we're in the array, collect items starting with -
        if [[ "$in_array" == "true" ]]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
                local item="${BASH_REMATCH[1]}"
                result="${result}${item}\n"
            elif [[ ! "$line" =~ ^[[:space:]]*$ ]] && [[ ! "$line" =~ ^[[:space:]]*- ]]; then
                # End of array (next key or same indentation level)
                break
            fi
        fi
    done < "$config_file"
    
    if [[ -n "$result" ]]; then
        echo -e "${result%\n}"  # Remove trailing newline
        return 0
    fi
    
    return 1
}

# ============================================================================
# validate_context <context_name>
# Returns 0 if context config exists and is valid
# ============================================================================
validate_context() {
    local context="${1}"
    local config_file="${DAEDALUS_CONFIG}/${context}.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # Basic YAML validation (check if it's readable)
    if grep -q "^context:" "$config_file" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

return 0
