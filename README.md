# Dotfiles

Config for a Linux workstation running **wezterm → zellij → neovim**, with Claude
Code inside neovim.

Everything here is the real file; `~` holds symlinks pointing back into this repo.

## New machine

```sh
git clone https://github.com/mansouriahmad/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Two scripts, deliberately split:

| | |
|---|---|
| `install.sh` | installs software. Never edits config files. |
| `bootstrap.sh` | links config files. Never installs software. |

`install.sh` runs `bootstrap.sh` at the end, so it is the only one you normally
call. Use `bootstrap.sh` alone when the tools are already present, and
`install.sh --tools-only` for the reverse. Both are idempotent.

It works on a fresh Ubuntu install and on a machine that is already set up:
every step checks first, and anything in the way is moved aside, never deleted.

Toolchains (Rust, Node, .NET, Miniconda), nvim plugins, and `~/Code` live under
`$DATA_ROOT` (default `/data`), so a reinstall of `/` doesn't lose them. With no
data partition, `/data` is simply created as a directory you own. To use a
different root:

```sh
DATA_ROOT="$HOME/data" ./install.sh
```

`bootstrap.sh` records a non-default root in `~/.zshenv`, which zsh reads before
`.zshrc`. (`~/.zshrc.local` would be too late: it is sourced at the end.)

Neovim plugins are pinned by `nvim/lazy-lock.json`; `install.sh` runs
`:Lazy! restore` to install exactly those commits. After `:Lazy update`, commit
the lockfile.

## Layout

| Path in repo | Symlinked to | What it is |
|---|---|---|
| `zsh/zshrc` | `~/.zshrc` | shell; sources `~/.zshrc.local` for secrets |
| `bash/bashrc` | `~/.bashrc` | |
| `bash/profile` | `~/.profile` | |
| `git/gitconfig` | `~/.gitconfig` | |
| `conda/condarc` | `~/.condarc` | |
| `zellij/config.kdl` | `~/.config/zellij/config.kdl` | multiplexer, see below |
| `wezterm/wezterm.lua` | `~/.config/wezterm` | terminal |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code |
| `btop/btop.conf` | `~/.config/btop/btop.conf` | |
| `nvim/` | `~/.config/nvim` | neovim config, merged in via git subtree |

Data directories, linked by `bootstrap.sh`. If the home directory already holds a
real one and `$DATA_ROOT` doesn't, it is moved there first; if both exist, it is
left alone for you to merge.

| `$DATA_ROOT/…` | Symlinked to | What it is |
|---|---|---|
| `nvim-data` | `~/.local/share/nvim` | lazy plugins, Mason tools |
| `Cargo` | `~/.cargo` | `CARGO_HOME`; rustup lives in `Cargo/rustup` |
| `Code` | `~/Code` | projects |

This repo is public, so it carries no identifying information: git identity
lives in `~/.gitconfig.local` (untracked, created by `bootstrap.sh`), secrets in
`~/.zshrc.local`, and machine-specific paths behind `DATA_ROOT`.

## Secrets

**Nothing secret goes in this repo.** `~/.zshrc.local` (chmod 600, untracked)
holds API tokens and per-machine overrides; `zsh/zshrc` sources it if present.
`.gitignore` also blocks `*.local`, `.env`, and anything matching `*token*` or
`*secret*` as a backstop.

A pre-commit hook in `.githooks/` refuses commits containing secret-shaped
assignments, known credential prefixes (`ghp_`, `sk-`, `AKIA…`), or private key
blocks. Enable it once per clone — `bootstrap.sh` does this for you:

```sh
git config core.hooksPath .githooks
```

If you ever need a secret on a new box, put it in `~/.zshrc.local` — never inline
in `zshrc`.

## Key bindings: how zellij and neovim share Ctrl-hjkl

Zellij receives keystrokes before neovim does, so its stock bindings shadow keys
neovim needs. This config resolves that rather than working around it:

- `Ctrl h/j/k/l` is bound in zellij to the
  [vim-zellij-navigator](https://github.com/hiasr/vim-zellij-navigator) wasm
  plugin. It forwards the key to neovim when a vim process owns the pane;
  [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim) moves the
  cursor and hands control back to zellij at the edge of the window layout. The
  result is one continuous space: editor split → editor split → zellij pane → tab.
- `Alt h/j/k/l` resizes (direction-only; zellij cannot resize by an amount).
- Modes that stock zellij puts on `Ctrl n/o/p/t` — which neovim uses for
  completion, the jumplist, and Telescope — moved to `Alt r/e/c/t`.
- `Alt m` move mode, `Alt n` new pane, `Alt f` floating, `Ctrl s` scroll.

Zellij loads plugins straight from a URL, so nothing is vendored here; it prompts
once to trust the plugin on first use.

Inside neovim, the Claude Code split is an ordinary window, so `Ctrl h` leaves it.
That map also exists in terminal mode, since terminal buffers start in insert mode
where normal-mode maps never fire. A single `Esc` still reaches Claude to interrupt
it; `Esc Esc` drops to neovim normal mode.

## Not tracked

Machine-local and generated files: `~/.zshrc.local` (secrets), editor scratch,
and OS junk. See `.gitignore`.
