-- main module file
local core = require("haken.core")

---@class Config
---@field column_sensitive boolean
---@field clear_jumplists boolean
---@field clear_on_new_window? boolean
local config = {
  column_sensitive = false,
  clear_jumplists = false,
  clear_on_new_window = false,
}

---@class Haken
local M = {}
M.name = "haken"
M.version = "0.0.1"

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
  -- reset jumplist on startup
  args = args or {}

  if args.clear_jumplists == true then
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.cmd("bufdo clearjumps")
      end,
    })
  end
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  core.setup(M.config)
end

-- core functions
M.add_haken = core.add_haken
M.clear_hakens = core.clear_hakens
M.show_hakens = core.show_hakens

return M
