#!/bin/bash
# =============================================================================
# Slash Command: /start-tunnel
# =============================================================================
# Starts a Cloudflare named tunnel using TUNNEL_TOKEN
# Equivalent to: cloudflared tunnel run --token $TUNNEL_TOKEN
# =============================================================================

set -e

TUNNEL_LOG="/tmp/cloudflared-tunnel.log"
TUNNEL_PID_FILE="/tmp/cloudflared-tunnel.pid"

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "Error: cloudflared not installed."
    echo "Run the SessionStart hook first or manually install cloudflared."
    exit 1
fi

# Check for tunnel token
if [ -z "${TUNNEL_TOKEN:-}" ]; then
    echo "Error: TUNNEL_TOKEN environment variable not set."
    echo ""
    echo "Set it in Claude Code Web environment settings:"
    echo "  TUNNEL_TOKEN=eyJhIjoiNDk2ZmZhYjR..."
    exit 1
fi

# Check if tunnel is already running
if [ -f "$TUNNEL_PID_FILE" ]; then
    OLD_PID=$(cat "$TUNNEL_PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Tunnel already running (PID: $OLD_PID)"
        echo ""
        echo "Use /tunnel-status to check status"
        echo "Stop with: kill $OLD_PID"
        exit 0
    fi
fi

echo "Starting Cloudflare named tunnel..."
echo ""

# Start tunnel in background (same as docker: cloudflared tunnel run)
cloudflared tunnel run --token "$TUNNEL_TOKEN" > "$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!
echo "$TUNNEL_PID" > "$TUNNEL_PID_FILE"

# Wait a moment for connection
sleep 3

# Check if still running
if kill -0 "$TUNNEL_PID" 2>/dev/null; then
    echo "============================================"
    echo "✓ Tunnel is running!"
    echo ""
    echo "PID: $TUNNEL_PID"
    echo ""
    echo "The tunnel is connected to your Cloudflare"
    echo "configuration. Traffic will route through"
    echo "your configured tunnel hostname."
    echo ""
    echo "To stop: kill $TUNNEL_PID"
    echo "Logs:    cat $TUNNEL_LOG"
    echo "============================================"
else
    echo "Error: Tunnel failed to start"
    echo ""
    echo "Logs:"
    cat "$TUNNEL_LOG"
    exit 1
fi
