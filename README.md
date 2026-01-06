# Claude Web Tunnel

Cloudflare Tunnel setup for Claude Code Web remote environments.

This project provides SessionStart hooks that automatically install and configure `cloudflared` when you open a project in Claude Code Web, allowing you to expose local services running in the sandbox to the internet.

## Features

- Automatic `cloudflared` installation via SessionStart hook
- Only runs in remote environments (checks `CLAUDE_CODE_REMOTE`)
- Support for both quick tunnels and named tunnels
- Helper scripts for easy tunnel management

## Quick Start

### 1. Clone this repo in Claude Code Web

```bash
git clone https://github.com/jbmurphy/claudewebtunnel.git
cd claudewebtunnel
```

### 2. Configure Network Access

In the Claude Code Web interface:
1. Click the environment settings
2. Add these domains to your network allowlist (or set to "Full" access):
   - `region1.v2.argotunnel.com`
   - `region2.v2.argotunnel.com`
   - `api.cloudflare.com`
   - `update.argotunnel.com`
   - `*.cfargotunnel.com`
   - `github.com` (for downloading cloudflared)

### 3. Start a Session

The SessionStart hook will automatically:
- Detect the remote environment
- Install `cloudflared` if not present
- Configure the tunnel token (if provided)

### 4. Start a Tunnel

**Quick tunnel** (no Cloudflare account needed):
```bash
./scripts/start-tunnel.sh 3000
```

**Named tunnel** (requires Cloudflare account):
```bash
# Set your tunnel token in Claude Code Web environment settings first
./scripts/start-tunnel.sh --named
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_REMOTE` | Automatically set to "true" in web environments |
| `CLOUDFLARE_TUNNEL_TOKEN` | Your Cloudflare tunnel token (optional, for named tunnels) |
| `CLAUDE_ENV_FILE` | Path to persist environment variables across the session |

## Use Cases

- **Webhook Testing**: Expose your dev server to receive webhooks from Stripe, GitHub, etc.
- **Preview Sharing**: Share a live preview of your work with teammates
- **API Development**: Test your API from external services
- **Local Services**: Access internal services via Cloudflare Access

## Project Structure

```
claudewebtunnel/
├── .claude/
│   └── settings.json      # Hook configuration
├── scripts/
│   ├── setup-tunnel.sh    # SessionStart hook script
│   └── start-tunnel.sh    # Helper to start tunnels
└── README.md
```

## How It Works

1. When you open this project in Claude Code Web, the SessionStart hook fires
2. The hook checks `CLAUDE_CODE_REMOTE` - if not "true", it exits (local environment)
3. If in remote environment, it downloads and installs `cloudflared`
4. You can then start tunnels to expose any port in the sandbox

## Security Considerations

- Quick tunnels generate random URLs that are publicly accessible
- Named tunnels require authentication via your Cloudflare account
- The sandbox is ephemeral - tunnels only exist while the session is active
- Never expose sensitive services without proper authentication

## Requirements

- Claude Code Web (Claude Code on the Web)
- Network access configured for Cloudflare domains
- For named tunnels: Cloudflare account and tunnel token

## License

MIT
