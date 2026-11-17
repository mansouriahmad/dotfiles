<#
  install.ps1 - provision a Windows machine (Windows 10/11, Windows Server
  2022/2025) with the tools these dotfiles expect, then link the configs.
  The Windows counterpart of install.sh + bootstrap.sh.

  Safety rules this script keeps:
    * Software comes only from winget's official community source
      (--source winget), the same packages Microsoft lists. Nothing is piped
      from the internet into a shell.
    * Nothing is ever deleted. A file or folder in the way is moved aside to
      <name>.pre-bootstrap (timestamped if that exists too) before a link
      replaces it. Links are created with New-Item, never removed with
      Remove-Item, so a junction can't take its target down with it.
    * Already-installed packages are left alone (no silent upgrades).
    * Every step checks first, so re-running is harmless.
    * -DryRun prints every action without doing any of them.

  Usage (from Windows PowerShell or pwsh; no admin shell needed, winget asks
  for elevation itself when a package installs machine-wide):

    git clone https://github.com/mansouriahmad/dotfiles.git $HOME\Dotfiles
    powershell -ExecutionPolicy Bypass -File $HOME\Dotfiles\windows\install.ps1 -DryRun
    powershell -ExecutionPolicy Bypass -File $HOME\Dotfiles\windows\install.ps1

    -Skip Rust,DotNet     skip components (names below)
    -ToolsOnly            install software, don't link configs
    -LinkOnly             link configs, don't install software

  Components: Build Terminal Font Node Rust DotNet Python Conda JDK Claude
              VSCode NvimSync   (Core is always installed)
#>
[CmdletBinding()]
param(
  [string[]]$Skip = @(),
  [switch]$ToolsOnly,
  [switch]$LinkOnly,
  [switch]$DryRun
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$Dotfiles = Split-Path -Parent $PSScriptRoot
$Failures = New-Object System.Collections.Generic.List[string]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Log  ($m) { Write-Host "==> $m" -ForegroundColor Blue }
function Ok   ($m) { Write-Host "  ok $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "  !! $m" -ForegroundColor Yellow }

$Components = 'Build','Terminal','Font','Node','Rust','DotNet','Python','Conda','JDK','Claude','VSCode','NvimSync'
foreach ($s in $Skip) {
  if ($Components -notcontains $s) { throw "Unknown component '$s'. Valid: $($Components -join ', ')" }
}
function Skipped ($name) { return $Skip -contains $name }

# Run a side effect, or just describe it under -DryRun.
function Step ([string]$Description, [scriptblock]$Action) {
  if ($DryRun) { Write-Host "  would $Description" -ForegroundColor DarkGray; return }
  & $Action
}

function Have ($cmd) {
  # Ignore the Microsoft Store "app execution alias" stubs in WindowsApps:
  # python.exe there opens the Store instead of running Python.
  $c = Get-Command $cmd -CommandType Application -ErrorAction SilentlyContinue |
       Where-Object { $_.Source -notlike '*\WindowsApps\*' } | Select-Object -First 1
  return [bool]$c
}

# Installers update the registry PATH, not this session's. Re-read it.
function Update-SessionPath {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = "$machine;$user"
}

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------
# Cmd: an executable that proves the tool is already there (from winget or
# anywhere else). Without one, `winget list` decides.
$VCTools = '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
$Packages = @(
  # Core: the editor and what it shells out to.
  @{ Group='Core';     Id='Microsoft.PowerShell';           Cmd='pwsh' }
  @{ Group='Core';     Id='Git.Git';                        Cmd='git' }
  @{ Group='Core';     Id='Neovim.Neovim';                  Cmd='nvim' }
  @{ Group='Core';     Id='BurntSushi.ripgrep.MSVC';        Cmd='rg' }
  @{ Group='Core';     Id='sharkdp.fd';                     Cmd='fd' }
  @{ Group='Core';     Id='equalsraf.win32yank';            Cmd='win32yank' }   # nvim's Windows clipboard provider
  @{ Group='Core';     Id='tree-sitter.tree-sitter-cli';    Cmd='tree-sitter' } # compiles Treesitter parsers
  @{ Group='Core';     Id='7zip.7zip';                      Cmd=$null }         # Mason unpacks .gz/.7z with it
  # Build: C/C++ compiler for Treesitter parsers, telescope-fzf-native, Rust (msvc) and your C++ work.
  @{ Group='Build';    Id='Microsoft.VisualStudio.BuildTools'; Cmd=$null; Override=$VCTools }
  @{ Group='Build';    Id='Kitware.CMake';                  Cmd='cmake' }
  @{ Group='Build';    Id='Ninja-build.Ninja';              Cmd='ninja' }
  @{ Group='Build';    Id='LLVM.LLVM';                      Cmd='clang' }
  # Terminal stack (WezTerm replaces wezterm + zellij here; see wezterm.lua).
  @{ Group='Terminal'; Id='wez.wezterm';                    Cmd='wezterm' }
  @{ Group='Terminal'; Id='Starship.Starship';              Cmd='starship' }
  @{ Group='Terminal'; Id='JesseDuffield.lazygit';          Cmd='lazygit' }
  @{ Group='Terminal'; Id='eza-community.eza';              Cmd='eza' }
  @{ Group='Font';     Id='DEVCOM.JetBrainsMonoNerdFont';   Cmd=$null }
  # Toolchains
  @{ Group='Node';     Id='OpenJS.NodeJS.LTS';              Cmd='node' }        # npm-based Mason servers
  @{ Group='Rust';     Id='Rustlang.Rustup';                Cmd='rustup' }
  @{ Group='DotNet';   Id='Microsoft.DotNet.SDK.10';        Cmd='dotnet' }
  @{ Group='Python';   Id='Python.Python.3.13';             Cmd='python' }
  @{ Group='Conda';    Id='Anaconda.Miniconda3';            Cmd=$null }
  @{ Group='JDK';      Id='Microsoft.OpenJDK.17';           Cmd=$null }
  @{ Group='Claude';   Id='Anthropic.ClaudeCode';           Cmd='claude' }
)

function Test-WingetInstalled ($id) {
  # Windows PowerShell 5.1 turns redirected native stderr into a terminating
  # error under 'Stop'; native calls below run with 'Continue' for that reason.
  $ErrorActionPreference = 'Continue'
  $null = & winget list --id $id --exact --accept-source-agreements --disable-interactivity 2>$null
  return ($LASTEXITCODE -eq 0)
}

function Install-Package ($p) {
  if ($p.Cmd -and (Have $p.Cmd)) { Ok "$($p.Id) (found $($p.Cmd))"; return }
  if (Test-WingetInstalled $p.Id)  { Ok "$($p.Id) (already installed)"; return }

  Log "Installing $($p.Id)"
  $wargs = @('install', '--id', $p.Id, '--exact', '--source', 'winget',
             '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
  if ($p.ContainsKey('Override') -and $p.Override) { $wargs += @('--override', $p.Override) }
  else { $wargs += '--silent' }

  Step "winget $($wargs -join ' ')" {
    & winget @wargs
    # 0x8A15002B: already installed / no applicable upgrade. 3010: needs a reboot.
    if (@(0, -1978335189, 3010) -contains $LASTEXITCODE) { Ok $p.Id }
    else { Warn "$($p.Id) failed (winget exit $LASTEXITCODE)"; $Failures.Add($p.Id) }
    Update-SessionPath
  }
}

# Append a directory to the *user* PATH (never the machine PATH), once.
function Add-UserPath ($dir) {
  if (-not (Test-Path $dir)) { return }
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not $user) { $user = '' }
  if (($user -split ';') -contains $dir) { return }
  Step "add $dir to the user PATH" {
    [Environment]::SetEnvironmentVariable('Path', ($user.TrimEnd(';') + ";$dir").TrimStart(';'), 'User')
    Update-SessionPath
    Ok "user PATH += $dir"
  }
}

# ---------------------------------------------------------------------------
# Linking
# ---------------------------------------------------------------------------
function Get-LinkTarget ($path) {
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if (-not $item -or -not $item.LinkType) { return $null }
  $t = @($item.Target)[0]
  if (-not $t) { return $null }
  return [IO.Path]::GetFullPath($t).TrimEnd('\')
}

function Show ($path) { return $path.Replace($HOME, '~') }

function Get-BackupName ($path) {
  $dest = "$path.pre-bootstrap"
  if (Get-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue) {
    $dest = "$path.pre-bootstrap-$(Get-Date -Format yyyyMMdd-HHmmss)"
  }
  return $dest
}

# Move whatever is at $path out of the way. Never deletes.
function Move-Aside ($path) {
  $dest = Get-BackupName $path
  Step "move $(Show $path) -> $(Split-Path -Leaf $dest)" {
    Move-Item -LiteralPath $path -Destination $dest
    Write-Host "  backup $(Show $path) -> $(Split-Path -Leaf $dest)"
  }
  return $dest
}

function Ensure-Parent ($path) {
  $parent = Split-Path -Parent $path
  if (-not (Test-Path -LiteralPath $parent)) {
    Step "create $(Show $parent)" { $null = New-Item -ItemType Directory -Path $parent -Force }
  }
}

# Directories become junctions: no admin or Developer Mode needed.
function Link-Dir ($rel, $dst) {
  $src = [IO.Path]::GetFullPath((Join-Path $Dotfiles $rel)).TrimEnd('\')
  if (-not (Test-Path -LiteralPath $src)) { Write-Host "  skip   $rel (missing in repo)"; return }
  if ((Get-LinkTarget $dst) -eq $src) { Ok (Show $dst); return }

  Ensure-Parent $dst
  # Get-Item, not Test-Path: Test-Path is false for a dangling junction.
  if (Get-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue) { $null = Move-Aside $dst }

  Step "junction $(Show $dst) -> $rel" {
    try { $null = New-Item -ItemType Junction -Path $dst -Target $src }
    catch {
      # Junctions need a local NTFS volume; a repo on a network share needs a symlink.
      $null = New-Item -ItemType SymbolicLink -Path $dst -Target $src
    }
    Write-Host "  link   $(Show $dst) -> $rel"
  }
}

# Files become symlinks when Windows allows it (Developer Mode or an admin
# shell), otherwise a copy -- re-run after changing the repo file to refresh it.
function Link-File ($rel, $dst) {
  $src = [IO.Path]::GetFullPath((Join-Path $Dotfiles $rel))
  if (-not (Test-Path -LiteralPath $src)) { Write-Host "  skip   $rel (missing in repo)"; return $null }
  if ((Get-LinkTarget $dst) -eq $src.TrimEnd('\')) { Ok (Show $dst); return $null }

  $isPlainFile = (Test-Path -LiteralPath $dst -PathType Leaf) -and -not (Get-LinkTarget $dst)
  if ($isPlainFile -and (Get-FileHash -LiteralPath $dst).Hash -eq (Get-FileHash -LiteralPath $src).Hash) {
    Ok "$(Show $dst) (copy, up to date)"; return $null
  }

  Ensure-Parent $dst
  $backup = $null
  if (Get-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue) { $backup = Move-Aside $dst }

  Step "symlink (or copy) $(Show $dst) -> $rel" {
    try {
      $null = New-Item -ItemType SymbolicLink -Path $dst -Target $src
      Write-Host "  link   $(Show $dst) -> $rel"
    } catch {
      Copy-Item -LiteralPath $src -Destination $dst
      Warn "$(Show $dst) copied, not linked (enable Developer Mode for a live link; re-run to refresh)"
    }
  }
  return $backup
}

# Add one dot-source line to a PowerShell profile. An existing profile is
# copied to .pre-bootstrap first and otherwise left as it was.
function Hook-Profile ($profilePath) {
  $script = Join-Path $Dotfiles 'windows\profile.ps1'
  $line = ". `"$script`"  # dotfiles (windows/profile.ps1)"
  if ((Test-Path -LiteralPath $profilePath) -and
      (Select-String -LiteralPath $profilePath -SimpleMatch $script -Quiet)) {
    Ok (Show $profilePath); return
  }
  Ensure-Parent $profilePath
  Step "add dotfiles line to $(Show $profilePath)" {
    if (Test-Path -LiteralPath $profilePath) {
      $backup = Get-BackupName $profilePath
      Copy-Item -LiteralPath $profilePath -Destination $backup
      Write-Host "  backup $(Show $profilePath) -> $(Split-Path -Leaf $backup)"
      Add-Content -LiteralPath $profilePath -Value "`r`n$line" -Encoding UTF8
    } else {
      Set-Content -LiteralPath $profilePath -Value $line -Encoding UTF8
    }
    Write-Host "  hook   $(Show $profilePath)"
  }
}

# ---------------------------------------------------------------------------
# 1. Software
# ---------------------------------------------------------------------------
if ($DryRun) { Warn 'dry run: nothing will be installed, moved or linked' }

if (-not $LinkOnly) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw ('winget not found. It ships with Windows 11 and Windows Server 2025 (App Installer). ' +
           'On Windows Server 2022 install it first, see learn.microsoft.com/windows/package-manager/winget, ' +
           'then re-run. Or use -LinkOnly if the tools are already installed.')
  }

  foreach ($p in $Packages) {
    if ($p.Group -ne 'Core' -and (Skipped $p.Group)) { continue }
    Install-Package $p
  }
  Update-SessionPath

  # 7-Zip's installer doesn't put 7z.exe on PATH; Mason looks for it there.
  if (-not (Have '7z')) { Add-UserPath "$env:ProgramFiles\7-Zip" }

  # Neovim >= 0.12 is required by nvim-treesitter's main branch.
  if (Have 'nvim') {
    $v = (& nvim --version | Select-Object -First 1)
    if ($v -match 'v0\.(\d+)' -and [int]$Matches[1] -lt 12) {
      Warn "$v is older than 0.12; run: winget upgrade --id Neovim.Neovim"
    } else { Ok $v }
  }

  if (-not (Skipped 'Rust') -and (Have 'rustup')) {
    Step 'set up the stable Rust toolchain + rustfmt, clippy, rust-analyzer' {
      $ErrorActionPreference = 'Continue'
      $toolchains = (& rustup toolchain list 2>$null) -join ''
      if (-not $toolchains -or $toolchains -match 'no installed toolchains') { & rustup default stable }
      & rustup component add rustfmt clippy rust-analyzer 2>$null
      Update-SessionPath
      Ok "$(& rustc --version 2>$null)"
    }
  }
}

# ---------------------------------------------------------------------------
# 2. Configs
# ---------------------------------------------------------------------------
if (-not $ToolsOnly) {
  Log "Linking dotfiles from $Dotfiles"

  if ((Test-Path (Join-Path $Dotfiles '.git')) -and (Have 'git')) {
    Step 'set core.hooksPath -> .githooks' {
      & git -C $Dotfiles config core.hooksPath .githooks
      Write-Host '  hooks  core.hooksPath -> .githooks'
    }
  }

  Link-Dir  'nvim'    (Join-Path $env:LOCALAPPDATA 'nvim')       # Windows stdpath('config')
  Link-Dir  'wezterm' (Join-Path $HOME '.config\wezterm')         # WezTerm checks here on Windows too
  $null = Link-File 'claude\settings.json' (Join-Path $HOME '.claude\settings.json')
  $null = Link-File 'conda\condarc'        (Join-Path $HOME '.condarc')

  # git/gitconfig only includes ~/.gitconfig.local. If a real ~/.gitconfig was
  # here, it becomes ~/.gitconfig.local, so your identity and settings carry on.
  $gitLocal  = Join-Path $HOME '.gitconfig.local'
  $gitBackup = Link-File 'git\gitconfig' (Join-Path $HOME '.gitconfig')
  if (-not (Test-Path -LiteralPath $gitLocal)) {
    Step 'create ~/.gitconfig.local' {
      if ($gitBackup -and (Test-Path -LiteralPath $gitBackup -PathType Leaf)) {
        Copy-Item -LiteralPath $gitBackup -Destination $gitLocal
        Write-Host '  create ~/.gitconfig.local (from your previous ~/.gitconfig)'
      } else {
        Set-Content -LiteralPath $gitLocal -Value "[user]`r`n`tname = CHANGE ME`r`n`temail = CHANGE ME" -Encoding ASCII
        Write-Host '  create ~/.gitconfig.local (set your git name/email)'
      }
    }
  }

  # pwsh 7 profile only (WezTerm starts pwsh). Windows PowerShell 5.1 is left
  # untouched: on Windows 10/11 its execution policy defaults to Restricted, so
  # a profile there would print an error in every window instead of loading.
  $docs = [Environment]::GetFolderPath('MyDocuments')   # follows OneDrive redirection
  Hook-Profile (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1')

  # Secrets are never in this repo. Seed a local file to hold them.
  $localPs = Join-Path $HOME '.pwsh.local.ps1'
  if (-not (Test-Path -LiteralPath $localPs)) {
    Step 'create ~/.pwsh.local.ps1' {
      Set-Content -LiteralPath $localPs -Value ('# Machine-local PowerShell config. NOT version controlled - secrets live here.' +
        "`r`n# Dot-sourced at the end of windows/profile.ps1.") -Encoding UTF8
      Write-Host '  create ~/.pwsh.local.ps1 (add API tokens here)'
    }
  }

  if (-not (Skipped 'VSCode') -and (Get-Command code.cmd -ErrorAction SilentlyContinue)) {
    Step 'install the nvim colorschemes into VS Code' {
      try { & (Join-Path $Dotfiles 'vscode\install.ps1') }
      catch { Warn "VS Code theme install failed: $_" }
    }
  }
}

# ---------------------------------------------------------------------------
# 3. Let nvim install its own plugins
# ---------------------------------------------------------------------------
if (-not $ToolsOnly -and -not (Skipped 'NvimSync') -and (Have 'nvim')) {
  # restore, not sync: exactly the commits pinned in nvim/lazy-lock.json.
  Log 'Restoring plugins from lazy-lock.json (first run compiles Treesitter parsers, be patient)'
  Step 'nvim --headless "+Lazy! restore" +qa' {
    & nvim --headless '+Lazy! restore' +qa
    if ($LASTEXITCODE -ne 0) { Warn 'Lazy restore reported issues (often fine on first run)' }
  }
  Log 'Installing Mason tools not covered by ensure_installed'
  Step 'nvim --headless +MasonInstall ...' {
    & nvim --headless '+MasonInstall stylua debugpy netcoredbg codelldb shfmt csharpier' +qa
    if ($LASTEXITCODE -ne 0) { Warn 'some Mason tools failed; open nvim and run :Mason to retry' }
  }
  Log 'Updating Treesitter parsers'
  Step 'nvim --headless TSUpdate' {
    & nvim --headless "+lua require('nvim-treesitter').update():wait(600000)" +qa
    if ($LASTEXITCODE -ne 0) { Warn 'TSUpdate reported issues' }
  }
}

# ---------------------------------------------------------------------------
Write-Host ''
if ($Failures.Count) {
  Warn "These packages failed and were skipped: $($Failures -join ', ')"
  Warn 'Re-run the script to retry them; everything else is unaffected.'
} else {
  Write-Host 'Install complete.' -ForegroundColor Green
}
@"

Next steps:
  1. Open a new terminal (WezTerm, or pwsh) to pick up PATH and the profile.
  2. Set git identity in ~/.gitconfig.local if it still says CHANGE ME.
  3. nvim, then :checkhealth to confirm providers.
  4. Secrets go in ~/.pwsh.local.ps1, never in this repo.

Linux-only parts not used on Windows: zsh, bash, zellij, btop, GNOME.
"@ | Write-Host
