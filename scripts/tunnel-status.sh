#!/bin/bash
# =============================================================================
# Slash Command: /tunnel-status
# =============================================================================
# Check tunnel status and show URL
# =============================================================================

TUNNEL_PID_FILE="/tmp/cloudflared-tunnel.pid"
TUNNEL_URL_FILE="/tmp/cloudflared-tunnel-url.txt"
TUNNEL_LOG="/tmp/cloudflared-tunnel.log"

echo "=== Cloudflare Tunnel Status ==="
echo ""

# Check if PID file exists
if [ ! -f "$TUNNEL_PID_FILE" ]; then
    echo "Status: Not running"
    echo ""
    echo "Start a tunnel with: /start-tunnel [port]"
    exit 0
fi

PID=$(cat "$TUNNEL_PID_FILE")

# Check if process is running
if kill -0 "$PID" 2>/dev/null; then
    echo "Status: Running"
    echo "PID:    $PID"

    # Show URL if available
    if [ -f "$TUNNEL_URL_FILE" ]; then
        URL=$(cat "$TUNNEL_URL_FILE")
        echo "URL:    $URL"
    else
        # Try to get from logs
        if [ -f "$TUNNEL_LOG" ]; then
            URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$TUNNEL_LOG" 2>/dev/null | head -1)
            if [ -n "$URL" ]; then
                echo "URL:    $URL"
            fi
        fi
    fi

    echo ""
    echo "To stop: kill $PID"
else
    echo "Status: Stopped (stale PID file)"
    rm -f "$TUNNEL_PID_FILE" "$TUNNEL_URL_FILE"
    echo ""
    echo "Start a tunnel with: /start-tunnel [port]"
fi
