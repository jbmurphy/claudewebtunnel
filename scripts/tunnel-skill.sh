#!/bin/bash
# =============================================================================
# Slash Command: /start-tunnel
# =============================================================================
# Starts a Cloudflare quick tunnel and captures the public URL
# Usage: /start-tunnel [port]
# =============================================================================

set -e

PORT="${1:-3000}"
TUNNEL_LOG="/tmp/cloudflared-tunnel.log"
TUNNEL_PID_FILE="/tmp/cloudflared-tunnel.pid"

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "Error: cloudflared not installed."
    echo "Run the SessionStart hook first or manually install cloudflared."
    exit 1
fi

# Check if tunnel is already running
if [ -f "$TUNNEL_PID_FILE" ]; then
    OLD_PID=$(cat "$TUNNEL_PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Tunnel already running (PID: $OLD_PID)"
        echo "Use /tunnel-status to see the URL"
        echo "Kill it with: kill $OLD_PID"
        exit 0
    fi
fi

echo "Starting Cloudflare tunnel for localhost:$PORT..."
echo ""

# Start tunnel in background and capture output
cloudflared tunnel --url "http://localhost:$PORT" > "$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!
echo "$TUNNEL_PID" > "$TUNNEL_PID_FILE"

echo "Tunnel starting (PID: $TUNNEL_PID)..."
echo "Waiting for URL..."
echo ""

# Wait for URL to appear in logs (up to 30 seconds)
for i in {1..30}; do
    if grep -q "trycloudflare.com" "$TUNNEL_LOG" 2>/dev/null; then
        TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$TUNNEL_LOG" | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            echo "============================================"
            echo "✓ Tunnel is running!"
            echo ""
            echo "Public URL: $TUNNEL_URL"
            echo "Local:      http://localhost:$PORT"
            echo "PID:        $TUNNEL_PID"
            echo ""
            echo "To stop: kill $TUNNEL_PID"
            echo "============================================"

            # Save URL for status command
            echo "$TUNNEL_URL" > /tmp/cloudflared-tunnel-url.txt
            exit 0
        fi
    fi
    sleep 1
done

# If we get here, URL wasn't found
echo "Tunnel started but URL not captured yet."
echo "Check logs: cat $TUNNEL_LOG"
echo "PID: $TUNNEL_PID"
