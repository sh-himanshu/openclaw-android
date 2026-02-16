#!/usr/bin/env bash
# gateway-start.sh - Start OpenClaw gateway with LAN dashboard access via socat
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SOCAT_PORT=18790
SOCAT_PID=""

cleanup() {
    if [ -n "$SOCAT_PID" ] && kill -0 "$SOCAT_PID" 2>/dev/null; then
        kill "$SOCAT_PID" 2>/dev/null
        echo ""
        echo -e "${GREEN}[OK]${NC}   socat stopped"
    fi
}

trap cleanup EXIT

# Check socat
if ! command -v socat &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} socat not found. Install it with: pkg install socat"
    exit 1
fi

# Get phone's Wi-Fi IP
PHONE_IP=""
if command -v ifconfig &>/dev/null; then
    PHONE_IP=$(ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -1) || true
fi

# Start socat in background
# Kill any existing socat on the same port
if command -v fuser &>/dev/null; then
    fuser -k "${SOCAT_PORT}/tcp" 2>/dev/null || true
fi

socat TCP-LISTEN:${SOCAT_PORT},fork,bind=0.0.0.0,reuseaddr TCP:127.0.0.1:18789 &
SOCAT_PID=$!

echo -e "${GREEN}[OK]${NC}   socat started (port ${SOCAT_PORT} → 18789)"
echo ""

if [ -n "$PHONE_IP" ]; then
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  PC Dashboard Access${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  After the gateway starts, look for the Dashboard URL"
    echo -e "  in the output below. Replace the URL like this:"
    echo ""
    echo -e "  ${YELLOW}Before:${NC} http://127.0.0.1:18789/#token=YOUR_TOKEN"
    echo -e "  ${GREEN}After:${NC}  http://${PHONE_IP}:${SOCAT_PORT}/#token=YOUR_TOKEN"
    echo ""
    echo -e "  Open the ${GREEN}After${NC} URL in your PC browser and bookmark it."
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
else
    echo -e "${YELLOW}[WARN]${NC} Could not detect Wi-Fi IP. Run 'ifconfig wlan0' to find it."
fi

echo ""
echo "Starting OpenClaw gateway..."
echo ""

# Start gateway (foreground — Ctrl+C stops both gateway and socat)
openclaw gateway
