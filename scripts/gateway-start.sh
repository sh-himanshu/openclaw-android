#!/usr/bin/env bash
# gateway-start.sh - Start OpenClaw gateway with HTTPS LAN dashboard access via socat
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SOCAT_PORT=18790
SOCAT_PID=""
CERT_DIR="$HOME/.openclaw-android/certs"
CERT_FILE="$CERT_DIR/cert.pem"
KEY_FILE="$CERT_DIR/key.pem"

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

# Check openssl
if ! command -v openssl &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} openssl not found. Install it with: pkg install openssl-tool"
    exit 1
fi

# Generate self-signed certificate if not exists
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Generating self-signed certificate..."
    mkdir -p "$CERT_DIR"
    openssl req -x509 -newkey rsa:2048 \
        -keyout "$KEY_FILE" -out "$CERT_FILE" \
        -days 365 -nodes -subj '/CN=openclaw' 2>/dev/null
    echo -e "${GREEN}[OK]${NC}   Certificate generated (valid for 365 days)"
else
    echo -e "${GREEN}[OK]${NC}   Certificate found"
fi

# Get phone's Wi-Fi IP
# Note: `ifconfig wlan0` fails in Termux (Permission denied), but `ifconfig` (all) works
PHONE_IP=""
if command -v ifconfig &>/dev/null; then
    PHONE_IP=$(ifconfig 2>/dev/null | grep -A1 'wlan0' | grep 'inet ' | awk '{print $2}' | head -1) || true
fi

# Get dashboard URL (extract token from openclaw dashboard output)
DASHBOARD_TOKEN=""
DASHBOARD_OUTPUT=$(openclaw dashboard 2>/dev/null) || true
if [ -n "$DASHBOARD_OUTPUT" ]; then
    DASHBOARD_TOKEN=$(echo "$DASHBOARD_OUTPUT" | sed -n 's/.*#token=\([a-f0-9]*\).*/\1/p' | head -1) || true
fi

# Kill any existing socat processes
pkill -9 socat 2>/dev/null || true
sleep 0.5

# Start socat with HTTPS in background
socat OPENSSL-LISTEN:${SOCAT_PORT},fork,reuseaddr,cert=${CERT_FILE},key=${KEY_FILE},verify=0 TCP:127.0.0.1:18789 &
SOCAT_PID=$!
sleep 0.5

# Check if socat started successfully
if ! kill -0 "$SOCAT_PID" 2>/dev/null; then
    echo -e "${RED}[FAIL]${NC} socat failed to start. Port ${SOCAT_PORT} may be in use."
    echo "       Try: pkill -9 socat; oca-gateway"
    SOCAT_PID=""
    exit 1
fi

echo -e "${GREEN}[OK]${NC}   socat HTTPS started (port ${SOCAT_PORT} → 18789)"
echo ""

# Display PC Dashboard Access info
show_dashboard_info() {
    if [ -n "$PHONE_IP" ] && [ -n "$DASHBOARD_TOKEN" ]; then
        echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}  PC Dashboard Access (HTTPS)${NC}"
        echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "  Open this URL in your PC browser and bookmark it:"
        echo ""
        echo -e "  ${GREEN}https://${PHONE_IP}:${SOCAT_PORT}/#token=${DASHBOARD_TOKEN}${NC}"
        echo ""
        echo -e "  Your browser will show a certificate warning on first"
        echo -e "  visit — click ${BOLD}Advanced${NC} → ${BOLD}Proceed${NC} to accept it."
        echo ""
        echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    elif [ -n "$PHONE_IP" ]; then
        echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}  PC Dashboard Access (HTTPS)${NC}"
        echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "  After the gateway starts, look for the Dashboard URL"
        echo -e "  in the output below. Replace the URL like this:"
        echo ""
        echo -e "  ${YELLOW}Before:${NC} http://127.0.0.1:18789/#token=YOUR_TOKEN"
        echo -e "  ${GREEN}After:${NC}  https://${PHONE_IP}:${SOCAT_PORT}/#token=YOUR_TOKEN"
        echo ""
        echo -e "  Your browser will show a certificate warning on first"
        echo -e "  visit — click ${BOLD}Advanced${NC} → ${BOLD}Proceed${NC} to accept it."
        echo ""
        echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    else
        echo -e "${YELLOW}[WARN]${NC} Could not detect Wi-Fi IP. Run 'ifconfig' to find it."
    fi
}

show_dashboard_info

# Check if gateway is already running
GATEWAY_OUTPUT=$(openclaw gateway 2>&1) || true

if echo "$GATEWAY_OUTPUT" | grep -q "already running"; then
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Gateway is already running."
    echo ""
    echo "To restart: openclaw gateway stop && oca-gateway"
    echo "Press Ctrl+C to stop socat."
    echo ""
    # Keep socat alive until user presses Ctrl+C
    wait "$SOCAT_PID" 2>/dev/null || true
else
    echo ""
    echo "$GATEWAY_OUTPUT"
fi
