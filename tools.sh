#!/usr/bin/env bash
set -euo pipefail

# Mother of Dragons - Security Toolchain Installer
# Idempotent: checks before installing, safe to re-run

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
skip()  { echo -e "${YELLOW}[skip]${NC} $*"; }
fail()  { echo -e "${RED}[error]${NC} $*"; }

installed=()
skipped=()

# ── Homebrew check ───────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    fail "Homebrew not found. Install it first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi
ok "Homebrew found"

# ── Helper: install brew formula if command is missing ───────────
brew_install() {
    local cmd="$1"
    local formula="$2"
    if command -v "$cmd" &>/dev/null; then
        skip "$formula (already installed)"
        skipped+=("$formula")
    else
        info "Installing $formula..."
        brew install "$formula"
        installed+=("$formula")
    fi
}

# ── Helper: install brew cask if command/app is missing ──────────
brew_cask_install() {
    local cmd="$1"
    local cask="$2"
    if command -v "$cmd" &>/dev/null \
       || brew list --cask "$cask" &>/dev/null 2>&1; then
        skip "$cask (already installed)"
        skipped+=("$cask")
    else
        info "Installing $cask..."
        brew install --cask "$cask"
        installed+=("$cask")
    fi
}

# ── Brew formulas ────────────────────────────────────────────────
echo ""
echo -e "${BLUE}Installing Homebrew packages...${NC}"
brew_install "ast-grep" "ast-grep"
brew_install "tree-sitter" "tree-sitter-cli"
brew_install "r2" "radare2"
brew_install "ffuf" "ffuf"
brew_install "nuclei" "nuclei"

# ── Ghidra (brew formula) ────────────────────────────────────────
echo ""
echo -e "${BLUE}Installing Ghidra...${NC}"
brew_install "ghidraRun" "ghidra"

# ── Python tools via uv ─────────────────────────────────────────
echo ""
echo -e "${BLUE}Installing Python tools...${NC}"
if command -v frida &>/dev/null; then
    skip "frida-tools (already installed)"
    skipped+=("frida-tools")
else
    if command -v uv &>/dev/null; then
        info "Installing frida-tools via uv..."
        uv tool install frida-tools
        installed+=("frida-tools")
    elif command -v pip3 &>/dev/null; then
        info "Installing frida-tools via pip..."
        pip3 install frida-tools
        installed+=("frida-tools")
    else
        fail "Neither uv nor pip3 found. Cannot install frida-tools."
    fi
fi

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Security Toolchain Setup Complete${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

if [[ ${#installed[@]} -gt 0 ]]; then
    echo -e "${GREEN}Installed:${NC}"
    for item in "${installed[@]}"; do
        echo "  + $item"
    done
    echo ""
fi

if [[ ${#skipped[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Already present (skipped):${NC}"
    for item in "${skipped[@]}"; do
        echo "  - $item"
    done
    echo ""
fi
