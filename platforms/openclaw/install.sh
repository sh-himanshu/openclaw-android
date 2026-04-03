#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/lib.sh"

echo "=== Installing OpenClaw Platform Package ==="
echo ""

export CPATH="$PREFIX/include/glib-2.0:$PREFIX/lib/glib-2.0/include"

python -c "import yaml" 2>/dev/null || pip install pyyaml -q || true

mkdir -p "$PROJECT_DIR/patches"
cp "$SCRIPT_DIR/../../patches/glibc-compat.js" "$PROJECT_DIR/patches/glibc-compat.js"

cp "$SCRIPT_DIR/../../patches/systemctl" "$PREFIX/bin/systemctl"
chmod +x "$PREFIX/bin/systemctl"

# Clean up existing installation for smooth reinstall
if pnpm list -g openclaw &>/dev/null 2>&1 || [ -d "$PREFIX/lib/node_modules/openclaw" ]; then
    echo "Existing installation detected — cleaning up for reinstall..."
    pnpm remove -g openclaw 2>/dev/null || true
    rm -rf "$PREFIX/lib/node_modules/openclaw" 2>/dev/null || true
    pnpm remove -g clawdhub 2>/dev/null || true
    rm -rf "$PREFIX/lib/node_modules/clawdhub" 2>/dev/null || true
    rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC}   Previous installation cleaned"
fi

echo "Running: pnpm add -g openclaw@latest --ignore-scripts"
echo "This may take several minutes..."
echo ""
pnpm add -g openclaw@latest --ignore-scripts

echo ""
echo -e "${GREEN}[OK]${NC}   OpenClaw installed"

# Fix native bindings broken by --ignore-scripts
OPENCLAW_DIR="$(pnpm root -g)/openclaw"
if [ -d "$OPENCLAW_DIR/node_modules/@snazzah/davey" ]; then
    echo "Installing native bindings for @snazzah/davey..."
    (cd "$OPENCLAW_DIR" && pnpm add @snazzah/davey 2>/dev/null) || true
fi

bash "$SCRIPT_DIR/patches/openclaw-apply-patches.sh"

echo ""
echo "Installing clawdhub (skill manager)..."
if pnpm add -g clawdhub; then
    echo -e "${GREEN}[OK]${NC}   clawdhub installed"
    CLAWHUB_DIR="$(pnpm root -g)/clawdhub"
    if [ -d "$CLAWHUB_DIR" ] && ! (cd "$CLAWHUB_DIR" && node -e "require('undici')" 2>/dev/null); then
        echo "Installing undici dependency for clawdhub..."
        if (cd "$CLAWHUB_DIR" && pnpm add undici); then
            echo -e "${GREEN}[OK]${NC}   undici installed for clawdhub"
        else
            echo -e "${YELLOW}[WARN]${NC} undici installation failed (clawdhub may not work)"
        fi
    fi
else
    echo -e "${YELLOW}[WARN]${NC} clawdhub installation failed (non-critical)"
    echo "       Retry manually: pnpm add -g clawdhub"
fi

mkdir -p "$HOME/.openclaw"

echo ""
echo "Running: openclaw update"
echo "  (This includes building native modules and may take 5-10 minutes)"
echo ""
openclaw update || true
