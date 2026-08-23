#!/usr/bin/env bash
# Recreate every dotfile symlink on a fresh machine.
#
#   git clone <this repo> ~/dotfiles && ~/dotfiles/bootstrap.sh
#
# Idempotent: an existing correct symlink is left alone, a real file is moved
# aside to <name>.pre-bootstrap before being replaced. Nothing is deleted.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
