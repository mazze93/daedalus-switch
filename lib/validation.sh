#!/usr/bin/env zsh
# DAEDALUS Validation Library
# Validates contexts, configurations, and system state

# ============================================================================
# validate_context <context_name>
# Returns 0 if context exists and is properly configured
# ============================================================================
validate_context() {
    local context="${1}"
    local daedalus_root="${DAEDALUS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)}"
    local config_file="${daedalus_root}/config/${context}.yaml"
    
    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # Validate YAML structure
    if ! grep -q "^context:" "$config_file"; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# validate_vpn_config <context>
# Returns 0 if VPN is properly configured
# ============================================================================
validate_vpn_config() {
    local context="${1}"
    local daedalus_root="${DAEDALUS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)}"
    local config_file="${daedalus_root}/config/${context}.yaml"
    
    # Check if VPN provider is configured
    if ! grep -q "^  provider:" "$config_file"; then
        return 1
    fi
    
    # Check if VPN server is configured
    if ! grep -q "^  server:" "$config_file"; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# validate_browser_config <context>
# Returns 0 if browser is properly configured
# ============================================================================
validate_browser_config() {
    local context="${1}"
    local daedalus_root="${DAEDALUS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)}"
    local config_file="${daedalus_root}/config/${context}.yaml"
    
    # Check if browser engine is configured
    if ! grep -q "^    engine:" "$config_file"; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# validate_file_permissions <file_path>
# Returns 0 if file has restrictive permissions (400, 600, 700)
# ============================================================================
validate_file_permissions() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local perms=$(stat -f '%OLp' "$file")
    
    case "$perms" in
        *400*|*600*|*700*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

return 0
