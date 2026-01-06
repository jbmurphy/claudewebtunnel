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
         Cloudflare                 │  │ - aggregator      │  │
         *.local.jbmurphy.com       │  │ - executor        │  │
                                    │  │ - github          │  │
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

### 1. Configure Claude Code Web Network Access

In Claude Code Web environment settings, add to your **network allowlist**:

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

### 3. Start a Session

The SessionStart hook automatically:
- Installs `cloudflared` and network tools
- Tests connectivity to your MCP aggregator
- Sets up environment variables for MCP server URLs

### 4. Test Connectivity

```bash
./scripts/test-connectivity.sh
```

Expected output:
```
=== Testing MCP Server Connectivity ===
Domain: *.local.jbmurphy.com

mcp-aggregator            Aggregator (all tools)    ✓ OK
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
curl -s https://mcp-aggregator.local.jbmurphy.com/mcp/list_tools | jq 'length'

# Call a tool
curl -X POST https://mcp-aggregator.local.jbmurphy.com/mcp/call_tool \
  -H "Content-Type: application/json" \
  -d '{"name": "github_list_repositories", "arguments": {}}'

# Check Docker containers on saturn
curl -X POST https://mcp-aggregator.local.jbmurphy.com/mcp/call_tool \
  -H "Content-Type: application/json" \
  -d '{"name": "docker-saturn_list_containers", "arguments": {}}'
```

## Available MCP Servers

| Server | Description | Tools |
|--------|-------------|-------|
| `mcp-aggregator` | Central hub for all servers | 240+ |
| `mcp-executor` | Code execution sandbox | 8 |
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

See full list at: https://mcp-aggregator.local.jbmurphy.com/mcp/list_tools

## Project Structure

```
claudewebtunnel/
├── .claude/
│   └── settings.json        # SessionStart hook config
├── scripts/
│   ├── setup-tunnel.sh      # Auto-setup on session start
│   ├── start-tunnel.sh      # Start outbound tunnel (optional)
│   └── test-connectivity.sh # Test MCP server connectivity
└── README.md
```

## Environment Variables

Set in Claude Code Web environment settings:

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_REMOTE` | Auto-set to "true" in web environments |
| `CLOUDFLARE_TUNNEL_TOKEN` | Optional: for creating outbound tunnels |

Set by SessionStart hook:

| Variable | Value |
|----------|-------|
| `MCP_AGGREGATOR_URL` | https://mcp-aggregator.local.jbmurphy.com |
| `MCP_EXECUTOR_URL` | https://mcp-executor.local.jbmurphy.com |
| `MCP_GITHUB_URL` | https://mcp-github.local.jbmurphy.com |
| `MCP_DOCKER_URL` | https://mcp-docker-saturn.local.jbmurphy.com |

## Troubleshooting

### "MCP Aggregator not reachable"

1. **Check network allowlist** - Ensure `*.local.jbmurphy.com` is allowed
2. **Verify tunnel is running** - Check cloudflared on your home server
3. **Test DNS** - `dig mcp-aggregator.local.jbmurphy.com`

### "Connection refused"

1. **Check MCP servers are running** - `docker-compose ps` on saturn
2. **Check proxy host** - Verify Nginx Proxy Manager configuration

### Slow connections

- Cloudflare tunnel adds latency (~50-100ms)
- For latency-sensitive operations, consider using mcp-executor which batches calls

## Security

- All traffic encrypted via HTTPS through Cloudflare
- Cloudflare Access can add authentication layer
- MCP servers should have their own auth (tokens, IP restrictions)
- Sandbox is ephemeral - no persistent access after session ends

## License

MIT
