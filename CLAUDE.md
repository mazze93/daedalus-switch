# DAEDALUS — Claude Context

Identity & context switcher. One command atomically switches VPN, terminal, browser, notifications,
and filesystem visibility across multiple legitimate identities. Privacy-first, ADHD-accessible.

## Stack
- **Language**: zsh shell scripts
- **Structure**: `bin/` (executables), `config/` (YAML per context), `lib/` (logging/config/validation), `logs/`
- **Install path**: `~/.daedalus/`

## Contexts
| Context | Purpose |
|---------|---------|
| `daedalus` | Security professional |
| `ryan` | Adult content creator |
| `creator` | Creative work |
| `organizer` | Community leadership |

## Key Commands
```bash
daedalus switch <context>   # Full atomic context switch
daedalus status             # Current context + system state
daedalus audit              # OPSEC integrity check
daedalus log [n]            # Audit trail (default 20 lines)
daedalus emergency-kill     # Full reset (requires confirmation)
```

## Switch Sequence
VPN (ProtonVPN CLI) → iTerm2 profile + SSH key + env vars → Safari/Chrome + URLs → macOS Focus mode → filesystem hide/show

## Security Standards
- VPN kill-switch per context; SSH keys isolated (400 perms); audit log (600 perms)
- No telemetry, no cloud, no third-party data
- SOGI data: encryption-by-default

## Design Rules
- Fail-safe: every step logs to audit trail; errors are detailed and non-blocking
- ADHD-accessible: one command = complete switch, minimal decision overhead
- Locally-audited: bash-native, auditable, portable
