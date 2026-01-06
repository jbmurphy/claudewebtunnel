# Claude Web Tunnel

Access your home network MCP servers from Claude Code Web via Cloudflare Tunnel.

This project provides SessionStart hooks that configure Claude Code Web to connect to your home network's MCP infrastructure through an existing Cloudflare Tunnel.

## Architecture

```
┌─────────────────────────┐         ┌─────────────────────────┐
│   Claude Code Web       │         │    Home Network         │
│   (Remote Sandbox)      │         │    192.168.11.0/24      │
│                         │         │                         │
│  ┌───────────────────┐  │         │  ┌───────────────────┐  │
│  │ Your Session      │  │ HTTPS   │  │ cloudflared       │  │
│  │                   │──┼────────►│  │ (tunnel daemon)   │  │
│  │ curl, scripts     │  │         │  └─────────┬─────────┘  │
│  └───────────────────┘  │         │            │            │
│                         │         │            ▼            │
└─────────────────────────┘         │  ┌───────────────────┐  │
                                    │  │ MCP Servers       │  │
         Cloudflare                 │  │ - executor        │  │
         *.local.jbmurphy.com       │  │ - github          │  │
                                    │  │ - docker          │  │
                                    │  │ - 30+ more...     │  │
                                    │  └───────────────────┘  │
                                    └─────────────────────────┘
```

## Prerequisites

1. **Cloudflare Tunnel running on your home network** - `cloudflared` daemon running on a server (e.g., saturn)
2. **DNS configured** - `*.local.jbmurphy.com` pointing to your Cloudflare tunnel
3. **MCP servers running** - Your MCP infrastructure via docker-compose

## Quick Start

### 1. Configure Claude Code Web Environment

In Claude Code Web environment settings, set:

**Environment Variables:**
```
TUNNEL_TOKEN=eyJhIjoiNDk2ZmZhYjRmYTU2NDkwOWRlZmViOTcxZTA1ZDgzZGQiLC...
```

**Network Allowlist:**
```
*.local.jbmurphy.com
*.jbmurphy.com
github.com
```

Or set network access to **"Full"** for unrestricted access.

### 2. Clone This Repo in Claude Code Web

```bash
git clone https://github.com/jbmurphy/claudewebtunnel.git
cd claudewebtunnel
```

### 3. Session Auto-Start

The SessionStart hook automatically:
- Installs `cloudflared` and network tools
- **Starts the tunnel** using your `TUNNEL_TOKEN`
- Tests connectivity to MCP Executor
- Sets up environment variables for MCP server URLs

You'll see output like:
```
=== Setting up Home Network Access ===
cloudflared installed successfully
Installing network tools...

=== Starting Cloudflare Tunnel ===
✓ Tunnel running (PID: 12345)

=== Testing Home Network Connectivity ===
✓ MCP Executor reachable
  Tools available: 8

=== Setup Complete ===
```

## Helper Scripts

Run these scripts directly (slash commands don't work in Claude Code Web):

| Script | Purpose |
|--------|---------|
| `./scripts/tunnel-skill.sh` | Manually restart tunnel if it dies |
| `./scripts/tunnel-status.sh` | Check if tunnel is running |
| `./scripts/test-connectivity.sh` | Test all MCP server connectivity |

### Test Connectivity

```bash
./scripts/test-connectivity.sh
```

Expected output:
```
=== Testing MCP Server Connectivity ===
Domain: *.local.jbmurphy.com

mcp-executor              Code Executor             ✓ OK
mcp-github                GitHub                    ✓ OK
mcp-repository            Git/Filesystem            ✓ OK
mcp-docker-saturn         Docker                    ✓ OK
...

=== Summary ===
Passed: 12
Failed: 0

All MCP servers are reachable!
```

## Using MCP Servers from Claude Code Web

Once connected, you can call MCP tools directly:

```bash
# List all available tools
curl -s https://mcp-executor.local.jbmurphy.com/mcp/list_tools | jq 'length'

# Call a tool
curl -X POST https://mcp-executor.local.jbmurphy.com/mcp/call_tool \
  -H "Content-Type: application/json" \
  -d '{"name": "execute_code", "arguments": {"code": "print(1+1)", "language": "python"}}'
```

## Available MCP Servers

| Server | Description | Tools |
|--------|-------------|-------|
| `mcp-executor` | Code execution sandbox | 8 |
| `mcp-aggregator` | Central hub for all servers | 240+ |
| `mcp-github` | GitHub repository management | 4 |
| `mcp-repository` | Local git + filesystem | 22 |
| `mcp-docker-saturn` | Full Docker management | 38 |
| `mcp-technitium` | DNS management | 5 |
| `mcp-proxy` | Nginx Proxy Manager | 10 |
| `mcp-spotify` | Spotify playback | 14 |
| `mcp-homeassistant` | Home Assistant | 10 |
| `mcp-browser` | Browser automation | 35 |
| `mcp-mattermost` | Mattermost admin | 16 |
| `mcp-cli` | Network diagnostics | 11 |

## Project Structure

```
claudewebtunnel/
├── .claude/
│   └── settings.json        # SessionStart hook config
├── scripts/
│   ├── setup-tunnel.sh      # Auto-runs on session start
│   ├── tunnel-skill.sh      # Manual tunnel restart
│   ├── tunnel-status.sh     # Check tunnel status
│   └── test-connectivity.sh # Test MCP server connectivity
└── README.md
```

## Environment Variables

**Set in Claude Code Web environment settings:**

| Variable | Description |
|----------|-------------|
| `TUNNEL_TOKEN` | Your Cloudflare tunnel token (required) |
| `CLAUDE_CODE_REMOTE` | Auto-set to "true" in web environments |

**Set by SessionStart hook:**

| Variable | Value |
|----------|-------|
| `MCP_EXECUTOR_URL` | https://mcp-executor.local.jbmurphy.com |
| `MCP_AGGREGATOR_URL` | https://mcp-aggregator.local.jbmurphy.com |
| `MCP_GITHUB_URL` | https://mcp-github.local.jbmurphy.com |
| `MCP_DOCKER_URL` | https://mcp-docker-saturn.local.jbmurphy.com |

## Troubleshooting

### "MCP Executor not reachable"

1. **Check network allowlist** - Ensure `*.local.jbmurphy.com` is allowed
2. **Verify tunnel is running** - `./scripts/tunnel-status.sh`
3. **Check tunnel logs** - `cat /tmp/cloudflared-tunnel.log`
4. **Test DNS** - `dig mcp-executor.local.jbmurphy.com`

### "TUNNEL_TOKEN not set"

Set `TUNNEL_TOKEN` in Claude Code Web environment settings before starting a session.

### "Tunnel failed to start"

1. Check logs: `cat /tmp/cloudflared-tunnel.log`
2. Verify your tunnel token is valid in Cloudflare dashboard
3. Try manual restart: `./scripts/tunnel-skill.sh`

### Slow connections

- Cloudflare tunnel adds latency (~50-100ms)
- Use mcp-executor for batched operations to reduce round trips

## Security

- All traffic encrypted via HTTPS through Cloudflare
- Cloudflare Access can add authentication layer
- MCP servers should have their own auth (tokens, IP restrictions)
- Sandbox is ephemeral - no persistent access after session ends

## License

MIT
