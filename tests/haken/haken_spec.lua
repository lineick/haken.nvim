local configs = {
  { name = "default", opts = {} },
  {
    name = "column_sensitive=true",
    opts = {
      column_sensitive = true,
      clear_jumps_on_startup = false,
      clear_jumps_on_new_window = false,
      silent = false,
    }
  },
  {
    name = "clear_jumps_on_new_window=true",
    opts = {
      clear_jumps_on_new_window = true,
    }
  },
  {
    name = "clear_jumps_on_startup=true",
    opts = {
      clear_jumps_on_startup = true,
    }
  },
  {
    name = "all options true",
    opts = {
      column_sensitive = true,
      clear_jumps_on_startup = true,
      clear_jumps_on_new_window = true,
      silent = true,
    }
  },
}

for _, cfg in ipairs(configs) do
  describe(('haken (%s)'):format(cfg.name), function()
    -- one extra line in your current before_each:
    local haken
    local core
    local utils
    local test_utils

    before_each(function()
      vim.o.jumpoptions = '' -- default value
      -- Clear any existing state
      package.loaded['haken'] = nil
      package.loaded['haken.core'] = nil
      package.loaded['haken.utils'] = nil
      package.loaded['tests.haken.utils'] = nil

      haken = require('haken')
      core = require('haken.core')
      utils = require('haken.utils')
      test_utils = require('tests.haken.utils')

      haken.setup(cfg.opts)

      -- Clear any existing manual entries (haken)
      core.clear_hakens()

      -- Clear jumplist
      vim.cmd('clearjumps')
    end)

    describe("setup", function()
      it("should setup with options", function()
        assert.has_no.errors(function()
          haken.setup(cfg.opts)
        end)
      end)

      it("should create user commands", function()
        haken.setup(cfg.opts)

        -- Check if commands exist
        local commands = vim.api.nvim_get_commands({})
        assert.is_not_nil(commands['AddHaken'])
        assert.is_not_nil(commands['ShowHakens'])
        assert.is_not_nil(commands['ClearAllHakens'])
      end)
    end)

    describe("add_haken", function()
      before_each(function()
        haken.setup(cfg.opts)
      end)

      it("should add a haken", function()
        -- Move cursor to a specific position

        local text = test_utils.generate_foo_bar_lines(200)
        test_utils.setup_test_buffer(text)
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
        local text = test_utils.generate_foo_bar_lines(200)
        test_utils.setup_test_buffer(text)
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
        local text = test_utils.generate_foo_bar_lines(200)
        test_utils.setup_test_buffer(text)
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
        haken.setup(cfg.opts)

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
        haken.setup(cfg.opts)
        local current_win_id = vim.api.nvim_get_current_win()
        local hakens = core.show_hakens()
        local win_hakens = hakens[current_win_id]
        assert.equals(0, #(win_hakens or {}))
        assert.is_table(win_hakens or {})
      end)
    end)
    describe("navigation with hakens", function()
      before_each(function()
        haken.setup(cfg.opts)

        local text = test_utils.generate_foo_bar_lines(200)
        test_utils.setup_test_buffer(text)
      end)

      it("should not remove jumplist if first haken is added", function()
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })

        test_utils.do_actions("}}}{")
        local pos = utils.get_current_position()
        test_utils.do_actions("}") -- this will be overwritten by the haken
        test_utils.do_actions("j")
        test_utils.do_actions("lll")
        test_utils.do_actions("H")
        test_utils.do_actions("o")

        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
      end)
      it("should connect hakens if new haken is added", function()
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })
        local pos = utils.get_current_position()

        test_utils.do_actions("H")
        test_utils.do_actions("}}}{}j")
        test_utils.do_actions("lll")
        test_utils.do_actions("H")
        local newest_pos = utils.get_current_position()
        test_utils.do_actions("o")

        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))

        test_utils.do_actions("i")
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), newest_pos))
      end)
      it("should work for hakens in deleted positions", function()
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })
        test_utils.do_actions("}")
        local pos = utils.get_current_position()
        test_utils.do_actions("H")
        test_utils.do_actions("d") -- delete line of haken
        test_utils.do_actions("}")
        test_utils.do_actions("H")
        test_utils.do_actions("o")

        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
      end)
      it("should prune", function()
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })
        local pos = utils.get_current_position()
        test_utils.do_actions("H")
        test_utils.do_actions("}")
        test_utils.do_actions("}j")
        test_utils.do_actions("lll")
        test_utils.do_actions("H")
        test_utils.do_actions("o")
        haken.prune_jumps()
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
        test_utils.do_actions("}")
        new_pos = utils.get_current_position()
        test_utils.do_actions("o")

        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
        test_utils.do_actions("i")
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), new_pos))
      end)
      it("should connect branches with hakens", function()
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })

        test_utils.do_actions("}}")
        test_utils.do_actions("H") -- set haken before branch

        local pos = utils.get_current_position()

        test_utils.do_actions("}") -- first branch
        test_utils.do_actions("H") -- haken in first branch

        local first_branch_pos = utils.get_current_position()

        test_utils.do_actions("o")
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
        test_utils.do_actions("{") -- second branch
        test_utils.do_actions("H") -- haken in second branch

        local second_branch_pos = utils.get_current_position()

        test_utils.do_actions("o") -- should go to first branch haken
        print("pos", vim.inspect(pos))
        print("first branch pos", vim.inspect(first_branch_pos))
        print("second branch pos", vim.inspect(second_branch_pos))
        print("current pos", vim.inspect(utils.get_current_position()))
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), first_branch_pos))
        test_utils.do_actions("o") -- should go to first root
        print("current pos", vim.inspect(utils.get_current_position()))
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
        test_utils.do_actions("i")
        test_utils.do_actions("i") -- should go to second branch haken
        print("current pos", vim.inspect(utils.get_current_position()))
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), second_branch_pos))
        test_utils.do_actions("oo") -- should go to root
        print("after o pos", vim.inspect(utils.get_current_position()))
        vim.api.nvim_win_set_cursor(win1, { 100, 0 })
        test_utils.do_actions("}") -- branch off into 3 branch
        test_utils.do_actions("H") -- haken in third branch
        local third_branch_pos = utils.get_current_position()
        print("third branch pos", vim.inspect(third_branch_pos))
        test_utils.do_actions("o") -- should go to root haken
        test_utils.do_actions("ii") -- should go to third branch haken (second i should not do anything)
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), third_branch_pos))
        test_utils.do_actions("o") -- should go to second branch haken
        print("current pos", vim.inspect(utils.get_current_position()))
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), second_branch_pos))
        test_utils.do_actions("o") -- should go to first branch haken
        print("current pos", vim.inspect(utils.get_current_position()))
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), first_branch_pos))
        test_utils.do_actions("o") -- should go to root haken
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))

      end)
      -- ############## STACK SPECIFIC TESTS! ##############
      it("should not remove jumplist if first haken is added (stack)", function()
        vim.o.jumpoptions = 'stack'
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })

        test_utils.do_actions("}}}{")
        local pos = utils.get_current_position()
        test_utils.do_actions("}") -- this will be overwritten by the haken
        test_utils.do_actions("j")
        test_utils.do_actions("lll")
        test_utils.do_actions("H")
        test_utils.do_actions("o")

        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
      end)
      it("should connect hakens if new haken is added (stack)", function()
        vim.o.jumpoptions = 'stack'
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })
        local pos = utils.get_current_position()

        test_utils.do_actions("H")
        test_utils.do_actions("}}}{}j")
        test_utils.do_actions("lll")
        test_utils.do_actions("H")
        local newest_pos = utils.get_current_position()
        test_utils.do_actions("o")

        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))

        test_utils.do_actions("i")
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), newest_pos))
      end)
      it("should work for hakens in deleted positions (stack)", function()
        vim.o.jumpoptions = 'stack'
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })
        test_utils.do_actions("}")
        local pos = utils.get_current_position()
        test_utils.do_actions("H")
        test_utils.do_actions("d") -- delete line of haken
        test_utils.do_actions("}")
        test_utils.do_actions("H")
        test_utils.do_actions("o")

        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
      end)
      it("should prune (stack)", function()
        vim.o.jumpoptions = 'stack'
        -- position
        local win1 = 0
        vim.api.nvim_win_set_cursor(win1, { 1, 0 })
        local pos = utils.get_current_position()
        test_utils.do_actions("H")
        test_utils.do_actions("}")
        test_utils.do_actions("}j")
        test_utils.do_actions("lll")
        test_utils.do_actions("H")
        test_utils.do_actions("o")
        haken.prune_jumps()
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
        test_utils.do_actions("}")
        new_pos = utils.get_current_position()
        test_utils.do_actions("o")

        assert.is_true(test_utils.positions_equal(utils.get_current_position(), pos))
        test_utils.do_actions("i")
        assert.is_true(test_utils.positions_equal(utils.get_current_position(), new_pos))
      end)
    end)
  end)
end
