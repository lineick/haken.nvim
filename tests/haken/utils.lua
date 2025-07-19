-- Utility functions for Haken tests

---@class HakenTestUtils
local M = {}

---Ensures the current buffer has at least the given number of lines.
---@param len integer
function M.ensure_buffer_length(len)
  local curr_lines = vim.api.nvim_buf_line_count(0)
  if curr_lines < len then
    -- Add empty lines to reach desired length
    local to_add = {}
    for _ = 1, len - curr_lines do
      table.insert(to_add, "")
    end
    vim.api.nvim_buf_set_lines(0, curr_lines, curr_lines, false, to_add)
  end
end

return M
