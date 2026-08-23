local platform = require('platform')

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      -- Standard IDE function keys (same as VS Code / IntelliJ)
      { "<F5>", function() require("dap").continue() end, desc = "Continue / Start" },
      { "<S-F5>", function() require("dap").terminate() end, desc = "Stop" },
      { "<C-S-F5>", function() require("dap").run_last() end, desc = "Restart (Run Last)" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<S-F9>", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional Breakpoint" },
      { "<F10>", function()  require("dap").step_over() end, desc = "Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Step Into" },
      { "<S-F11>", function() require("dap").step_out() end, desc = "Step Out" },

      -- Leader-based alternatives (always work, no terminal key issues)
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>dT", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Hover Variables", mode = { "n", "v" } },
      { "<leader>dp", function() require("dap.ui.widgets").preview() end, desc = "Preview", mode = { "n", "v" } },
      { "<leader>dR", desc = "Debug Rust Target (picker)" },
      { "<leader>dt", desc = "Debug Test Under Cursor" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.35 },
              { id = "breakpoints", size = 0.15 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            position = "bottom",
            size = 10,
          },
        },
      })

      require("nvim-dap-virtual-text").setup({
        commented = true,
      })

      -- Auto open/close DAP UI when debugging starts/stops
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Breakpoint signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "●", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })

      -- ============================================
      -- Persistent breakpoints (survive Neovim restarts)
      -- ============================================
      local breakpoints = require("dap.breakpoints")
      local bp_file = vim.fn.stdpath("data") .. "/dap_breakpoints.json"

      --- Save all breakpoints to disk
      local function save_breakpoints()
        local bps = breakpoints.get()
        local data = {}
        for bufnr, buf_bps in pairs(bps) do
          local uri = vim.uri_from_bufnr(bufnr)
          if uri and #buf_bps > 0 then
            data[uri] = {}
            for _, bp in ipairs(buf_bps) do
              table.insert(data[uri], {
                line = bp.line,
                condition = bp.condition,
                log_message = bp.logMessage,
                hit_condition = bp.hitCondition,
              })
            end
          end
        end
        local json = vim.fn.json_encode(data)
        local f = io.open(bp_file, "w")
        if f then
          f:write(json)
          f:close()
        end
      end

      --- Restore breakpoints for a buffer
      local function restore_breakpoints_for_buf(bufnr)
        local f = io.open(bp_file, "r")
        if not f then return end
        local content = f:read("*a")
        f:close()
        if content == "" then return end

        local ok_json, data = pcall(vim.fn.json_decode, content)
        if not ok_json or not data then return end

        local uri = vim.uri_from_bufnr(bufnr)
        if not data[uri] then return end

        for _, bp in ipairs(data[uri]) do
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          if bp.line and bp.line <= line_count then
            dap.set_breakpoint(bp.condition, bp.hit_condition, bp.log_message)
            -- set_breakpoint uses current cursor, so we need to use the lower-level API
            breakpoints.set({
              condition = bp.condition,
              logMessage = bp.log_message,
              hitCondition = bp.hit_condition,
            }, bufnr, bp.line)
          end
        end
      end

      -- Auto-save breakpoints whenever they change
      local bp_augroup = vim.api.nvim_create_augroup("DapPersistBreakpoints", { clear = true })

      -- Save on breakpoint toggle (hook into DAP)
      local orig_toggle = dap.toggle_breakpoint
      dap.toggle_breakpoint = function(...)
        orig_toggle(...)
        vim.defer_fn(save_breakpoints, 100)
      end

      local orig_set_bp = dap.set_breakpoint
      dap.set_breakpoint = function(...)
        orig_set_bp(...)
        vim.defer_fn(save_breakpoints, 100)
      end

      -- Restore breakpoints when opening a buffer
      vim.api.nvim_create_autocmd("BufReadPost", {
        group = bp_augroup,
        callback = function(args)
          -- Defer to ensure buffer is fully loaded
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              restore_breakpoints_for_buf(args.buf)
            end
          end, 200)
        end,
      })

      -- Save breakpoints on exit
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = bp_augroup,
        callback = save_breakpoints,
      })

      -- Python debugger (uses debugpy)
      -- Strategy: Use Mason's debugpy for the adapter (guaranteed to have debugpy),
      -- but run the user's code with the project's Python interpreter.
      local ok, dap_python = pcall(require, "dap-python")
      if ok then
        -- Use Mason's debugpy — it always has the debugpy module
        local debugpy_python = platform.venv_python(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv")
        if vim.fn.executable(debugpy_python) ~= 1 then
          vim.notify("debugpy not found! Run :MasonInstall debugpy", vim.log.levels.WARN)
          debugpy_python = platform.python()
        end
        dap_python.setup(debugpy_python)

        --- Detect the project's Python interpreter (for running user code)
        local function detect_project_python()
          -- 1. Active virtual environment (venv, poetry, pipenv)
          if vim.env.VIRTUAL_ENV then
            local venv_py = platform.venv_python(vim.env.VIRTUAL_ENV)
            if vim.fn.executable(venv_py) == 1 then
              return venv_py
            end
          end

          -- 2. Active conda env (but NOT the base env)
          if vim.env.CONDA_PREFIX and vim.env.CONDA_DEFAULT_ENV and vim.env.CONDA_DEFAULT_ENV ~= "base" then
            local conda_py = platform.venv_python(vim.env.CONDA_PREFIX)
            if vim.fn.executable(conda_py) == 1 then
              return conda_py
            end
          end

          -- 3. Project-local .venv or venv directory
          local cwd = vim.fn.getcwd()
          for _, dir in ipairs({ ".venv", "venv", ".env", "env" }) do
            local local_py = platform.venv_python(cwd .. "/" .. dir)
            if vim.fn.executable(local_py) == 1 then
              return local_py
            end
          end

          -- 4. python on PATH
          local py = vim.fn.exepath(platform.python())
          if py ~= "" then return py end

          return platform.python()
        end

        -- Override dap-python configurations to use the project's Python for execution
        -- while Mason's debugpy handles the adapter side
        local project_python = detect_project_python()

        -- Patch all python configurations to use the project interpreter
        dap.listeners.before.event_initialized["dap_python_path"] = function(_, body)
          for _, config in ipairs(dap.configurations.python or {}) do
            if not config._pythonPath_set then
              local orig_python_path = config.pythonPath
              config.pythonPath = function()
                if type(orig_python_path) == "function" then
                  return orig_python_path()
                end
                return project_python
              end
              config._pythonPath_set = true
            end
          end
        end

        -- Also set pythonPath on all default configs right away
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "python",
          once = true,
          callback = function()
            project_python = detect_project_python()
            for _, config in ipairs(dap.configurations.python or {}) do
              config.pythonPath = project_python
              config.console = "integratedTerminal"
            end
            vim.notify("DAP: adapter=" .. debugpy_python .. "\nDAP: project=" .. project_python, vim.log.levels.INFO)
          end,
        })

        -- Keymap to switch project Python for debugging
        vim.keymap.set("n", "<leader>dP", function()
          vim.ui.input({ prompt = "Project Python path: ", default = project_python, completion = "file" }, function(input)
            if input and input ~= "" then
              project_python = input
              for _, config in ipairs(dap.configurations.python or {}) do
                config.pythonPath = project_python
              end
              vim.notify("DAP project Python set to: " .. project_python, vim.log.levels.INFO)
            end
          end)
        end, { desc = "Set Python for debugger" })
      end

      -- .NET / C# debugger (netcoredbg)
      -- try to discover a suitable adapter in an OS‑independent way; prefer
      -- Mason's copy but fall back to whatever is on PATH, and warn if neither
      -- is available.
      local function find_netcoredbg()
        local mason_base = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg"
        local exe = "netcoredbg"
        if vim.fn.has("win32") == 1 then
          exe = "netcoredbg.exe"
        end
        local candidate = mason_base .. "/" .. exe
        if vim.fn.executable(candidate) == 1 then
          return candidate
        end
        local path = vim.fn.exepath("netcoredbg")
        if path ~= "" then
          return path
        end
        return nil
      end

      local netcoredbg_path = find_netcoredbg()
      if not netcoredbg_path then
        vim.notify("netcoredbg not found! Run :MasonInstall netcoredbg or add it to your PATH", vim.log.levels.WARN)
        netcoredbg_path = "netcoredbg" -- let DAP attempt to execute it anyway
      end

      dap.adapters.netcoredbg = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }

      -- collect all plausible DLLs under bin/**/*/net*/*.dll
      -- this is intentionally broad; we’ll let the user choose the right one.
      local function find_dotnet_dlls()
        local cwd = vim.fn.getcwd()
        local base = cwd .. "/bin"
        -- globpath returns a list when the final argument is true
        local dlls = vim.fn.globpath(base, "**/net*/*.dll", false, true)
        if not dlls or vim.tbl_isempty(dlls) then
          vim.notify("No DLLs found under bin/ – make sure the project has been built", vim.log.levels.INFO)
          return {}
        end
        return dlls
      end

      -- prompt the user with a picker if there are multiple candidates
      local function choose_from_list(list, prompt)
        if not list or #list == 0 then
          return nil
        elseif #list == 1 then
          return list[1]
        end
        local choice = nil
        vim.ui.select(list, { prompt = prompt }, function(item)
          choice = item
        end)
        return choice
      end

      dap.configurations.cs = {
        {
          type = "netcoredbg",
          name = "Launch .NET",
          request = "launch",
          program = function()
            local candidates = find_dotnet_dlls()
            local dll = choose_from_list(candidates, "Select DLL to debug:")
            if dll then
              return dll
            end
            return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- codelldb adapter (used by Rust, C, C++)
      -- Auto-detect codelldb from Mason install path or fall back to PATH
      local codelldb_path = "codelldb"
      local mason_codelldb = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
      if vim.fn.executable(mason_codelldb) == 1 then
        codelldb_path = mason_codelldb
      end

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb_path,
          args = { "--port", "${port}" },
        },
      }

      -- ============================================
      -- Rust: Auto-discover cargo targets (VS Code-like)
      -- ============================================

      --- Get all cargo targets using `cargo metadata`
      ---@return table[] list of {name, kind, src_path}
      local function get_cargo_targets()
        local metadata_json, code = platform.run({ "cargo", "metadata", "--no-deps", "--format-version", "1" })
        if code ~= 0 then
          return {}
        end
        local metadata = vim.fn.json_decode(metadata_json)
        if not metadata or not metadata.packages then
          return {}
        end

        local targets = {}
        for _, pkg in ipairs(metadata.packages) do
          for _, target in ipairs(pkg.targets or {}) do
            table.insert(targets, {
              name = target.name,
              kind = target.kind[1], -- "bin", "lib", "example", "test", "bench"
              src_path = target.src_path,
              package = pkg.name,
            })
          end
        end
        return targets
      end

      --- Build a cargo target and return the compiled binary path
      ---@param target_name string
      ---@param kind string
      ---@return string|nil
      local function build_and_get_binary(target_name, kind)
        local build_args = { "cargo", "build", "--message-format=json" }

        if kind == "bin" then
          table.insert(build_args, "--bin")
          table.insert(build_args, target_name)
        elseif kind == "example" then
          table.insert(build_args, "--example")
          table.insert(build_args, target_name)
        elseif kind == "test" then
          table.insert(build_args, "--test")
          table.insert(build_args, target_name)
        elseif kind == "bench" then
          table.insert(build_args, "--bench")
          table.insert(build_args, target_name)
        else
          -- lib or unknown — build the whole package
          table.insert(build_args, "--lib")
        end

        vim.notify("Building " .. kind .. ": " .. target_name .. "...", vim.log.levels.INFO)
        local output, code = platform.run(build_args)

        if code ~= 0 then
          vim.notify("Cargo build failed!\n" .. output, vim.log.levels.ERROR)
          return nil
        end

        -- Parse JSON lines to find the compiled executable
        for line in output:gmatch("[^\n]+") do
          local ok_json, artifact = pcall(vim.fn.json_decode, line)
          if ok_json and artifact and artifact.reason == "compiler-artifact" then
            if artifact.executable and artifact.executable ~= vim.NIL then
              return artifact.executable
            end
          end
        end

        vim.notify("Could not find compiled binary for: " .. target_name, vim.log.levels.ERROR)
        return nil
      end

      --- Show a picker with all cargo targets and launch the debugger
      local function rust_debug_picker()
        local targets = get_cargo_targets()
        if #targets == 0 then
          vim.notify("No cargo targets found. Are you in a Rust project?", vim.log.levels.WARN)
          return
        end

        -- Build display items
        local items = {}
        for _, t in ipairs(targets) do
          -- Only show debuggable targets (bins, examples, tests)
          if t.kind == "bin" or t.kind == "example" or t.kind == "test" or t.kind == "bench" then
            table.insert(items, {
              label = string.format("[%s] %s", t.kind, t.name),
              target = t,
            })
          end
        end

        if #items == 0 then
          vim.notify("No runnable targets (bin/example/test) found.", vim.log.levels.WARN)
          return
        end

        -- If only one target, launch immediately
        if #items == 1 then
          local binary = build_and_get_binary(items[1].target.name, items[1].target.kind)
          if binary then
            dap.run({
              name = items[1].target.name,
              type = "codelldb",
              request = "launch",
              program = binary,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
            })
          end
          return
        end

        -- Show picker
        vim.ui.select(items, {
          prompt = "Select cargo target to debug:",
          format_item = function(item) return item.label end,
        }, function(choice)
          if not choice then return end
          local binary = build_and_get_binary(choice.target.name, choice.target.kind)
          if binary then
            dap.run({
              name = choice.target.name,
              type = "codelldb",
              request = "launch",
              program = binary,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
            })
          end
        end)
      end

      --- Debug the test under cursor
      local function rust_debug_test_under_cursor()
        local test_name = nil
        local current_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_get_lines(0, 0, current_line, false)

        -- Walk backwards to find the nearest #[test] fn
        for i = #lines, 1, -1 do
          local fn_match = lines[i]:match("fn%s+([%w_]+)")
          if fn_match then
            -- Check if there's a #[test] or #[tokio::test] above it
            for j = i - 1, math.max(1, i - 5), -1 do
              if lines[j]:match("#%[test%]") or lines[j]:match("#%[tokio::test%]") or lines[j]:match("#%[rstest%]") then
                test_name = fn_match
                break
              end
            end
            if test_name then break end
          end
        end

        if not test_name then
          vim.notify("No test function found above cursor", vim.log.levels.WARN)
          return
        end

        vim.notify("Building test: " .. test_name .. "...", vim.log.levels.INFO)

        -- Build tests and get the test binary
        local output = platform.run({ "cargo", "test", "--no-run", "--message-format=json" })
        local test_binary = nil

        for line in output:gmatch("[^\n]+") do
          local ok_json, artifact = pcall(vim.fn.json_decode, line)
          if ok_json and artifact and artifact.reason == "compiler-artifact" then
            if artifact.executable and artifact.executable ~= vim.NIL then
              -- Use the last test executable found
              if artifact.profile and artifact.profile.test then
                test_binary = artifact.executable
              end
            end
          end
        end

        if not test_binary then
          vim.notify("Could not find test binary", vim.log.levels.ERROR)
          return
        end

        dap.run({
          name = "Debug test: " .. test_name,
          type = "codelldb",
          request = "launch",
          program = test_binary,
          args = { "--exact", test_name, "--nocapture" },
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        })
      end

      -- Expose Rust debug commands as keymaps
      vim.keymap.set("n", "<leader>dR", rust_debug_picker, { desc = "Debug Rust Target (picker)" })
      vim.keymap.set("n", "<leader>dt", rust_debug_test_under_cursor, { desc = "Debug Test Under Cursor" })

      -- .NET launch helper using the fuzzy picker logic
      vim.keymap.set("n", "<leader>dN", function()
        local candidates = find_dotnet_dlls()
        local dll = choose_from_list(candidates, "Select DLL to debug:")
        dap.run({
          type = "netcoredbg",
          name = "Launch .NET",
          request = "launch",
          program = dll or vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file"),
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        })
      end, { desc = ".NET debug (auto‑detect dll)" })
      -- build-and-debug helper invoked on F5
      local function build_and_debug()
        -- if a session already exists, just continue/resume it
        if dap.session() then
          dap.continue()
          return
        end

        local ft = vim.bo.filetype
        if ft == "rust" then
          -- rust_debug_picker already builds & starts
          rust_debug_picker()
        elseif ft == "cs" or ft == "csharp" then
          -- ensure dotnet CLI is available
          if vim.fn.exepath("dotnet") == "" then
            vim.notify("dotnet CLI not found; cannot build project", vim.log.levels.ERROR)
          else
            vim.notify("dotnet build (Debug) invoked", vim.log.levels.INFO)
            vim.fn.system("dotnet build -c Debug")
          end
          -- replicate the picker logic from the main configuration
          local candidates = find_dotnet_dlls()
          local dll = choose_from_list(candidates, "Select DLL to debug:")
          dap.run({
            type = "netcoredbg",
            name = "Launch .NET",
            request = "launch",
            program = dll or vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file"),
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
          })
        else
          -- fallback to continue (attach or restart) for other languages
          dap.continue()
        end
      end
      -- override F5 to build & start where appropriate
      vim.keymap.set("n", "<F5>", build_and_debug, { desc = "Build + Debug" })

      -- C/C++ still uses manual path selection; offer fuzzy pick if multiple
      local function choose_executable(default_dir)
        -- look for binaries under target/debug, target/release, or current dir
        local search = vim.fn.glob(default_dir .. "**/*", false, true)
        if type(search) == "string" then
          search = vim.split(search, "\n")
        end
        local files = {}
        for _, f in ipairs(search) do
          if vim.fn.executable(f) == 1 then
            table.insert(files, f)
          end
        end
        return choose_from_list(files, "Select executable to debug:")
      end

      dap.configurations.c = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            local exe = choose_executable(vim.fn.getcwd() .. "/")
            if exe then
              return exe
            end
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.cpp = dap.configurations.c
    end,
  },
}
