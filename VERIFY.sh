#!/usr/bin/env zsh
# DAEDALUS Verification Script
# Run this to check if installation is complete

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}┌─ DAEDALUS Installation Verification${NC}"
echo ""

passed=0
failed=0

# Check 1: Daedalus directory exists
echo -n -e "${BLUE}[1/12]${NC} Checking ~/.daedalus directory... "
if [[ -d "$HOME/.daedalus" ]]; then
    echo -e "${GREEN}✓${NC}"
    ((passed++))
else
    echo -e "${RED}✗${NC}"
    ((failed++))
fi

# Check 2: Main executable
echo -n -e "${BLUE}[2/12]${NC} Checking daedalus main script... "
if [[ -f "$HOME/.daedalus/bin/daedalus" ]] && [[ -x "$HOME/.daedalus/bin/daedalus" ]]; then
    echo -e "${GREEN}✓${NC}"
    ((passed++))
else
    echo -e "${RED}✗${NC}"
    ((failed++))
fi

# Check 3: All bin scripts exist
echo -n -e "${BLUE}[3/12]${NC} Checking bin scripts (9 expected)... "
bin_count=$(ls "$HOME/.daedalus/bin" | wc -l)
if [[ "$bin_count" -ge 9 ]]; then
    echo -e "${GREEN}✓${NC} ($bin_count found)"
    ((passed++))
else
    echo -e "${RED}✗${NC} (only $bin_count found)"
    ((failed++))
fi

# Check 4: All config files
echo -n -e "${BLUE}[4/12]${NC} Checking context configs (4 expected)... "
config_count=$(ls "$HOME/.daedalus/config"/*.yaml 2>/dev/null | wc -l)
if [[ "$config_count" -ge 4 ]]; then
    echo -e "${GREEN}✓${NC} ($config_count found)"
    ((passed++))
else
    echo -e "${RED}✗${NC} (only $config_count found)"
    ((failed++))
fi

# Check 5: Library files
echo -n -e "${BLUE}[5/12]${NC} Checking lib files (3 expected)... "
lib_count=$(ls "$HOME/.daedalus/lib"/*.sh 2>/dev/null | wc -l)
if [[ "$lib_count" -eq 3 ]]; then
    echo -e "${GREEN}✓${NC}"
    ((passed++))
else
    echo -e "${RED}✗${NC} (only $lib_count found)"
    ((failed++))
fi

# Check 6: Proton VPN CLI installed
echo -n -e "${BLUE}[6/12]${NC} Checking protonvpn-cli... "
if command -v protonvpn &>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((passed++))
else
    echo -e "${RED}✗${NC}"
    echo -e "      ${YELLOW}Install: brew install protonvpn-cli${NC}"
    ((failed++))
fi

# Check 7: Logs directory
echo -n -e "${BLUE}[7/12]${NC} Checking logs directory... "
if [[ -d "$HOME/.daedalus/logs" ]]; then
    echo -e "${GREEN}✓${NC}"
    ((passed++))
else
    echo -e "${RED}✗${NC}"
    ((failed++))
fi

# Check 8: Context data directories
echo -n -e "${BLUE}[8/12]${NC} Checking context directories... "
for ctx in daedalus ryan creative community; do
    if [[ ! -d "$HOME/.daedalus/$ctx" ]]; then
        echo -e "${RED}✗${NC} Missing: $ctx"
        ((failed++))
        break
    fi
done
echo -e "${GREEN}✓${NC}"
((passed++))

# Check 9: SSH keys
echo -n -e "${BLUE}[9/12]${NC} Checking SSH keys (4 expected)... "
ssh_count=$(ls "$HOME/.ssh/id_rsa_"* 2>/dev/null | wc -l)
if [[ "$ssh_count" -ge 4 ]]; then
    echo -e "${GREEN}✓${NC} ($ssh_count found)"
    ((passed++))
else
    echo -e "${YELLOW}⚠${NC} (only $ssh_count found)"
    echo -e "      ${YELLOW}Create with: ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_security${NC}"
    ((failed++))
fi

# Check 10: daedalus alias
echo -n -e "${BLUE}[10/12]${NC} Checking zshrc alias... "
if grep -q "alias daedalus" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((passed++))
else
    echo -e "${YELLOW}⚠${NC}"
    echo -e "      ${YELLOW}Add to ~/.zshrc: alias daedalus=\"~/.daedalus/bin/daedalus\"${NC}"
    ((failed++))
fi

# Check 11: Script permissions
echo -n -e "${BLUE}[11/12]${NC} Checking script permissions... "
if [[ -x "$HOME/.daedalus/bin/daedalus" ]]; then
    echo -e "${GREEN}✓${NC}"
    ((passed++))
else
    echo -e "${RED}✗${NC}"
    echo -e "      ${YELLOW}Fix: chmod +x ~/.daedalus/bin/*${NC}"
    ((failed++))
fi

# Check 12: Test daedalus command
echo -n -e "${BLUE}[12/12]${NC} Testing daedalus command... "
if "$HOME/.daedalus/bin/daedalus" help &>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((passed++))
else
    echo -e "${RED}✗${NC}"
    ((failed++))
fi

echo ""
echo -e "${BLUE}├─ Results:${NC}"
echo -e "${GREEN}✓ Passed: $passed/12${NC}"
if [[ "$failed" -gt 0 ]]; then
    echo -e "${RED}✗ Failed: $failed/12${NC}"
else
    echo -e "${GREEN}✓ All checks passed!${NC}"
fi

echo ""
if [[ "$failed" -eq 0 ]]; then
    echo -e "${GREEN}✔ Installation verified successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review context configs: nano ~/.daedalus/config/daedalus.yaml"
    echo "2. Test first switch: daedalus switch daedalus"
    echo "3. Check status: daedalus status"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Installation incomplete. Fix errors above.${NC}"
    echo ""
    exit 1
fi
