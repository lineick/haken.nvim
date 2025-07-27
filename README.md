# haken.nvim

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/lineick/haken.nvim/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A Neovim plugin for **easy jumplist management**. Add custom "hakens" (jump points), and keep your jumplist clean and focused.

---

> [!NOTE]
> The Hakens always connect between each other. A new haken will connect to the last set haken. This behavior does not adapt to `vim.o.jumpoptions="stack"`.

## Features

- **Manual Jump Points ("Hakens")**: Mark custom positions in the jumplist using a command or keybinding. (I like backspace `<BS>` or enter `<CR>` in normal mode)
- **Smart Cleanup**: When you add a new haken, entries *after* your last haken are automatically pruned from the jumplist connecting your last haken to your current one.
- **Built-in Commands**: Inspect, clear, and manage hakens with `:AddHaken`, `:ShowHakens`, and `:ClearAllHakens` (clear hakens for all windows).
- **Window-specific**: Your hakens and jumplists are managed per window.

---

## Requirements

- **Neovim 0.10.0+**

---

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "lineick/haken.nvim",
  opts = {
    -- column_sensitive = false, -- update haken even when just the column changed
    -- clear_jumps_on_startup = false, -- clear jumplist on startup (hakens are always cleared on startup)
    -- clear_jumps_on_new_window = false, -- clear jumplist for each new window
    -- silent = false, -- deactivates prints into the statusbar when adding hakens etc.
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "lineick/haken.nvim",
  config = function()
    require("haken").setup()
  end
}
```


## Example Configuration

Call `require("haken").setup()` with these options (all optional):

```lua
require("haken").setup({
  column_sensitive = true, -- update haken even when just the column changed
  clear_jumps_on_startup = true, -- clear jumplist on startup (hakens are always cleared on startup)
  clear_jumps_on_new_window = false, -- clear jumplist for each new window
  silent = false, -- deactivates prints into the statusbar when adding hakens etc.
})
```

Add keybindings for adding hakens and optionally for pruning the jumplist.

```lua
vim.keymap.set('n', '<BS>', haken.add_haken, {
  desc = "Add haken",
  silent = true,
})

vim.keymap.set('n', '<leader><BS>', haken.prune_jumps, {
  desc = "Prune jumps to current position in jumplist",
  silent = true,
})
```

---

## Vim Commands

* **Add a haken:**
  Run `:AddHaken` to add a haken (calls `haken.add_haken()`) under the hood.
* **See your hakens:**
  Run `:ShowHakens` to print the list of currently tracked hakens.
* **Clear hakens:**
  Run `:ClearAllHakens` to clear hakens in all windows (does *not* alter the actual jumplist, just the haken marks).
* **Navigation:**
  Use Vim's default `<C-o>` and `<C-i>` for jumplist navigation. Haken will keep the jumplist clean as you add new marks.

---

## How It Works

1. When you add a haken, Haken checks if this position is different from your last haken. If no previous haken exists, it just adds the haken as a jump, without pruning the jumplist.
2. If a previous haken is in the jumplist, it prunes all jumplist entries between the previous haken and the haken you set now, letting you jump with only one `<C-o>`.
3. This ensures your jumplist contains only the entries you care about (your hakens), plus any automatic jumps since your last haken and before your first haken.

---

### Example Workflow

![](./doc/example_dark.png#gh-dark-mode-only)
![](./doc/example_light.png#gh-light-mode-only)

```
1. make a jump (e.g. with `}`)
2. move a bit further -> :AddHaken (haken 1)
3. make a jump (or multiple, for simplicity in the graphic its just one)
3. move further -> :AddHaken (haken 2)
4. move back once (`<C-o>`) to get to haken 1
5. move somewhere else (can of course also be other buffers) -> :AddHaken (haken 3)
6. jump again (e.g. `}`)
7. move back (`<C-o`) three times to get to haken 1
8. jump somewhere else
9. move a bit further -> :AddHaken (haken 4)

You now have only 5 entries in your jumplist (4 hakens and the initial jump).
Jumping back will take you over your previous hakens one by one.
```

---

## API

You can also access the core functions programmatically:

```lua
local haken = require("haken")

-- Add a haken at the current cursor position
haken.add_haken()

-- Show all hakens (returns table)
local hakens = haken.show_hakens()

-- Clear hakens tracking
haken.clear_hakens()
```

If you need even more advanced features, the core API is available in `require("haken.core")`.

---

## Contributing

Contributions are welcome!
Open issues, file pull requests, or share suggestions for new features.

