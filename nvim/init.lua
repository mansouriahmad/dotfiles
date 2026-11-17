-- Enhanced init.lua
-- Performance monitoring start

-- Load core configuration
require 'options'
require 'keymaps'
require 'lazy-bootstrap'
require 'lazy-plugins'
require 'selected-theme'
require('cpp-tools').setup()


-- Load enhanced utilities
-- local performance = require('utils.performance')
-- local project = require('utils.project')
-- local error_handler = require('utils.error_handler')

-- Setup enhanced features
-- performance.setup()
-- project.setup()
-- error_handler.setup()

-- Windows: PowerShell 7 is set as 'shell' in options.lua; OS differences live
-- in lua/platform.lua. windows/install.ps1 installs what the plugins need.
vim.o.background = "dark"
