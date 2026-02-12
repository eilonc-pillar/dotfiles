You are installing or updating a modern macOS terminal stack into the user's environment.

## Source files

Fetch each file from GitHub using WebFetch. The base URL is:

```
https://raw.githubusercontent.com/eilonc-pillar/dotfiles/main/
```

Files to fetch when needed:
- `configs/ghostty/config`
- `configs/starship.toml`
- `configs/tmux.conf`
- `configs/zshrc`
- `configs/gitconfig-delta`
- `hooks/pre-push`
- `install.sh`

## Steps

1. **Inventory what exists.** Check for these files and note which exist:
   - `~/Library/Application Support/com.mitchellh.ghostty/config`
   - `~/.config/starship.toml`
   - `~/.tmux.conf`
   - `~/.zshrc` (check if it already sources dotfiles zshrc)
   - `~/.gitconfig` (check for delta config)
   - `~/.dotfiles/hooks/pre-push`

2. **Ask the user what to install.** Use AskUserQuestion with a single multi-select question. List each component with a short description. Pre-label components that are missing as recommended. Components:
   - **Ghostty config** — Catppuccin theme, JetBrains Mono Nerd Font, transparency, quick terminal
   - **Starship prompt** — minimal prompt with git status, Catppuccin colors, Nerd Font icons
   - **tmux config** — Ctrl+a prefix, vi mode, Catppuccin status bar, session persistence
   - **Zsh aliases** — modern CLI aliases (eza, bat, ripgrep, fd, zoxide, fzf) with Catppuccin fzf theme
   - **Git delta** — side-by-side diffs with syntax highlighting and Catppuccin theme
   - **Security tools** — brew install gitleaks, semgrep, trivy, httpie, mitmproxy
   - **Gitleaks pre-push hook** — scan for secrets before every push

3. **Install brew packages.** For any selected components that need brew packages:
   - Ghostty: no extra packages (font installed separately)
   - Starship: `starship`
   - tmux: `tmux`
   - Zsh aliases: `eza bat ripgrep fd zoxide fzf git-delta doggo glow`
   - Git delta: `git-delta`
   - Security tools: `gitleaks semgrep trivy httpie mitmproxy`
   Check which are already installed with `brew list` before installing.

4. **Install font.** If any component was selected, check for and install `font-jetbrains-mono-nerd-font` via `brew install --cask`.

5. **For each selected component, install it:**

   - **Ghostty config**: Fetch `configs/ghostty/config`. Back up existing config if present. Write to `~/Library/Application Support/com.mitchellh.ghostty/config`.

   - **Starship prompt**: Fetch `configs/starship.toml`. Back up existing if present. Write to `~/.config/starship.toml`.

   - **tmux config**: Fetch `configs/tmux.conf`. Back up existing if present. Write to `~/.tmux.conf`. Install TPM if `~/.tmux/plugins/tpm` doesn't exist.

   - **Zsh aliases**: Fetch `configs/zshrc`. Clone/symlink the dotfiles repo to `~/.dotfiles` if not present (or write the zshrc file to `~/.dotfiles/configs/zshrc` directly). Add `source "$HOME/.dotfiles/configs/zshrc"` to `~/.zshrc` if not already present. Never overwrite the user's existing `~/.zshrc` — only append the source line.

   - **Git delta**: Run `git config --global` commands to set: `core.pager=delta`, `interactive.diffFilter=delta --color-only`, `delta.navigate=true`, `delta.side-by-side=true`, `delta.line-numbers=true`, `delta.syntax-theme=Catppuccin Mocha`, `merge.conflictstyle=diff3`, `diff.colorMoved=default`.

   - **Security tools**: Just the brew install from step 3.

   - **Gitleaks pre-push hook**: Fetch `hooks/pre-push`. Write to `~/.dotfiles/hooks/pre-push` and `chmod +x`. Set `git config --global core.hooksPath ~/.dotfiles/hooks`.

6. **Install bat theme.** If zsh aliases or git delta were selected, install the Catppuccin Mocha bat theme:
   ```bash
   mkdir -p "$(bat --config-dir)/themes"
   curl -fsSL -o "$(bat --config-dir)/themes/Catppuccin Mocha.tmTheme" \
     "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"
   bat cache --build
   ```

7. **Self-install.** After completing the user's selections, also install this command to `~/.claude/commands/dotfiles/install.md` so the user can run `/dotfiles:install` from any directory.

8. **Post-install.** Summarize what was installed/updated. Remind the user to:
   - Restart their terminal (or `source ~/.zshrc`)
   - Press `Ctrl+a` then `I` in tmux to install plugins (if tmux was selected)
   - Set Ghostty as default terminal (if Ghostty was selected)
