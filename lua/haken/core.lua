-- Core functionality for Haken (Jumplist Cutting)

---@class HakenCore
---@field column_sensitive? boolean
local M = {}
local utils = require("haken.utils")

-- Table to store haken positions
---@type HakenPosition[]
local hakens = {}

-- Find the most recent haken in the jumplist
---@return integer|nil
local function find_last_haken_index()
  if #hakens == 0 then
    return nil
  end

  ---@type table[], integer
  local jumps, current_jump_idx = utils.get_jumplist()

  -- If jumplist is empty, no manual entries can be found
  if #jumps == 0 then
    return nil
  end

  -- Build a hash table for constant retrieval per haken
  -- 100 iterations at most (default jumplist length)
  ---@type integer|nil
  local latest_haken_index = nil
  ---@type table<string, integer>
  local jump_hashtable = {}

  for i = current_jump_idx, 1, -1 do
    local jump = jumps[i]
    local key = utils.position_to_key(jump)
    if not jump_hashtable[key] then
      -- Only store the latest occurrence of a position in the jumplist
      jump_hashtable[key] = i
    end
  end

  -- As hakens are kicked out as soon as they are not in the jumplist anymore,
  -- The #hakens is never larger than the jumplist length (100 by default)
  for i = #hakens, 1, -1 do
    local haken_pos = hakens[i]
    local key = utils.position_to_key(haken_pos)
    -- Check if this haken exists in the jumplist
    if jump_hashtable[key] then
      if not latest_haken_index then
        latest_haken_index = jump_hashtable[key]
      end
    else
      -- No matching entries found for this haken, so remove it
      table.remove(hakens, i)
    end
  end

  return latest_haken_index
end

-- Remove jumplist entries after a specific index
---@param target_index integer|nil
local function remove_entries_after_index(target_index)
  if not target_index then
    return
  end
  local jumps, current_jump_idx = utils.get_jumplist()
  if current_jump_idx < target_index then
    -- No entries to remove, as the target index is beyond current jump index
    return
  end

  -- Keep entries up to and including the target index
  ---@type table[]
  local entries_to_keep = {}
  for i = 1, target_index do
    if jumps[i] then
      table.insert(entries_to_keep, jumps[i])
    end
  end

  -- Clear and rebuild jumplist
  vim.cmd("clearjumps")

  local current_buf = vim.api.nvim_get_current_buf()
  local original_pos = vim.api.nvim_win_get_cursor(0)

  for _, jump in ipairs(entries_to_keep) do
    if vim.fn.bufexists(jump.bufnr) == 1 then
      vim.api.nvim_set_current_buf(jump.bufnr)
      vim.api.nvim_win_set_cursor(0, { jump.lnum, jump.col })
      vim.cmd("normal! m`")
    end
  end

  -- Return to original position
  vim.api.nvim_set_current_buf(current_buf)
  vim.api.nvim_win_set_cursor(0, original_pos)
end

-- Add haken
function M.add_haken()
  local current_pos = utils.get_current_position()

  -- Check if current position is same as last haken
  if #hakens > 0 then
    local last_manual = hakens[#hakens]
    if utils.positions_equal(current_pos, last_manual, not M.column_sensitive) then
      print("haken not added - position unchanged")
      return
    end
  end

  -- Check if a previous haken exists in the jumplist
  local last_manual_index = find_last_haken_index()

  if last_manual_index then
    -- Remove all entries after the last haken
    remove_entries_after_index(last_manual_index)
  end

  -- Add current position to jumplist
  vim.cmd("normal! m`")

  -- Track this as a haken
  table.insert(hakens, current_pos)

  local filename = current_pos.filename ~= "" and vim.fn.fnamemodify(current_pos.filename, ":t") or "[No Name]"
  print("haken added: " .. filename .. ":" .. current_pos.lnum)
end

-- Clear manual entries
function M.clear_hakens()
  hakens = {}
end

---@return HakenPosition[]
function M.show_hakens()
  if #hakens == 0 then
    print("No manual jumplist entries")
    return hakens
  end

  print("Manual jumplist entries:")
  for i, haken in ipairs(hakens) do
    local filename = haken.filename ~= "" and vim.fn.fnamemodify(haken.filename, ":t") or "[No Name]"
    print(string.format("%d: %s:%d:%d", i, filename, haken.lnum, haken.col))
  end
  return hakens
end

-- Setup function
---@param args? { column_sensitive?: boolean }
function M.setup(args)
  args = args or {}
  M.column_sensitive = args.column_sensitive

  vim.api.nvim_create_user_command("AddHaken", M.add_haken, {
    desc = "Add a haken",
  })

  vim.api.nvim_create_user_command("ShowHakens", M.show_hakens, {
    desc = "Show all manual jumplist entries",
  })

  vim.api.nvim_create_user_command("ClearHakens", function()
    M.clear_hakens()
    print("Manual jumplist entries cleared")
  end, {
    desc = "Clear manual jumplist entries tracking",
  })
end

return M
