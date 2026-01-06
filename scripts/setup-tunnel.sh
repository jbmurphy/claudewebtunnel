#!/bin/bash
set -e

# =============================================================================
# Claude Code Web - Cloudflare Tunnel Setup Script
# =============================================================================
# This script installs and configures cloudflared in Claude Code Web
# remote environments. It only runs when CLAUDE_CODE_REMOTE=true.
#
# Required: Set CLOUDFLARE_TUNNEL_TOKEN in your Claude Code Web environment
# =============================================================================

# Only run in remote environments
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
    echo "Skipping tunnel setup - not in remote environment" >&2
    exit 0
fi

echo "=== Setting up Cloudflare Tunnel ===" >&2

# Install cloudflared if not present
if ! command -v cloudflared &> /dev/null; then
    echo "Installing cloudflared..." >&2

    # Download latest cloudflared for Linux amd64
    curl -sL --output /tmp/cloudflared.deb \
        https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

    # Install the package
    sudo dpkg -i /tmp/cloudflared.deb
    rm /tmp/cloudflared.deb

    echo "cloudflared installed successfully" >&2
else
    echo "cloudflared already installed" >&2
fi

# Verify installation
cloudflared --version >&2

# Persist tunnel token in environment if provided
if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo "export CLOUDFLARE_TUNNEL_TOKEN='${CLOUDFLARE_TUNNEL_TOKEN}'" >> "$CLAUDE_ENV_FILE"
    echo "Tunnel token persisted to session environment" >&2
fi

echo "=== Cloudflare Tunnel Ready ===" >&2
echo "" >&2
echo "To start a tunnel:" >&2
echo "  Quick tunnel (no account): cloudflared tunnel --url http://localhost:3000" >&2
echo "  Named tunnel (with token): cloudflared tunnel run --token \$CLOUDFLARE_TUNNEL_TOKEN" >&2
echo "" >&2

exit 0
