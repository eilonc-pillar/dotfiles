# dotfiles

Modern macOS terminal stack: Ghostty + Catppuccin, tmux, starship prompt, and a curated set of CLI replacements and security tools.

## Quick start

```bash
git clone https://github.com/eilonc-pillar/dotfiles.git ~/Documents/GitHub/dotfiles
cd ~/Documents/GitHub/dotfiles
./install.sh
```

The installer is idempotent — safe to re-run at any time.

### Claude Code

If you use [Claude Code](https://docs.anthropic.com/en/docs/claude-code), you can install interactively:

```
/dotfiles:install
```

This fetches configs from GitHub and lets you pick which components to install.

## What's included

### Terminal

| Tool | Description |
|------|-------------|
| [Ghostty](https://ghostty.org) | GPU-accelerated terminal with Catppuccin theme, transparency, quick terminal |
| [JetBrains Mono Nerd Font](https://www.nerdfonts.com) | Monospace font with ligatures and icon glyphs |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer with Catppuccin status bar and session persistence |
| [Starship](https://starship.rs) | Minimal prompt with git status, language versions, Catppuccin colors |

### CLI replacements

| Alias | Tool | Replaces |
|-------|------|----------|
| `ls`, `ll`, `lt` | [eza](https://github.com/eza-community/eza) | `ls` — icons, tree view, git status |
| `cat` | [bat](https://github.com/sharkdp/bat) | `cat` — syntax highlighting, line numbers |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` — fast regex search |
| `find` | [fd](https://github.com/sharkdp/fd) | `find` — fast file finder |
| `diff` | [delta](https://github.com/dandavid/delta) | `diff` — side-by-side diffs with syntax highlighting |
| `dig` | [doggo](https://github.com/mr-karan/doggo) | `dig` — modern DNS client |
| `md` | [glow](https://github.com/charmbracelet/glow) | — — render markdown in terminal |
| `cd` (via `z`) | [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd` — smart directory jumping |
| Ctrl+T | [fzf](https://github.com/junegunn/fzf) | — — fuzzy file/directory finder |

### Security tools

| Alias | Tool | Purpose |
|-------|------|---------|
| `secrets` | [gitleaks](https://github.com/gitleaks/gitleaks) | Scan git history for secrets |
| `scan` | [semgrep](https://github.com/semgrep/semgrep) | Static analysis with auto-config |
| `vulns` | [trivy](https://github.com/aquasecurity/trivy) | Scan for vulnerabilities, secrets, misconfigs |
| — | [httpie](https://httpie.io) | Human-friendly HTTP client |
| — | [mitmproxy](https://mitmproxy.org) | Interactive HTTPS proxy for debugging |

### Git

- **Delta** as default pager — side-by-side diffs, syntax highlighting, Catppuccin theme
- **Gitleaks pre-push hook** — blocks pushes containing secrets

## Config files

| File | Installs to | Safe to overwrite? |
|------|-------------|-------------------|
| `configs/ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` | Yes |
| `configs/starship.toml` | `~/.config/starship.toml` | Yes |
| `configs/tmux.conf` | `~/.tmux.conf` | Yes |
| `configs/zshrc` | Sourced from `~/.zshrc` | Yes (snippet, not full replacement) |
| `configs/gitconfig-delta` | Merged into `~/.gitconfig` via `git config` | Yes (additive) |
| `hooks/pre-push` | `~/.dotfiles/hooks/pre-push` | Yes |

The installer backs up existing files before overwriting (`.backup.<timestamp>` suffix).

`configs/zshrc` is a **sourceable snippet**, not a full `.zshrc` replacement. The installer appends a `source` line to your existing `~/.zshrc`, preserving your PATH entries, completions, and other customizations.

## Keybindings

### Ghostty

| Key | Action |
|-----|--------|
| `Cmd+`` | Toggle quick terminal (drops down from top) |

### tmux

| Key | Action |
|-----|--------|
| `Ctrl+a` | Prefix (replaces default `Ctrl+b`) |
| `Prefix \|` | Split pane horizontally |
| `Prefix -` | Split pane vertically |
| `Alt+Arrow` | Navigate panes (no prefix needed) |
| `Prefix Alt+Arrow` | Resize pane |
| `Prefix r` | Reload config |
| `Prefix I` | Install/update TPM plugins |
| `Prefix [` | Enter copy mode (vi keys, `v` to select, `y` to copy) |

### fzf

| Key | Action |
|-----|--------|
| `Ctrl+T` | Fuzzy find files |
| `Ctrl+R` | Fuzzy search command history |
| `Alt+C` | Fuzzy find and cd into directory |

## Customization

### Override aliases

Add overrides **after** the source line in your `~/.zshrc`:

```bash
source "$HOME/.dotfiles/configs/zshrc"

# Override: use eza without icons
alias ls="eza --group-directories-first"
```

### Change Catppuccin flavor

The configs use **Catppuccin Mocha** (dark). To switch to Latte (light), Frappe, or Macchiato:

1. **Starship**: Change `palette` and `[palettes.*]` section in `configs/starship.toml`
2. **fzf**: Update the `FZF_DEFAULT_OPTS` colors in `configs/zshrc`
3. **bat**: Download the matching `.tmTheme` from [catppuccin/bat](https://github.com/catppuccin/bat)
4. **tmux**: Change `@catppuccin_flavor` in `configs/tmux.conf`
5. **Ghostty**: Already auto-switches between Latte/Mocha based on macOS appearance

### Disable the gitleaks hook

```bash
git config --global --unset core.hooksPath
```

Or for a single repo:

```bash
git config --local core.hooksPath ""
```

## Requirements

- macOS (Homebrew-based installer)
- Ghostty terminal (for the Ghostty config; other configs work in any terminal)
