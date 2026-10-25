-- C / C++ build and run helpers (Linux, macOS, Windows).
--
-- Two modes, picked automatically:
--   * CMake project (a CMakeLists.txt above the file): configure + build into
--     <root>/build in Debug, with compile_commands.json for clangd.
--   * Single file: compile just this file with debug info and, outside Windows,
--     AddressSanitizer + UBSan. Output goes to Neovim's cache dir, not the repo.
--
-- Keymaps (C/C++ buffers only):
--   <leader>cr  compile + run this file        <leader>cb  CMake build
--   <leader>cR  CMake build + run a target     <F5>        build + debug (dap.lua)

local platform = require("platform")

local M = {}

local exe_suffix = platform.is_windows and ".exe" or ""

--- First compiler found on PATH for the language.
local function compiler(is_c)
  local list = is_c and { "clang", "gcc", "cc" } or { "clang++", "g++", "c++" }
  for _, c in ipairs(list) do
    if vim.fn.executable(c) == 1 then
      return c
    end
  end
  return nil
end

--- Put compiler output in the quickfix list (gcc/clang format) and open it.
local function to_quickfix(text, title)
  local lines = vim.split(text or "", "\n", { trimempty = true })
  vim.fn.setqflist({}, " ", { title = title, lines = lines, efm = vim.o.errorformat })
  vim.cmd("botright copen")
end

--- Run argv in a terminal split at the bottom.
local function run_in_terminal(argv, cwd)
  vim.cmd("botright 15split")
  vim.cmd("enew")
  vim.fn.jobstart(argv, { term = true, cwd = cwd })
  vim.cmd("startinsert")
end

--- Root of the CMake project containing the current buffer, or nil.
function M.cmake_root()
  local root = vim.fs.root(0, "CMakeLists.txt")
  if not root then
    return nil
  end
  -- Walk up to the outermost CMakeLists.txt (subdirectories have their own).
  local parent = vim.fs.root(vim.fs.dirname(root), "CMakeLists.txt")
  while parent and parent ~= root do
    root = parent
    parent = vim.fs.root(vim.fs.dirname(root), "CMakeLists.txt")
  end
  return root
end

--- Compile the current file. Calls on_done(exe_path) on success.
function M.compile_file(on_done)
  vim.cmd("silent! write")
  local file = vim.api.nvim_buf_get_name(0)
  local is_c = vim.bo.filetype == "c"
  local cc = compiler(is_c)
  if not cc then
    vim.notify("No C/C++ compiler on PATH (install clang or gcc)", vim.log.levels.ERROR)
    return
  end

  local out_dir = vim.fn.stdpath("cache") .. "/cpp-run"
  vim.fn.mkdir(out_dir, "p")
  local exe = out_dir .. "/" .. vim.fn.fnamemodify(file, ":t:r") .. exe_suffix

  local args = { cc, is_c and "-std=c17" or "-std=c++20", "-g", "-O0", "-Wall", "-Wextra", "-pedantic" }
  if not platform.is_windows then
    vim.list_extend(args, { "-fsanitize=address,undefined", "-fno-omit-frame-pointer" })
  end
  vim.list_extend(args, { file, "-o", exe })
  if not is_c and not platform.is_windows then
    table.insert(args, "-pthread")
  end

  vim.system(args, { text = true }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      to_quickfix(res.stderr, "compile " .. vim.fn.fnamemodify(file, ":t"))
      return
    end
    if res.stderr and res.stderr ~= "" then
      to_quickfix(res.stderr, "warnings") -- compiled, but show warnings
    end
    on_done(exe)
  end))
end

--- Executables under <root>/build (skips CMake's own files).
function M.find_executables(build_dir)
  local found = {}
  for name, kind in vim.fs.dir(build_dir, { depth = 4 }) do
    local path = build_dir .. "/" .. name
    if kind == "file" and not name:find("CMakeFiles", 1, true) then
      local ok = platform.is_windows and name:match("%.exe$")
        or (vim.fn.executable(path) == 1 and not name:match("%.so[%.%d]*$") and not name:match("%.dylib$"))
      if ok then
        table.insert(found, path)
      end
    end
  end
  table.sort(found)
  return found
end

--- Configure (first time) and build. Calls on_done(root) on success.
function M.cmake_build(on_done)
  local root = M.cmake_root()
  if not root then
    vim.notify("No CMakeLists.txt above this file", vim.log.levels.WARN)
    return
  end
  vim.cmd("silent! wall")
  local build = root .. "/build"
  local configure = {
    "cmake", "-S", root, "-B", build,
    "-DCMAKE_BUILD_TYPE=Debug", "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
  }
  vim.notify("CMake: building " .. vim.fn.fnamemodify(root, ":t") .. " ...", vim.log.levels.INFO)
  vim.system(configure, { text = true }, function(cfg)
    if cfg.code ~= 0 then
      vim.schedule(function() to_quickfix(cfg.stdout .. cfg.stderr, "cmake configure") end)
      return
    end
    vim.system({ "cmake", "--build", build, "--config", "Debug", "--parallel" }, { text = true },
      vim.schedule_wrap(function(res)
        if res.code ~= 0 then
          to_quickfix(res.stdout .. res.stderr, "cmake build")
          return
        end
        vim.notify("CMake: build OK", vim.log.levels.INFO)
        if on_done then on_done(root) end
      end))
  end)
end

--- Build, then let the user pick a target. Calls on_pick(exe).
local function cmake_pick(on_pick)
  M.cmake_build(function(root)
    local exes = M.find_executables(root .. "/build")
    if #exes == 0 then
      vim.notify("No executables found in build/", vim.log.levels.WARN)
    elseif #exes == 1 then
      on_pick(exes[1])
    else
      vim.ui.select(exes, {
        prompt = "Target:",
        format_item = function(p) return vim.fn.fnamemodify(p, ":.") end,
      }, function(choice)
        if choice then on_pick(choice) end
      end)
    end
  end)
end

--- Used by <F5>: CMake project if there is one, otherwise the current file.
function M.build_for_debug(on_exe)
  if M.cmake_root() then
    cmake_pick(on_exe)
  else
    M.compile_file(on_exe)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("CppTools", { clear = true }),
    pattern = { "c", "cpp" },
    callback = function(ev)
      local map = function(lhs, fn, desc)
        vim.keymap.set("n", lhs, fn, { buffer = ev.buf, desc = desc })
      end
      map("<leader>cr", function()
        M.compile_file(function(exe) run_in_terminal({ exe }) end)
      end, "Compile + run this file")
      map("<leader>cb", function() M.cmake_build() end, "CMake build (Debug)")
      map("<leader>cR", function()
        cmake_pick(function(exe) run_in_terminal({ exe }, M.cmake_root()) end)
      end, "CMake build + run target")
    end,
  })
end

return M
