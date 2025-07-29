-- Core functionality for Haken (Jumplist Cutting)

---@class HakenCore
---@field column_sensitive? boolean
local M = {}
local utils = require("haken.utils")

---@type table<integer, HakenPosition[]>
local jumplist_at_last_haken = {}

-- Table to store haken positions
---@type table<integer, HakenPosition[]>
local hakens = {}

---@param win_id integer
---@param cutoff_index? integer
function M.clean_hakens(win_id, cutoff_index)
  local jumps, current_index = utils.get_jumplist()
  cutoff_index = cutoff_index or current_index

  if not hakens[win_id] then
    return
  end

  local win_hakens = hakens[win_id]
  local jump_hashtable = utils.jumps_to_hashtable(jumps, cutoff_index)
  -- Remove all hakens that are after the current index in the jumplist
  for i = #win_hakens, 1, -1 do
    local haken = win_hakens[i]
    local key = utils.position_to_key(haken)
    -- If the haken is not in the jumplist or after the cutoff index, remove
    if not jump_hashtable[key] or jump_hashtable[key] > cutoff_index then
      table.remove(win_hakens, i)
    end
  end
end

-- Remove jumplist entries after a specific index
---@param jumplist HakenPosition[]
local function set_jumplist(jumplist)
  local current_buf = vim.api.nvim_get_current_buf()
  local original_pos = vim.api.nvim_win_get_cursor(0)

  vim.cmd("clearjumps")

  for _, jump in ipairs(jumplist) do
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

-- Remove jumplist entries after a specific index
---@param target_index? integer
local function remove_entries_after_index(target_index)
  if not target_index then
    return
  end
  local jumps, _ = utils.get_jumplist()
  if target_index > #jumps then
    error("Target index: " .. target_index .. "exceeds jumplist length: " .. #jumps)
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

-- Prune the jumplist to the current index
function M.prune_jumps()
  local view_state = vim.fn.winsaveview()
  local _, current_index = utils.get_jumplist()
  remove_entries_after_index(current_index)
  -- write current jumps
  local jumps, _ = utils.get_jumplist()
  local win_id = vim.api.nvim_get_current_win()
  jumplist_at_last_haken[win_id] = jumps
  -- Add current position to jumplist
  local current_pos = utils.get_current_position()
  table.insert(jumplist_at_last_haken[win_id], {
    bufnr = current_pos.bufnr,
    lnum = current_pos.lnum,
    col = current_pos.col,
  })
  set_jumplist(jumplist_at_last_haken[win_id])
  -- clean up hakens
  M.clean_hakens(win_id, current_index)
  vim.fn.winrestview(view_state)
  local filename = current_pos.filename ~= "" and vim.fn.fnamemodify(current_pos.filename, ":t") or "[No Name]"
  utils.print(
    "Jumplist pruned, previous jump at " .. filename .. ":" .. current_pos.lnum .. ":" .. current_pos.col,
    M.config.silent
  )
end

-- Add haken
function M.add_haken()
  -- Save view state to restore at function end
  local view_state = vim.fn.winsaveview()
  local win_id = vim.api.nvim_get_current_win()

  if not hakens[win_id] then
    hakens[win_id] = {}
  end
  local win_hakens = hakens[win_id]

  -- save current position and window
  local current_pos = utils.get_current_position()

  -- Check if current position is same as last haken
  if #win_hakens > 0 then
    local last_manual = win_hakens[#win_hakens]
    if utils.positions_equal(current_pos, last_manual, not M.config.column_sensitive) then
      utils.print("haken not added - position unchanged", M.config.silent)
      return
    end
  end
  if not jumplist_at_last_haken[win_id] then
    local curr_jumps, _ = utils.get_jumplist()
    jumplist_at_last_haken[win_id] = curr_jumps
  end
  current_pos = utils.get_current_position()

  -- Add current position to jumplist
  table.insert(jumplist_at_last_haken[win_id], {
    bufnr = current_pos.bufnr,
    lnum = current_pos.lnum,
    col = current_pos.col,
  })
  set_jumplist(jumplist_at_last_haken[win_id])

  -- Track this as a haken
  table.insert(win_hakens, current_pos)

  local filename = current_pos.filename ~= "" and vim.fn.fnamemodify(current_pos.filename, ":t") or "[No Name]"

  --restore view state (for multiple windows)
  vim.fn.winrestview(view_state)

  utils.print("haken added: " .. filename .. ":" .. current_pos.lnum .. ":" .. current_pos.col, M.config.silent)
end

-- Clear manual entries
--@param win_id? integer
function M.clear_hakens(win_id)
  if not win_id then
    -- Clear all hakens
    hakens = {}
    jumplist_at_last_haken = {}
    return
  end
  hakens[win_id] = {}
end

---@return HakenPosition[]
function M.show_hakens()
  if vim.tbl_isempty(hakens) then
    utils.print("No manual jumplist entries found")
    return hakens
  end
  for win_id, win_hakens in pairs(hakens) do
    print(string.format("Window %d:", win_id))
    for i, haken in ipairs(win_hakens) do
      local filename = haken.filename ~= "" and vim.fn.fnamemodify(haken.filename, ":t") or "[No Name]"
      print(string.format("%d: %s:%d:%d", i, filename, haken.lnum, haken.col))
    end
  end
  return hakens
end

-- Setup function
---@param args? Config
function M.setup(args)
  args = args or {}
  M.config = args

  -- clear on new window automatically
  if M.config.clear_jumps_on_new_window then
    vim.api.nvim_create_autocmd("WinNew", {
      pattern = "*",
      callback = function()
        vim.cmd("clearjumps")
        M.clear_hakens(vim.api.nvim_get_current_win())
        utils.print("Manual jumplist entries cleared on new window", M.config.silent)
      end,
    })
  end

  vim.api.nvim_create_user_command("AddHaken", M.add_haken, {
    desc = "Add a haken",
  })

  vim.api.nvim_create_user_command("PruneJumps", function()
    M.prune_jumps()
  end, {
    desc = "Prune jumplist entries to the current index in the jumplist",
  })

  vim.api.nvim_create_user_command("ShowHakens", M.show_hakens, {
    desc = "Show all manual jumplist entries",
  })

  vim.api.nvim_create_user_command("ClearAllHakens", function()
    M.clear_hakens()
    print("Cleared hakens in all windows")
  end, {
    desc = "Clear Hakens in all windows",
  })
end

return M
