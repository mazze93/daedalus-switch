#!/usr/bin/env zsh
# DAEDALUS OPSEC Audit
# Verifies context integrity, VPN kill-switch, file permissions, etc.

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

echo ""
echo -e "${BLUE}┌─ DAEDALUS OPSEC Audit${NC}"
echo -e "${BLUE}├─ Running security and integrity checks...${NC}"
echo ""

local audit_passed=true

# Check 1: Log file permissions
echo -e "${BLUE}├─ Checking log file permissions...${NC}"
if [[ -f "${DAEDALUS_ROOT}/logs/audit.log" ]]; then
    local perms=$(stat -f '%OLp' "${DAEDALUS_ROOT}/logs/audit.log")
    if [[ "$perms" == *"600"* ]] || [[ "$perms" == *"400"* ]]; then
        echo -e "  ${GREEN}✓ Audit log is not world-readable (perms: $perms)${NC}"
    else
        echo -e "  ${RED}✗ Audit log permissions too permissive: $perms${NC}"
        echo "    Fix with: chmod 600 ~/.daedalus/logs/audit.log"
        audit_passed=false
    fi
fi

# Check 2: SSH Key permissions
echo -e "${BLUE}├─ Checking SSH key permissions...${NC}"
for ssh_key in ~/.ssh/id_rsa_*; do
    if [[ -f "$ssh_key" ]]; then
        local key_perms=$(stat -f '%OLp' "$ssh_key")
        if [[ "$key_perms" == *"600"* ]] || [[ "$key_perms" == *"400"* ]]; then
            echo -e "  ${GREEN}✓ $(basename $ssh_key): $key_perms${NC}"
        else
            echo -e "  ${RED}✗ $(basename $ssh_key): permissions too permissive ($key_perms)${NC}"
            echo "    Fix with: chmod 600 $ssh_key"
            audit_passed=false
        fi
    fi
done

# Check 3: VPN Kill Switch
echo -e "${BLUE}├─ Checking VPN kill-switch...${NC}"
if command -v protonvpn &>/dev/null; then
    local killswitch_status=$(protonvpn killswitch status 2>/dev/null || echo "unknown")
    if [[ "$killswitch_status" == *"on"* ]] || [[ "$killswitch_status" == *"On"* ]]; then
        echo -e "  ${GREEN}✓ VPN kill-switch is ENABLED${NC}"
    else
        echo -e "  ${YELLOW}⚠ VPN kill-switch is disabled (consider enabling)${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ ProtonVPN CLI not installed; install with: brew install protonvpn-cli${NC}"
fi

# Check 4: Directory hidden flags
echo -e "${BLUE}├─ Checking directory visibility...${NC}"
for context in personal creator organizer; do
    local context_dir="${HOME}/.daedalus/${context}"
    if [[ -d "$context_dir" ]]; then
        # Check if hidden
        if [[ -f "$context_dir" ]]; then
            local is_hidden=$(ls -ldo "$context_dir" | grep -o '^\.' | wc -l)
            if (( is_hidden > 0 )); then
                echo -e "  ${GREEN}✓ ~/.daedalus/${context} is hidden${NC}"
            else
                echo -e "  ${YELLOW}⚠ ~/.daedalus/${context} is visible (consider hiding)${NC}"
            fi
        fi
    fi
done

# Check 5: Config file integrity
echo -e "${BLUE}├─ Checking context configurations...${NC}"
if [[ $(ls -1 "${DAEDALUS_ROOT}/config"/*.yaml 2>/dev/null | wc -l) -gt 0 ]]; then
    echo -e "  ${GREEN}✓ Configuration files found$(NC)"
else
    echo -e "  ${RED}✗ No configuration files found in ${DAEDALUS_ROOT}/config${NC}"
    audit_passed=false
fi

# Check 6: Audit log integrity
echo -e "${BLUE}├─ Checking audit log...${NC}"
if [[ -f "${DAEDALUS_ROOT}/logs/audit.log" ]]; then
    local log_lines=$(wc -l < "${DAEDALUS_ROOT}/logs/audit.log")
    echo -e "  ${GREEN}✓ Audit log has $log_lines entries${NC}"
else
    echo -e "  ${YELLOW}⚠ No audit log yet (will be created on first switch)${NC}"
fi

# Check 7: Recent successful switches
echo -e "${BLUE}├─ Checking recent switches...${NC}"
if [[ -f "${DAEDALUS_ROOT}/logs/audit.log" ]]; then
    local successful_switches=$(grep "SWITCH_SUCCESS" "${DAEDALUS_ROOT}/logs/audit.log" 2>/dev/null | wc -l)
    if (( successful_switches > 0 )); then
        echo -e "  ${GREEN}✓ $successful_switches successful context switches${NC}"
        echo ""
        echo -e "  ${BLUE}Last 3 switches:${NC}"
        grep "SWITCH_SUCCESS" "${DAEDALUS_ROOT}/logs/audit.log" 2>/dev/null | tail -3 | while read -r line; do
            echo -e "    ${YELLOW}${line}${NC}"
        done
    else
        echo -e "  ${YELLOW}⚠ No successful switches yet${NC}"
    fi
fi

echo ""
echo -e "${BLUE}├─ Remediation Steps (if needed):${NC}"
if [[ "$audit_passed" == "false" ]]; then
    echo -e "  ${RED}Audit FAILED${NC}"
    echo ""
    echo -e "  ${YELLOW}Recommended fixes:${NC}"
    echo "    1. Fix SSH key permissions: chmod 600 ~/.ssh/id_rsa_*"
    echo "    2. Fix audit log permissions: chmod 600 ~/.daedalus/logs/audit.log"
    echo "    3. Enable VPN kill-switch: protonvpn killswitch on"
    echo "    4. Hide context directories: chflags hidden ~/.daedalus/personal ~/.daedalus/creator"
    log_event "AUDIT_FAILED" "severity=high"
else
    echo -e "  ${GREEN}✓ All checks passed${NC}"
    log_event "AUDIT_PASSED" "severity=info"
fi

echo ""
echo -e "${BLUE}└─ Audit Complete${NC}"
echo ""

if [[ "$audit_passed" == "false" ]]; then
    return 1
fi

return 0
