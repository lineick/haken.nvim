describe("haken", function()
  local haken
  local core
  local test_utils

  before_each(function()
    -- Clear any existing state
    package.loaded['haken'] = nil
    package.loaded['haken.core'] = nil
    package.loaded['tests.haken.utils'] = nil

    haken = require('haken')
    core = require('haken.core')
    test_utils = require('tests.haken.utils')

    -- Clear any existing manual entries (haken)
    core.clear_hakens()

    -- Clear jumplist
    vim.cmd('clearjumps')
  end)

  describe("setup", function()
    it("should setup with default options", function()
      assert.has_no.errors(function()
        haken.setup()
      end)
    end)

    it("should create user commands", function()
      haken.setup()

      -- Check if commands exist
      local commands = vim.api.nvim_get_commands({})
      assert.is_not_nil(commands['AddHaken'])
      assert.is_not_nil(commands['ShowHakens'])
      assert.is_not_nil(commands['ClearAllHakens'])
    end)
  end)

  describe("add_haken", function()
    before_each(function()
      haken.setup()
    end)

    it("should add a haken", function()
      -- Move cursor to a specific position

      test_utils.ensure_buffer_length(10)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      -- Add manual entry
      core.add_haken()

      -- Check that entry was added
      local current_win_id = vim.api.nvim_get_current_win()
      local hakens = core.show_hakens()
      local win_hakens = hakens[current_win_id]

      assert.equals(1, #win_hakens)
      assert.equals(1, win_hakens[1].lnum)
      assert.equals(0, win_hakens[1].col)
    end)

    it("should not add duplicate entries at same position", function()
      -- Move cursor and add entry
      test_utils.ensure_buffer_length(10)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      core.add_haken()

      -- Try to add same position again
      core.add_haken()

      -- Should still only have one entry
      local current_win_id = vim.api.nvim_get_current_win()
      local hakens = core.show_hakens()
      local win_hakens = hakens[current_win_id]

      assert.equals(1, #win_hakens)
    end)

    it("should add multiple entries at different positions", function()
      -- Add first entry
      test_utils.ensure_buffer_length(10)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      core.add_haken()

      -- Add second entry at different position
      vim.api.nvim_win_set_cursor(0, { 5, 0 })
      core.add_haken()

      local current_win_id = vim.api.nvim_get_current_win()
      local hakens = core.show_hakens()
      local win_hakens = hakens[current_win_id]

      -- Should have two entries
      assert.equals(2, #win_hakens)
      assert.equals(1, win_hakens[1].lnum)
      assert.equals(5, win_hakens[2].lnum)
    end)
  end)

  describe("clear_hakens", function()
    it("should clear all manual entries (haken)", function()
      haken.setup()

      -- Add some entries
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      core.add_haken()
      vim.api.nvim_win_set_cursor(0, { 5, 0 })
      core.add_haken()

      local current_win_id = vim.api.nvim_get_current_win()
      local hakens = core.show_hakens()
      local win_hakens = hakens[current_win_id]

      -- Verify entries exist
      assert.equals(2, #win_hakens)

      -- Clear entries
      core.clear_hakens(current_win_id)

      -- Verify entries are cleared
      hakens = core.show_hakens()
      win_hakens = hakens[current_win_id]
      assert.equals(0, #win_hakens)
    end)
  end)

  describe("show_hakens", function()
    it("should return empty table initially", function()
      haken.setup()
      local current_win_id = vim.api.nvim_get_current_win()
      local hakens = core.show_hakens()
      local win_hakens = hakens[current_win_id]
      assert.equals(0, #(win_hakens or {}))
      assert.is_table(win_hakens or {})
    end)
  end)
end)
