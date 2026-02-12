#!/usr/bin/env bash
set -euo pipefail

# Dotfiles installer — idempotent, safe to re-run

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/eilonc-pillar/dotfiles.git"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

installed=()
skipped=()

info()  { echo -e "${BLUE}[info]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[skip]${NC} $*"; }
err()   { echo -e "${RED}[error]${NC} $*"; }

backup_file() {
  local target="$1"
  if [[ -f "$target" ]]; then
    cp "$target" "${target}${BACKUP_SUFFIX}"
    info "Backed up $target"
  fi
}

# ── Step 1: macOS check ────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  err "This installer is macOS-only."
  exit 1
fi

# ── Step 2: Homebrew ───────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  installed+=("homebrew")
else
  warn "Homebrew already installed"
  skipped+=("homebrew")
fi

# ── Step 3: Brew packages ─────────────────────────────────────────
PACKAGES=(
  eza bat ripgrep fd zoxide fzf starship tmux git-delta
  doggo glow
  gitleaks semgrep trivy httpie mitmproxy
  gnupg yq
)

info "Installing brew packages..."
for pkg in "${PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    skipped+=("$pkg")
  else
    brew install "$pkg"
    installed+=("$pkg")
  fi
done

# ── Step 4: Font ──────────────────────────────────────────────────
FONT_CASK="font-jetbrains-mono-nerd-font"
if brew list --cask "$FONT_CASK" &>/dev/null; then
  warn "JetBrains Mono Nerd Font already installed"
  skipped+=("$FONT_CASK")
else
  info "Installing JetBrains Mono Nerd Font..."
  brew install --cask "$FONT_CASK"
  installed+=("$FONT_CASK")
fi

# ── Step 5: Clone/update dotfiles to ~/.dotfiles ──────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "$DOTFILES_DIR" ]]; then
  # If ~/.dotfiles is already a symlink to this repo, skip
  if [[ -L "$DOTFILES_DIR" ]]; then
    warn "$HOME/.dotfiles symlink already exists"
    skipped+=("dotfiles-link")
  else
    info "Updating ~/.dotfiles..."
    git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not pull ~/.dotfiles (not a git repo or has conflicts)"
    skipped+=("dotfiles-link")
  fi
else
  # If running from the cloned repo, symlink; otherwise clone
  if [[ -f "$SCRIPT_DIR/configs/zshrc" ]]; then
    info "Symlinking $SCRIPT_DIR -> ~/.dotfiles"
    ln -s "$SCRIPT_DIR" "$DOTFILES_DIR"
    installed+=("dotfiles-link")
  else
    info "Cloning dotfiles to ~/.dotfiles..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
    installed+=("dotfiles-clone")
  fi
fi

# ── Step 6: Copy configs ─────────────────────────────────────────
# Ghostty
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_DIR"
backup_file "$GHOSTTY_DIR/config"
cp "$DOTFILES_DIR/configs/ghostty/config" "$GHOSTTY_DIR/config"
ok "Ghostty config installed"

# Starship
mkdir -p "$HOME/.config"
backup_file "$HOME/.config/starship.toml"
cp "$DOTFILES_DIR/configs/starship.toml" "$HOME/.config/starship.toml"
ok "Starship config installed"

# tmux
backup_file "$HOME/.tmux.conf"
cp "$DOTFILES_DIR/configs/tmux.conf" "$HOME/.tmux.conf"
ok "tmux config installed"

# ── Step 7: Source zshrc snippet ──────────────────────────────────
# shellcheck disable=SC2016
SOURCE_LINE='source "$HOME/.dotfiles/configs/zshrc"'
if [[ -f "$HOME/.zshrc" ]] && command grep -qF ".dotfiles/configs/zshrc" "$HOME/.zshrc"; then
  warn "zshrc source line already present"
  skipped+=("zshrc-source")
else
  info "Adding source line to ~/.zshrc"
  {
    echo ""
    echo "# Dotfiles: modern CLI aliases and tools"
    echo "$SOURCE_LINE"
  } >> "$HOME/.zshrc"
  installed+=("zshrc-source")
fi

# ── Step 8: Git delta config ─────────────────────────────────────
info "Configuring git delta..."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global delta.syntax-theme "Catppuccin Mocha"
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
ok "Git delta configured"

# ── Step 9: TPM ──────────────────────────────────────────────────
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
  warn "TPM already installed"
  skipped+=("tpm")
else
  info "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  installed+=("tpm")
fi

# ── Step 10: Bat Catppuccin theme ─────────────────────────────────
BAT_THEMES_DIR="$(bat --config-dir)/themes"
MOCHA_THEME="$BAT_THEMES_DIR/Catppuccin Mocha.tmTheme"
if [[ -f "$MOCHA_THEME" ]]; then
  warn "Bat Catppuccin theme already installed"
  skipped+=("bat-theme")
else
  info "Installing bat Catppuccin Mocha theme..."
  mkdir -p "$BAT_THEMES_DIR"
  curl -fsSL -o "$MOCHA_THEME" \
    "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"
  bat cache --build
  installed+=("bat-theme")
fi

# ── Step 11: Git hooks path ──────────────────────────────────────
info "Setting global git hooks path..."
git config --global core.hooksPath "$DOTFILES_DIR/hooks"
chmod +x "$DOTFILES_DIR/hooks/pre-push"
ok "Git hooks configured (gitleaks pre-push)"

# ── Step 12: Claude Code config (optional) ───────────────────────
CLAUDE_CONFIG_REPO="https://github.com/trailofbits/claude-code-config.git"

if command -v claude &>/dev/null; then
  echo ""
  echo -e "${BLUE}[optional]${NC} Claude Code detected."
  echo "  Install opinionated Claude Code config? (settings, CLAUDE.md, MCP servers, commands)"
  echo "  Source: $CLAUDE_CONFIG_REPO"
  echo ""
  read -rp "  Install Claude Code config? [y/N] " answer
  if [[ "${answer,,}" == "y" ]]; then
    info "To install, run inside Claude Code:"
    echo ""
    echo "    /trailofbits:config"
    echo ""
    echo "  Or clone and review manually:"
    echo "    git clone $CLAUDE_CONFIG_REPO ~/Documents/GitHub/claude-code-config"
    echo ""
    skipped+=("claude-code-config (manual)")
  else
    warn "Claude Code config (declined)"
    skipped+=("claude-code-config")
  fi
else
  info "Claude Code not found — skipping config suggestion"
  info "Install: https://docs.anthropic.com/en/docs/claude-code"
fi

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo -e "${GREEN}  Dotfiles installation complete${NC}"
echo -e "${GREEN}══════════════════════════════════════${NC}"
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

echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Open tmux and press Ctrl+a then I to install tmux plugins"
echo "  3. Set Ghostty as your default terminal in System Settings"
echo ""
