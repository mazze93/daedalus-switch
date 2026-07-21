# DAEDALUS: Installation & Setup Guide

## Prerequisites

### 1. Proton VPN CLI

Required for automated VPN switching with kill-switch support.

```bash
# Install via Homebrew
brew install protonvpn-cli

# Configure with Proton credentials
protonvpn config

# Verify installation
protonvpn status

# List available VPN servers
protonvpn list
```

**What to do with server list**:
- Note server names you want per context (e.g., `proton-vpn-security`, `proton-vpn-adult`)
- Update context YAML files with your preferred servers
- Test connection: `protonvpn connect --servername "proton-vpn-security"`

### 2. macOS Requirements

- **macOS 11+** (for full AppleScript/Focus mode support)
- **zsh shell** (default since Catalina)
- **Admin access** (for file permissions, directory hiding)

### 3. Initial System Setup

#### Create macOS Focus Modes

For each context, create a corresponding Focus mode:

1. Open **System Preferences** → **Focus**
2. Click **+** (New)
3. Create:
   - "Security" (for daedalus context)
   - "Creator" (for creative context)
   - "Organizing" (for organizer context)
   - Your preference for personal context

#### Create Safari/Chrome Profiles (Optional)

**Safari**: Preferences → Profiles (Safari uses iCloud sync; no true profile separation)

**Chrome**: Settings → Profiles → Add profile
- Create: "daedalus-professional", "personal-workspace", "creator-workspace", etc.
- Sync each with separate Google account or local storage

#### Create SSH Keys Per Context

```bash
# Security context
ssh-keygen -t ed25519 -C "daedalus@secure-pride" -f ~/.ssh/id_rsa_security

# Adult content context
ssh-keygen -t ed25519 -C "personal" -f ~/.ssh/id_rsa_personal

# Creative context
ssh-keygen -t ed25519 -C "creator" -f ~/.ssh/id_rsa_creative

# Community context
ssh-keygen -t ed25519 -C "organizer" -f ~/.ssh/id_rsa_community
```

## Installation Steps

### Step 1: Copy DAEDALUS

```bash
git clone https://github.com/mazze93/daedalus-switch ~/.daedalus
```

### Step 2: Create Context Directories

```bash
mkdir -p ~/.daedalus/{daedalus,personal,creative,community}

# These are where context-specific data lives
# (future: encrypted volumes)
```

### Step 3: Make Scripts Executable

```bash
chmod +x ~/.daedalus/bin/*
chmod +x ~/.daedalus/lib/*.sh

# Verify
ls -la ~/.daedalus/bin/ | head -5
```

### Step 4: Update Context YAML Files

Edit each context config to match your setup:

```bash
# Edit daedalus context
nano ~/.daedalus/config/daedalus.yaml

# Update these key fields:
# vpn.server: Your preferred Proton VPN server name
# browser.urls_to_open: Your bookmarks/sites
# terminal.ssh_key: Path to your SSH key
# notifications.focus_mode: Your macOS Focus mode name
```

### Step 5: Create Shell Alias

Add to `~/.zshrc`:

```bash
# DAEDALUS Context Switcher
alias daedalus="~/.daedalus/bin/daedalus"

# Optional: Source context environment on startup
# (This enables env vars in new terminals when a context is active)
if [[ -f ~/.daedalus_$(daedalus status 2>/dev/null | grep -oP 'Active Context: \K.*').zshenv ]]; then
    source ~/.daedalus_$(daedalus status 2>/dev/null | grep -oP 'Active Context: \K.*').zshenv
fi
```

Reload shell:
```bash
source ~/.zshrc
```

### Step 6: Set File Permissions

```bash
# Make logs directory restricted
chmod 700 ~/.daedalus/logs
chmod 600 ~/.daedalus/logs/audit.log 2>/dev/null || true

# SSH keys
chmod 400 ~/.ssh/id_rsa_*
```

## Verification

### Test Installation

```bash
# Show help
daedalus help

# Check status
daedalus status

# Run initial audit
daedalus audit
```

### First Context Switch (Dry Run)

```bash
# Switch to daedalus context
daedalus switch daedalus

# Expected output:
# ├─ Loading context configuration...
# ├─ Configuring VPN...
# ├─ Configuring terminal...
# ├─ Configuring browser...
# ├─ Configuring notifications and focus...
# ├─ Configuring file system...
# └─ Context switch complete

# Verify
daedalus status
daedalus log
```

## Troubleshooting Installation

### Scripts Not Executable

```bash
chmod +x ~/.daedalus/bin/*
ls -la ~/.daedalus/bin/daedalus | awk '{print $1}'
# Should show: -rwxr-xr-x (or similar with x flags)
```

### Alias Not Working

```bash
# Check if alias is in .zshrc
grep "alias daedalus" ~/.zshrc

# Reload
source ~/.zshrc

# Test
which daedalus
```

### VPN Connection Fails

```bash
# Verify ProtonVPN CLI works
protonvpn status

# Test manual connection
protonvpn connect --servername "proton-vpn-security"

# Check if credentials are configured
protonvpn config
```

### Focus Mode Not Found

```bash
# Create Focus mode in System Preferences first:
# System Preferences > Focus > + > Create "Security"

# Verify it exists
open "x-apple.systempreferences:com.apple.preference.notifications"
```

## Post-Installation

### Regular Maintenance

1. **Weekly audit**:
   ```bash
   daedalus audit
   ```

2. **Review logs**:
   ```bash
   daedalus log 50
   ```

3. **Update SSH keys** (annually):
   ```bash
   # Regenerate keys
   ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_security
   ```

4. **Test emergency kill** (monthly, in safe environment):
   ```bash
   daedalus emergency-kill
   ```

### Enable Logging to syslog (Optional)

For persistent audit trail in macOS logs:

```bash
# Create a launch agent
cat > ~/Library/LaunchAgents/com.daedalus.audit.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.daedalus.audit</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>-c</string>
        <string>~/.daedalus/bin/_audit.sh >> ~/.daedalus/logs/audit-weekly.log 2>&1</string>
    </array>
    <key>StartCalendarInterval</key>
    <array>
        <dict>
            <key>Day</key>
            <integer>0</integer>
            <key>Hour</key>
            <integer>2</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
    </array>
</dict>
</plist>
EOF

# Load
launchctl load ~/Library/LaunchAgents/com.daedalus.audit.plist
```

---

**Installation complete!** Run `daedalus switch daedalus` to activate your first context.
