#!/usr/bin/env bash
# bootstrap.sh - Download and run OpenClaw on Android installer
# Usage: curl -sL https://raw.githubusercontent.com/AidanPark/openclaw-android/main/bootstrap.sh | bash
set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/AidanPark/openclaw-android/main"
INSTALL_DIR="$HOME/.openclaw-android/installer"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}OpenClaw on Android - Bootstrap${NC}"
echo ""

# Ensure curl is available
if ! command -v curl &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} curl not found. Install it with: pkg install curl"
    exit 1
fi

# Create installer directory structure
mkdir -p "$INSTALL_DIR"/{patches,scripts,tests}

# File list to download
FILES=(
    "install.sh"
    "uninstall.sh"
    "patches/bionic-compat.js"
    "patches/patch-paths.sh"
    "patches/apply-patches.sh"
    "scripts/check-env.sh"
    "scripts/install-deps.sh"
    "scripts/setup-paths.sh"
    "scripts/setup-env.sh"
    "scripts/build-sharp.sh"
    "tests/verify-install.sh"
    "update.sh"
)

# Download all files
echo "Downloading installer files..."
FAILED=0
for f in "${FILES[@]}"; do
    if curl -sfL "$REPO_BASE/$f" -o "$INSTALL_DIR/$f"; then
        echo -e "  ${GREEN}[OK]${NC} $f"
    else
        echo -e "  ${RED}[FAIL]${NC} $f"
        FAILED=$((FAILED + 1))
    fi
done

if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed to download $FAILED file(s). Check your internet connection.${NC}"
    rm -rf "$INSTALL_DIR"
    exit 1
fi

# Make scripts executable
chmod +x "$INSTALL_DIR"/*.sh "$INSTALL_DIR"/patches/*.sh "$INSTALL_DIR"/scripts/*.sh "$INSTALL_DIR"/tests/*.sh

echo ""
echo "Running installer..."
echo ""

# Run installer
bash "$INSTALL_DIR/install.sh"

# Keep uninstall.sh and update.sh accessible, clean up the rest
cp "$INSTALL_DIR/uninstall.sh" "$HOME/.openclaw-android/uninstall.sh"
chmod +x "$HOME/.openclaw-android/uninstall.sh"
cp "$INSTALL_DIR/update.sh" "$HOME/.openclaw-android/update.sh"
chmod +x "$HOME/.openclaw-android/update.sh"
rm -rf "$INSTALL_DIR"

echo "Uninstaller saved at: ~/.openclaw-android/uninstall.sh"
echo "Updater saved at:     ~/.openclaw-android/update.sh"
