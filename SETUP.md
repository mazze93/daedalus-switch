# DAEDALUS Setup Guide

## Quick Start

### 1. Install Proton VPN CLI
```bash
brew install protonvpn-cli
protonvpn config  # Configure credentials
protonvpn list    # View available servers
```

### 2. Copy DAEDALUS
```bash
git clone https://github.com/mazze93/daedalus ~/.daedalus
mkdir -p ~/.daedalus/{daedalus,personal,creative,community}
```

### 3. Make Executable
```bash
chmod +x ~/.daedalus/bin/*
chmod +x ~/.daedalus/lib/*.sh
```

### 4. Add Shell Alias (~/.zshrc)
```bash
alias daedalus="~/.daedalus/bin/daedalus"
source ~/.zshrc
```

### 5. Create macOS Focus Modes
- System Preferences > Focus > + (Create: "Security", "Creator", "Organizing")

### 6. Create SSH Keys Per Context
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_security
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_personal
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_creative
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_community
```

### 7. Edit Context Configs
```bash
nano ~/.daedalus/config/daedalus.yaml
# Update: vpn.server, terminal.ssh_key, browser.urls_to_open, notifications.focus_mode

# Repeat for personal.yaml, creator.yaml, organizer.yaml
```

### 8. Test
```bash
daedalus switch daedalus
daedalus status
daedalus log
```

## Configuration Reference

### VPN
- Provider: proton-vpn
- Server names: Get from `protonvpn list`
- Kill-switch: Recommended enabled

### Browser
- Safari (uses iCloud sync)
- Chrome (create profiles in Settings > Profiles)

### Terminal
- iTerm2 profile: Create in Preferences > Profiles
- SSH keys: Use separate keys per context

### Focus Modes
- Create in System Preferences > Focus
- One per context (Security, Creator, Organizing, etc.)

## Commands

```bash
daedalus switch <context>    # daedalus, personal, creator, organizer
daedalus status              # Show current context
daedalus audit               # Verify OPSEC
daedalus log [lines]         # View switch history
daedalus emergency-kill      # Full reset (requires confirmation)
daedalus help                # Show help
```

## Troubleshooting

### VPN won't connect
```bash
protonvpn status
protonvpn connect --servername "proton-vpn-security"
```

### Focus mode not found
Create it in System Preferences > Focus first

### Browser profile missing
Create in Chrome settings or use Safari's iCloud sync

### SSH key not found
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_security
ssh-add ~/.ssh/id_rsa_security
```

## Verification
```bash
daedalus status   # Check installation
daedalus audit    # Verify OPSEC integrity
daedalus log      # View audit trail
```
