#!/usr/bin/env bash
#
# install.sh — provision a fresh Debian/Ubuntu box with the tools these
# dotfiles expect, then link the configs.
#
# Division of labour:
#   install.sh    installs software. Never edits config files.
#   bootstrap.sh  links config files. Never installs software.
#
# This script deliberately does NOT append anything to ~/.zshrc or ~/.bashrc:
# those are symlinks into this repo, and zsh/zshrc already sets every PATH and
# toolchain init. Editing them here would dirty the repo and fight the config.
#
# Safe to re-run: every step checks before it acts.
#
# Usage:
#   ./install.sh                    # tools, then link configs
#   SKIP_DOTNET=1 ./install.sh      # skip a component, see SKIP_* below
#   ./install.sh --tools-only       # install software, don't link
#
# SKIP_<NODE|RUST|DOTNET|CONDA|JDK|ZELLIJ|FONT|ZSH|WEZTERM|CLAUDE|NVIM_SYNC>=1
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NERD_FONT_VERSION="${NERD_FONT_VERSION:-v3.4.0}"
NODE_VERSION="${NODE_VERSION:---lts}"
DOTNET_CHANNEL="${DOTNET_CHANNEL:-LTS}"

# zsh/zshrc keeps toolchains on a data partition so a reinstall doesn't lose
# them. Override if this box has no /data.
DATA_ROOT="${DATA_ROOT:-/data}"

LOCAL_BIN="${HOME}/.local/bin"
FONT_DIR="${HOME}/.local/share/fonts"

TOOLS_ONLY=0
[ "${1:-}" = "--tools-only" ] && TOOLS_ONLY=1

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
c_blue='\033[1;34m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_red='\033[1;31m'; c_off='\033[0m'
log()  { printf "${c_blue}==>${c_off} %s\n" "$*"; }
ok()   { printf "${c_green}  ok${c_off} %s\n" "$*"; }
warn() { printf "${c_yellow}  !!${c_off} %s\n" "$*"; }
die()  { printf "${c_red}error:${c_off} %s\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
skip() { local v="SKIP_$1"; [ "${!v:-0}" = "1" ]; }

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)        NVIM_ARCH="x86_64"; ZELLIJ_ARCH="x86_64";  LG_ARCH="x86_64"; GNU_ARCH="x86_64" ;;
  aarch64|arm64) NVIM_ARCH="arm64";  ZELLIJ_ARCH="aarch64"; LG_ARCH="arm64";  GNU_ARCH="aarch64" ;;
  *) die "unsupported architecture: $ARCH" ;;
esac

[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
have apt-get || die "this script targets Debian/Ubuntu (apt-get not found)"

mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

# No data partition is fine: $DATA_ROOT becomes a plain directory we own.
if [ ! -d "$DATA_ROOT" ] || [ ! -w "$DATA_ROOT" ]; then
  log "Creating $DATA_ROOT"
  $SUDO mkdir -p "$DATA_ROOT"
  $SUDO chown "$(id -u):$(id -g)" "$DATA_ROOT"
fi

# ---------------------------------------------------------------------------
# 1. Base packages
# ---------------------------------------------------------------------------
log "Installing base packages via apt"
$SUDO apt-get update -y
$SUDO apt-get install -y --no-install-recommends \
  build-essential cmake pkg-config \
  git curl wget unzip tar ca-certificates gnupg \
  ripgrep fd-find \
  xclip wl-clipboard \
  python3 python3-pip python3-venv \
  zsh fontconfig btop
ok "apt packages installed"

# Debian ships fd as 'fdfind'; Telescope expects 'fd'.
if have fdfind && ! have fd; then
  ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  ok "linked fdfind -> fd"
fi

# eza backs the ls/ll/la/lt aliases in zsh/zshrc. In apt from Ubuntu 24.04;
# older releases get the released binary instead.
if ! have eza; then
  log "Installing eza"
  if $SUDO apt-get install -y eza 2>/dev/null; then
    ok "eza from apt"
  else
    eza_ver="$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest \
               | grep -oP '"tag_name":\s*"v\K[^"]+' || true)"
    if [ -n "${eza_ver:-}" ]; then
      tmp="$(mktemp -d)"
      curl -fL "https://github.com/eza-community/eza/releases/latest/download/eza_${GNU_ARCH}-unknown-linux-gnu.tar.gz" \
        -o "$tmp/eza.tar.gz"
      tar -xzf "$tmp/eza.tar.gz" -C "$tmp"
      install -m755 "$tmp/eza" "$LOCAL_BIN/eza"
      rm -rf "$tmp"
      ok "eza $eza_ver from release"
    else
      warn "could not install eza; the ls aliases in zshrc will fail"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 2. Neovim (>= 0.11, required by the LSP config's vim.lsp.config/enable API)
# ---------------------------------------------------------------------------
if have nvim && nvim --version | head -1 | grep -qE 'v0\.(1[1-9]|[2-9][0-9])'; then
  ok "neovim $(nvim --version | head -1) already present"
else
  log "Installing latest stable Neovim"
  tarball="nvim-linux-${NVIM_ARCH}.tar.gz"
  tmp="$(mktemp -d)"
  curl -fL "https://github.com/neovim/neovim/releases/latest/download/${tarball}" -o "$tmp/$tarball"
  $SUDO rm -rf /opt/nvim && $SUDO mkdir -p /opt/nvim
  $SUDO tar -xzf "$tmp/$tarball" -C /opt/nvim --strip-components=1
  $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$tmp"
  ok "neovim $(nvim --version | head -1) installed"
fi

# ---------------------------------------------------------------------------
# 3. Toolchains. Paths match zsh/zshrc, which points at $DATA_ROOT.
# ---------------------------------------------------------------------------
if ! skip NODE; then
  export NVM_DIR="${DATA_ROOT}/nvm"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    log "Installing nvm into $NVM_DIR"
    mkdir -p "$NVM_DIR"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  have node || { log "Installing Node.js (${NODE_VERSION})"; nvm install "$NODE_VERSION"; nvm alias default "$NODE_VERSION"; }
  ok "node $(node --version 2>/dev/null || echo '?')"
else
  warn "skipping Node.js"
fi

if ! skip RUST; then
  export RUSTUP_HOME="${DATA_ROOT}/Cargo/rustup" CARGO_HOME="${DATA_ROOT}/Cargo"
  export PATH="$CARGO_HOME/bin:$PATH"   # so a re-run finds the existing rustup
  if ! have rustup; then
    log "Installing Rust toolchain into $CARGO_HOME"
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fi
  # shellcheck disable=SC1091
  [ -f "$CARGO_HOME/env" ] && . "$CARGO_HOME/env"
  rustup component add rustfmt clippy rust-analyzer 2>/dev/null || true
  ok "rust $(rustc --version 2>/dev/null || echo '?')"
else
  warn "skipping Rust"
fi

if ! skip DOTNET; then
  export DOTNET_ROOT="${DATA_ROOT}/dotnet"
  if ! have dotnet && [ ! -x "${DOTNET_ROOT}/dotnet" ]; then
    log "Installing .NET SDK (${DOTNET_CHANNEL}) into $DOTNET_ROOT"
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    bash /tmp/dotnet-install.sh --channel "$DOTNET_CHANNEL" --install-dir "$DOTNET_ROOT"
    rm -f /tmp/dotnet-install.sh
  fi
  export PATH="${DOTNET_ROOT}:$PATH"
  ok ".NET $(dotnet --version 2>/dev/null || echo '?')"
else
  warn "skipping .NET"
fi

if ! skip CONDA; then
  if [ ! -x "${DATA_ROOT}/miniconda3/bin/conda" ]; then
    log "Installing Miniconda into ${DATA_ROOT}/miniconda3"
    tmp="$(mktemp -d)"
    curl -fL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${GNU_ARCH}.sh" -o "$tmp/miniconda.sh"
    # -b: batch, no prompts and no edits to shell rc files (zshrc sources conda.sh itself).
    bash "$tmp/miniconda.sh" -b -p "${DATA_ROOT}/miniconda3"
    rm -rf "$tmp"
  fi
  ok "conda $("${DATA_ROOT}/miniconda3/bin/conda" --version 2>/dev/null || echo '?')"
else
  warn "skipping Miniconda"
fi

# zshrc exports JAVA_HOME for JDK 17 (Android tooling) when it is present.
if ! skip JDK; then
  if ! dpkg -s openjdk-17-jdk >/dev/null 2>&1; then
    log "Installing OpenJDK 17"
    $SUDO apt-get install -y --no-install-recommends openjdk-17-jdk || warn "openjdk-17-jdk install failed"
  fi
  dpkg -s openjdk-17-jdk >/dev/null 2>&1 && ok "OpenJDK 17"
else
  warn "skipping JDK"
fi

# ---------------------------------------------------------------------------
# 4. Terminal stack: zellij, wezterm, starship, lazygit, Nerd Font
# ---------------------------------------------------------------------------
if ! skip ZELLIJ; then
  if ! have zellij; then
    log "Installing Zellij"
    tmp="$(mktemp -d)"
    curl -fL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ZELLIJ_ARCH}-unknown-linux-musl.tar.gz" \
      -o "$tmp/zellij.tar.gz"
    tar -xzf "$tmp/zellij.tar.gz" -C "$tmp"
    install -m755 "$tmp/zellij" "$LOCAL_BIN/zellij"
    rm -rf "$tmp"
  fi
  ok "zellij $(zellij --version 2>/dev/null || echo '?')"
  # zellij/config.kdl needs >= 0.42.2 for the vim-zellij-navigator bindings.
  zv="$(zellij --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo 0.0.0)"
  [ "$(printf '%s\n0.42.2\n' "$zv" | sort -V | head -1)" = "0.42.2" ] \
    || warn "zellij $zv is older than 0.42.2; Ctrl-hjkl navigation will not work"
else
  warn "skipping Zellij"
fi

if ! skip WEZTERM && ! have wezterm; then
  log "Installing WezTerm"
  curl -fsSL https://apt.fury.io/wez/gpg.key \
    | $SUDO gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
    | $SUDO tee /etc/apt/sources.list.d/wezterm.list >/dev/null
  $SUDO apt-get update -y && $SUDO apt-get install -y wezterm || warn "wezterm install failed"
fi
have wezterm && ok "wezterm $(wezterm --version 2>/dev/null || echo '?')"

if ! have starship; then
  log "Installing starship"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
fi
ok "starship $(starship --version 2>/dev/null | head -1 || echo '?')"

if ! have lazygit; then
  log "Installing lazygit"
  lg_ver="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
            | grep -oP '"tag_name":\s*"v\K[^"]+' || true)"
  if [ -n "${lg_ver:-}" ]; then
    tmp="$(mktemp -d)"
    curl -fL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lg_ver}_Linux_${LG_ARCH}.tar.gz" \
      -o "$tmp/lazygit.tar.gz"
    tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
    install -m755 "$tmp/lazygit" "$LOCAL_BIN/lazygit"
    rm -rf "$tmp"
  else
    warn "could not resolve lazygit version; skipping"
  fi
fi
have lazygit && ok "lazygit $(lazygit --version 2>/dev/null | head -1 || echo '?')"

if ! skip FONT; then
  if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    log "Installing JetBrainsMono Nerd Font ${NERD_FONT_VERSION}"
    mkdir -p "$FONT_DIR"
    tmp="$(mktemp -d)"
    curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.zip" \
      -o "$tmp/JetBrainsMono.zip"
    unzip -o -q "$tmp/JetBrainsMono.zip" -d "$FONT_DIR/JetBrainsMono"
    rm -rf "$tmp"
    fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
  fi
  ok "JetBrainsMono Nerd Font present (wezterm.lua already selects it)"
else
  warn "skipping font"
fi

# ---------------------------------------------------------------------------
# 5. Claude Code (claudecode.nvim drives this binary)
# ---------------------------------------------------------------------------
if ! skip CLAUDE && ! have claude; then
  log "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed; see docs.claude.com"
fi
have claude && ok "claude $(claude --version 2>/dev/null || echo '?')"

# ---------------------------------------------------------------------------
# 6. Default shell
# ---------------------------------------------------------------------------
if ! skip ZSH; then
  zsh_path="$(command -v zsh)"
  if [ "${SHELL:-}" != "$zsh_path" ]; then
    log "Setting zsh as default shell (may prompt for your password)"
    chsh -s "$zsh_path" 2>/dev/null && ok "default shell set to zsh (next login)" \
      || warn "chsh failed; run manually:  chsh -s $zsh_path"
  fi
fi

# ---------------------------------------------------------------------------
# 7. Link the configs, then let nvim install its own plugins
# ---------------------------------------------------------------------------
if [ "$TOOLS_ONLY" -eq 1 ]; then
  warn "--tools-only: skipping config linking"
else
  log "Linking configs"
  "$DOTFILES/bootstrap.sh"
fi

if ! skip NVIM_SYNC; then
  # restore, not sync: install exactly the commits pinned in nvim/lazy-lock.json.
  log "Restoring plugins from lazy-lock.json — the first run compiles Treesitter parsers, be patient"
  nvim --headless "+Lazy! restore" +qa || warn "Lazy restore reported issues (often fine on first run)"
  log "Installing Mason tools not covered by ensure_installed"
  nvim --headless "+MasonInstall stylua debugpy netcoredbg codelldb shfmt" +qa \
    || warn "some Mason tools failed; open nvim and run :Mason to retry"
  log "Updating Treesitter parsers"
  nvim --headless "+TSUpdateSync" +qa || warn "TSUpdate reported issues"
else
  warn "skipping headless nvim sync"
fi

printf "\n${c_green}Install complete.${c_off}\n"
cat <<EOF

Next steps:
  1. exec zsh          pick up PATH and starship
  2. Set the terminal font to "JetBrainsMono Nerd Font" (wezterm does this itself)
  3. zellij            first Ctrl-h prompts to trust the vim-zellij-navigator plugin
  4. nvim              run :checkhealth to confirm providers

Secrets:
  ~/.zshrc.local was created empty. Add API tokens there — never in zsh/zshrc.

Toolchains, nvim plugins, ~/.cargo and ~/Code live under ${DATA_ROOT}.

Not installed (add by hand if needed):
  Android Studio / SDK (${DATA_ROOT}/Android/Sdk) — referenced by zsh/zshrc but
  harmless when absent.
EOF
