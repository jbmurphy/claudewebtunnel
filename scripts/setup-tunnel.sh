#!/bin/bash
set -e

# =============================================================================
# Claude Code Web - Home Network Access Setup
# =============================================================================
# This script configures Claude Code Web remote environments to access
# your home network via Cloudflare Tunnel.
#
# Prerequisites:
# - TUNNEL_TOKEN environment variable set in Claude Code Web
# - Network allowlist configured for *.local.jbmurphy.com
# =============================================================================

TUNNEL_LOG="/tmp/cloudflared-tunnel.log"
TUNNEL_PID_FILE="/tmp/cloudflared-tunnel.pid"

# Only run in remote environments
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
    echo "Skipping setup - not in remote environment" >&2
    exit 0
fi

echo "=== Setting up Home Network Access ===" >&2

# Install cloudflared if not present
if ! command -v cloudflared &> /dev/null; then
    echo "Installing cloudflared..." >&2
    curl -sL --output /tmp/cloudflared.deb \
        https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i /tmp/cloudflared.deb
    rm /tmp/cloudflared.deb
    echo "cloudflared installed successfully" >&2
else
    echo "cloudflared already installed" >&2
fi

# Install useful tools
echo "Installing network tools..." >&2
sudo apt-get update -qq
sudo apt-get install -y -qq curl jq dnsutils 2>/dev/null || true

# Start the tunnel if TUNNEL_TOKEN is set
if [ -n "${TUNNEL_TOKEN:-}" ]; then
    echo "" >&2
    echo "=== Starting Cloudflare Tunnel ===" >&2

    # Start tunnel in background
    cloudflared tunnel run --token "$TUNNEL_TOKEN" > "$TUNNEL_LOG" 2>&1 &
    TUNNEL_PID=$!
    echo "$TUNNEL_PID" > "$TUNNEL_PID_FILE"

    sleep 3

    if kill -0 "$TUNNEL_PID" 2>/dev/null; then
        echo "✓ Tunnel running (PID: $TUNNEL_PID)" >&2
    else
        echo "✗ Tunnel failed to start. Check logs: cat $TUNNEL_LOG" >&2
    fi
else
    echo "" >&2
    echo "⚠ TUNNEL_TOKEN not set - tunnel not started" >&2
    echo "  Set TUNNEL_TOKEN in Claude Code Web environment settings" >&2
    echo "  Or run /start-tunnel manually" >&2
fi

# Test connectivity to home network MCP servers
echo "" >&2
echo "=== Testing Home Network Connectivity ===" >&2

MCP_AGGREGATOR="https://mcp-aggregator.local.jbmurphy.com"

if curl -s --max-time 10 "$MCP_AGGREGATOR/health" > /dev/null 2>&1; then
    echo "✓ MCP Aggregator reachable" >&2
    TOOL_COUNT=$(curl -s --max-time 10 "$MCP_AGGREGATOR/mcp/list_tools" 2>/dev/null | jq 'length' 2>/dev/null || echo "?")
    echo "  Tools available: $TOOL_COUNT" >&2
else
    echo "✗ MCP Aggregator not reachable" >&2
    echo "  Make sure *.local.jbmurphy.com is in your network allowlist" >&2
fi

# Persist environment variables
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    cat >> "$CLAUDE_ENV_FILE" << 'ENVEOF'
export MCP_AGGREGATOR_URL="https://mcp-aggregator.local.jbmurphy.com"
export MCP_EXECUTOR_URL="https://mcp-executor.local.jbmurphy.com"
export MCP_GITHUB_URL="https://mcp-github.local.jbmurphy.com"
export MCP_DOCKER_URL="https://mcp-docker-saturn.local.jbmurphy.com"
ENVEOF
    echo "" >&2
    echo "MCP server URLs persisted to session environment" >&2
fi

echo "" >&2
echo "=== Setup Complete ===" >&2
echo "" >&2

exit 0
