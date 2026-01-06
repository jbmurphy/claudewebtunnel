#!/bin/bash
# =============================================================================
# Test Connectivity to Home Network MCP Servers
# =============================================================================

set -e

BASE_DOMAIN="local.jbmurphy.com"

# MCP servers to test (from CLAUDE.md)
MCP_SERVERS=(
    "mcp-aggregator:Aggregator (all tools)"
    "mcp-executor:Code Executor"
    "mcp-github:GitHub"
    "mcp-repository:Git/Filesystem"
    "mcp-docker-saturn:Docker"
    "mcp-technitium:DNS"
    "mcp-proxy:Nginx Proxy"
    "mcp-mattermost:Mattermost"
    "mcp-spotify:Spotify"
    "mcp-homeassistant:Home Assistant"
    "mcp-browser:Browser Automation"
    "mcp-cli:CLI Tools"
)

echo "=== Testing MCP Server Connectivity ==="
echo "Domain: *.$BASE_DOMAIN"
echo ""

PASSED=0
FAILED=0

for server_info in "${MCP_SERVERS[@]}"; do
    server="${server_info%%:*}"
    description="${server_info#*:}"
    url="https://${server}.${BASE_DOMAIN}"

    printf "%-25s %-25s " "$server" "$description"

    if curl -s --max-time 5 "$url/health" > /dev/null 2>&1; then
        echo "✓ OK"
        ((PASSED++))
    else
        echo "✗ FAILED"
        ((FAILED++))
    fi
done

echo ""
echo "=== Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "Some servers are not reachable."
    echo "Make sure:"
    echo "  1. Cloudflare tunnel is running on your home network"
    echo "  2. *.local.jbmurphy.com is in Claude Code Web network allowlist"
    echo "  3. The MCP servers are running (docker-compose up -d)"
    exit 1
fi

echo "All MCP servers are reachable!"

# Show aggregator tool count
echo ""
echo "=== Aggregator Tools ==="
TOOLS=$(curl -s --max-time 10 "https://mcp-aggregator.${BASE_DOMAIN}/mcp/list_tools" 2>/dev/null)
if [ -n "$TOOLS" ]; then
    TOOL_COUNT=$(echo "$TOOLS" | jq 'length' 2>/dev/null || echo "?")
    echo "Total tools available: $TOOL_COUNT"

    # Show servers
    echo ""
    echo "Servers:"
    echo "$TOOLS" | jq -r '.[].name' 2>/dev/null | sed 's/_.*$//' | sort -u | head -20
fi
