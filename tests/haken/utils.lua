-- Utility functions for Haken tests

---@class HakenTestUtils
local M = {}
local core = require("haken.core")

---@param repeat_n_times integer repeat the pattern this many times
---@return string[]
function M.generate_foo_bar_lines(repeat_n_times)
  local pattern = {
    "foo bar. foo bar. foo bar. foo",
    "bar. foo bar.",
    "",
  }
  local result = {}
  local idx = 1
  for _ = 1, repeat_n_times do
    table.insert(result, pattern[idx])
    idx = idx % #pattern + 1
  end
  return result
end

---Creates a new buffer with the given lines and switches to it.
---@param lines string[]? Lines to insert into the buffer (default: 10 numbered lines)
function M.setup_test_buffer(lines)
  lines = lines or {}
  -- Create a new buffer and window
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", true, { buf = vim.api.nvim_get_current_buf() })
  -- Make sure it's a normal buffer
  vim.api.nvim_set_option_value("buftype", "", { buf = vim.api.nvim_get_current_buf() })
end

---run user input synchronously (instant)
---@param input string
local function exec_cmd(input)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(input, true, false, true),
    "nx",
    false
  )
end

---Executes a sequence of actions mapped from a string.
---@param actions string
function M.do_actions(actions)
  for i = 1, #actions do
    local c = actions:sub(i, i)
    if c == "h" then
      exec_cmd("h")
    elseif c == "j" then
      exec_cmd("j")
    elseif c == "k" then
      exec_cmd("k")
    elseif c == "l" then
      exec_cmd("l")
    elseif c == "i" then
      exec_cmd("<C-i>")
    elseif c == "o" then
      exec_cmd("<C-o>")
    elseif c == "H" then
      core.add_haken()
    elseif c == "}" then
      exec_cmd("}")
    elseif c == "{" then
      exec_cmd("{")
    elseif c == "(" then
      exec_cmd("(")
    elseif c == ")" then
      exec_cmd(")")
    elseif c == "d" then
      exec_cmd("dd")
    else
      error("Unknown action: " .. c)
    end
  end
end

return M
