-- Utility functions for Haken plugin

---@class HakenPosition
---@field bufnr integer
---@field lnum integer
---@field col integer
---@field filename string?

---@class HakenUtils
local M = {}

-- parse a given position to a key
---@param pos HakenPosition
---@return string
function M.position_to_key(pos)
  return string.format("%d:%d:%d", pos.bufnr, pos.lnum, pos.col)
end

-- Get current cursor position
---@return HakenPosition
function M.get_current_position()
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return {
    bufnr = buf,
    lnum = cursor[1],
    col = cursor[2],
    filename = vim.api.nvim_buf_get_name(buf),
  }
end

-- Compare two positions for equality
---@param pos1 HakenPosition
---@param pos2 HakenPosition
---@param ignore_col boolean?
---@return boolean
function M.positions_equal(pos1, pos2, ignore_col)
  ignore_col = ignore_col or true
  return pos1.bufnr == pos2.bufnr and pos1.lnum == pos2.lnum and (pos1.col == pos2.col or ignore_col)
end

-- Get the current jumplist
---@return table[] jumps, integer current_index
function M.get_jumplist()
  local jumplist = vim.fn.getjumplist()
  return jumplist[1], jumplist[2] -- jumps table, current index
end

-- Print a message to the user (wraps print but checks if silent)
---@param print_msg string
---@param silent? boolean
function M.print(print_msg, silent)
  silent = silent or false
  if not silent then
    return print(print_msg)
  end
end

-- Create a hashtable for jump positions to avoid duplicates
---@param jumps HakenPosition[]
---@param cutoff_idx integer
---@return table<string, integer> jump_hashtable
function M.jumps_to_hashtable(jumps, cutoff_idx)
  ---@type table<string, integer>
  local jump_hashtable = {}
  for i = cutoff_idx, 1, -1 do
    local jump = jumps[i]
    local key = M.position_to_key(jump)
    if not jump_hashtable[key] then
      -- Only store the latest occurrence of a position in the jumplist
      jump_hashtable[key] = i
    end
  end
  return jump_hashtable
end

return M
