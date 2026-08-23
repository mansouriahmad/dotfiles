-- Platform helpers.
--
-- Every function here returns exactly what the config already did on Linux and
-- macOS. The Windows branches exist only so the same config runs there without
-- a separate copy — nothing below changes POSIX behaviour.

local M = {}

M.is_windows = vim.fn.has('win32') == 1

--- Path to the interpreter inside a venv / conda prefix.
--- POSIX layouts put it at `bin/python`, Windows at `Scripts\python.exe`.
---@param prefix string venv root (VIRTUAL_ENV, CONDA_PREFIX, a mason package, ...)
---@return string
function M.venv_python(prefix)
  if M.is_windows then
    return prefix .. '/Scripts/python.exe'
  end
  return prefix .. '/bin/python'
end

--- Name of a python interpreter that actually exists on PATH here.
--- Windows installers ship `python`; macOS and most Linux ship only `python3`.
---@return string
function M.python()
  if vim.fn.exepath('python3') ~= '' then
    return 'python3'
  end
  return 'python'
end

--- Run a command without going through a shell and return its stdout.
---
--- Replaces `vim.fn.system("... 2>/dev/null")`. That redirect is POSIX-only and
--- errors under cmd.exe, and the whole reason it was there — keeping stderr out
--- of stdout so the JSON parses — is something `vim.system` does natively on
--- every platform. Note this does NOT set `v:shell_error`; use the second
--- return value instead.
---@param cmd string[] argv, no shell quoting needed
---@return string stdout, integer code
function M.run(cmd)
  local res = vim.system(cmd, { text = true }):wait()
  return res.stdout or '', res.code
end

return M
