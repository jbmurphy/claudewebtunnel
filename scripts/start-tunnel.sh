#!/bin/bash
# =============================================================================
# Start Cloudflare Tunnel
# =============================================================================
# Usage:
#   ./start-tunnel.sh              # Quick tunnel on localhost:3000
#   ./start-tunnel.sh 8080         # Quick tunnel on localhost:8080
#   ./start-tunnel.sh --named      # Named tunnel using CLOUDFLARE_TUNNEL_TOKEN
# =============================================================================

set -e

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "Error: cloudflared not installed. Run setup-tunnel.sh first." >&2
    exit 1
fi

# Parse arguments
if [ "$1" = "--named" ]; then
    # Named tunnel (requires token)
    if [ -z "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
        echo "Error: CLOUDFLARE_TUNNEL_TOKEN environment variable not set" >&2
        echo "Set it in Claude Code Web environment settings" >&2
        exit 1
    fi
    echo "Starting named tunnel..." >&2
    cloudflared tunnel run --token "$CLOUDFLARE_TUNNEL_TOKEN"
else
    # Quick tunnel
    PORT="${1:-3000}"
    echo "Starting quick tunnel for localhost:$PORT..." >&2
    echo "Note: This will generate a random trycloudflare.com URL" >&2
    cloudflared tunnel --url "http://localhost:$PORT"
fi
