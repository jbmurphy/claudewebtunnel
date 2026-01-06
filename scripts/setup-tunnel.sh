#!/bin/bash
set -e

# =============================================================================
# Claude Code Web - Home Network Access Setup
# =============================================================================
# This script configures Claude Code Web remote environments to access
# your home network via Cloudflare Tunnel.
#
# Prerequisites:
# - Cloudflare Tunnel running on your home network
# - *.local.jbmurphy.com domains proxied through Cloudflare
# - Network allowlist configured in Claude Code Web settings
# =============================================================================

# Only run in remote environments
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
    echo "Skipping setup - not in remote environment" >&2
    exit 0
fi

echo "=== Setting up Home Network Access ===" >&2

# Install cloudflared if not present (for future WARP/access features)
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

# Test connectivity to home network MCP servers
echo "" >&2
echo "=== Testing Home Network Connectivity ===" >&2

MCP_AGGREGATOR="https://mcp-aggregator.local.jbmurphy.com"

if curl -s --max-time 10 "$MCP_AGGREGATOR/health" > /dev/null 2>&1; then
    echo "✓ MCP Aggregator reachable" >&2

    # Get tool count
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
echo "Run './scripts/test-connectivity.sh' to verify all MCP servers" >&2
echo "" >&2

exit 0
