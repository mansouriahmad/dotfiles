#!/usr/bin/env bash
# Recreate every dotfile symlink on a fresh machine.
#
#   git clone <this repo> ~/dotfiles && ~/dotfiles/bootstrap.sh
#
# Idempotent: an existing correct symlink is left alone, a real file is moved
# aside to <name>.pre-bootstrap before being replaced. Nothing is deleted.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Same defaults as zsh/zshrc: macOS won't allow new top-level directories.
if [[ $(uname -s) == Darwin ]]; then DEFAULT_DATA_ROOT="$HOME/data"; else DEFAULT_DATA_ROOT=/data; fi
DATA_ROOT="${DATA_ROOT:-$DEFAULT_DATA_ROOT}"

link() {
  local src="$DOTFILES/$1" dst="$2"

  if [[ ! -e $src ]]; then
    printf '  skip   %s (missing in repo)\n' "$1"
    return
  fi

  if [[ -L $dst && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    printf '  ok     %s\n' "${dst/#$HOME/\~}"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -e $dst || -L $dst ]]; then
    mv "$dst" "$dst.pre-bootstrap"
    printf '  backup %s -> %s\n' "${dst/#$HOME/\~}" "${dst##*/}.pre-bootstrap"
  fi

  ln -s "$src" "$dst"
  printf '  link   %s -> %s\n' "${dst/#$HOME/\~}" "$1"
}

# Point a home directory at its counterpart under $DATA_ROOT, so bulky or
# precious state (plugins, toolchains, projects) survives a reinstall of /.
# A real directory already at $2 is moved into $DATA_ROOT when nothing is there
# yet; if both exist it is left alone rather than guessing which one wins.
link_data() {
  local src="$DATA_ROOT/$1" dst="$2"

  if [[ -L $dst && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    printf '  ok     %s\n' "${dst/#$HOME/\~}"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -d $dst && ! -L $dst ]]; then
    if [[ -e $src ]]; then
      printf '  keep   %s (both it and %s exist; merge by hand)\n' "${dst/#$HOME/\~}" "$src"
      return
    fi
    mv "$dst" "$src"
    printf '  move   %s -> %s\n' "${dst/#$HOME/\~}" "$src"
  elif [[ -e $dst || -L $dst ]]; then
    mv "$dst" "$dst.pre-bootstrap"
    printf '  backup %s -> %s\n' "${dst/#$HOME/\~}" "${dst##*/}.pre-bootstrap"
  fi

  mkdir -p "$src"
  ln -s "$src" "$dst"
  printf '  link   %s -> %s\n' "${dst/#$HOME/\~}" "$src"
}

# $DATA_ROOT is a plain directory if this box has no data partition; create it
# owned by us so nothing below needs root.
if ! mkdir -p "$DATA_ROOT" 2>/dev/null || [[ ! -w $DATA_ROOT ]]; then
  sudo mkdir -p "$DATA_ROOT"
  sudo chown "$(id -u):$(id -g)" "$DATA_ROOT"
  echo "Created $DATA_ROOT (owned by $(id -un))"
fi

echo "Linking dotfiles from $DOTFILES"

# Refuse commits that carry credentials (see .githooks/pre-commit).
if [[ -d $DOTFILES/.git ]]; then
  git -C "$DOTFILES" config core.hooksPath .githooks
  echo "  hooks  core.hooksPath -> .githooks"
fi

link zsh/zshrc            "$HOME/.zshrc"
link bash/bashrc          "$HOME/.bashrc"
link bash/profile         "$HOME/.profile"
link git/gitconfig        "$HOME/.gitconfig"
link conda/condarc        "$HOME/.condarc"
link zellij/config.kdl    "$HOME/.config/zellij/config.kdl"
link wezterm              "$HOME/.config/wezterm"
link claude/settings.json "$HOME/.claude/settings.json"
link btop/btop.conf       "$HOME/.config/btop/btop.conf"
link nvim                 "$HOME/.config/nvim"

echo "Linking data directories under $DATA_ROOT"
link_data nvim-data "$HOME/.local/share/nvim"   # lazy plugins, mason tools
link_data Cargo     "$HOME/.cargo"              # same dir zshrc uses as CARGO_HOME
link_data Code      "$HOME/Code"

# zshrc only knows the per-OS default; any other root has to be exported
# before zshrc runs, and ~/.zshenv is the file zsh reads first.
if [[ $DATA_ROOT != "$DEFAULT_DATA_ROOT" ]] && ! grep -qs '^export DATA_ROOT=' "$HOME/.zshenv"; then
  printf 'export DATA_ROOT="%s"\n' "$DATA_ROOT" >> "$HOME/.zshenv"
  echo "  append ~/.zshenv (DATA_ROOT=$DATA_ROOT)"
fi

# Identity is not tracked (public repo). Seed it locally.
if [[ ! -f $HOME/.gitconfig.local ]]; then
  cat > "$HOME/.gitconfig.local" <<'IDENT'
[user]
	name = CHANGE ME
	email = CHANGE ME
IDENT
  echo "  create ~/.gitconfig.local (set your git name/email)"
fi

# Secrets are never in this repo. Seed a local file to hold them.
if [[ ! -f $HOME/.zshrc.local ]]; then
  cat > "$HOME/.zshrc.local" <<'LOCAL'
# Machine-local shell config. NOT version controlled - secrets live here.
# Sourced from ~/.zshrc. Keep this file out of any dotfiles repo.
LOCAL
  chmod 600 "$HOME/.zshrc.local"
  echo "  create ~/.zshrc.local (add API tokens here)"
fi

echo "Done."
