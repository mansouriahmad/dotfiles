# PowerShell profile -- the Windows counterpart of zsh/zshrc.
# Dot-sourced from the pwsh 7 $PROFILE (install.ps1 adds the line). Also works
# in Windows PowerShell 5.1. Secrets go in ~/.pwsh.local.ps1, never here.

$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

# Vi mode, like `bindkey -v` in zshrc: Esc enters normal mode, with a block
# cursor in normal mode and a beam in insert mode.
if (Get-Module -ListAvailable -Name PSReadLine) {
  try {
    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
      param($mode)
      if ($mode -eq 'Command') { Write-Host -NoNewline "$([char]27)[2 q" }
      else                     { Write-Host -NoNewline "$([char]27)[6 q" }
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -Function ReverseSearchHistory -ViMode Insert
    Set-PSReadLineKeyHandler -Chord 'Tab' -Function MenuComplete
  } catch {
    # PSReadLine older than 2.0 (Windows Server 2016's inbox copy) lacks these.
  }
}

# eza backs ls/ll/la/lt, as in zshrc. `ls` is a built-in alias, so drop it first.
if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
  Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
  function ls { eza @args }
  function ll { eza -lh --icons --git @args }
  function la { eza -la --icons --git @args }
  function lt { eza --tree --level=2 @args }
}

# Conda: hooked lazily on first use. `conda shell.powershell hook` costs about
# a second, too much for every new prompt. auto_activate is off in condarc.
$condaRoot = if ($env:CONDA_ROOT) { $env:CONDA_ROOT } else { Join-Path $HOME 'miniconda3' }
if (Test-Path (Join-Path $condaRoot 'Scripts\conda.exe')) {
  function conda {
    Remove-Item Function:conda
    (& (Join-Path $condaRoot 'Scripts\conda.exe') 'shell.powershell' 'hook') | Out-String | Invoke-Expression
    conda @args
  }
}

# Starship last among prompt changes, so it wraps the final prompt function.
if (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue) {
  Invoke-Expression (& starship init powershell --print-full-init | Out-String)
}

$localProfile = Join-Path $HOME '.pwsh.local.ps1'
if (Test-Path $localProfile) { . $localProfile }
Remove-Variable localProfile -ErrorAction SilentlyContinue
