-- Enhanced init.lua
-- Performance monitoring start

-- Load core configuration
require 'options'
require 'keymaps'
require 'lazy-bootstrap'
require 'lazy-plugins'
require 'selected-theme'


-- Load enhanced utilities
-- local performance = require('utils.performance')
-- local project = require('utils.project')
-- local error_handler = require('utils.error_handler')

-- Setup enhanced features
-- performance.setup()
-- project.setup()
-- error_handler.setup()

-- Windows compatibility: Ensure PowerShell is set as the default shell in plugins/toggleterm.lua
-- Some plugins may require additional setup or dependencies on Windows (see plugin configs)
vim.o.background = "dark"
