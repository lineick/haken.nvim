# haken.nvim

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/lineick/haken.nvim/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A Neovim plugin for **easy jumplist management**. Add custom "hakens" (jump points), and keep your jumplist clean and focused.

---

## Features

- **Manual Jump Points ("Hakens")**: Mark custom positions in the jumplist using a command or keybinding. (`<BS>` is recommended)
- **Smart Cleanup**: When you add a new haken, entries *after* your last haken are automatically pruned from the jumplist connecting your last haken to your current one.
- **Built-in Commands**: Inspect, clear, and manage hakens with `:AddHaken`, `:ShowHakens`, and `:ClearHakens`.

---

## Requirements

- **Neovim 0.10.0+**

---

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "lineick/haken.nvim",
  config = function()
    require("haken").setup({
      -- column_sensitive = false, -- update haken even when just the column changed
      -- clear_jumplist = true,    -- clear jumplist on VimEnter (start of your session)
    })
  end,
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


## Configuration

Call `require("haken").setup()` with these options (all optional):

```lua
require("haken").setup({
  column_sensitive = false, -- Whether hakens are unique per column (default: false)
  clear_jumplist = true,    -- Whether to clear the jumplist on VimEnter (default: true)
})
```

**Note:**
Keybindings for adding hakens must be set up separately, or by mapping to `:AddHaken`.
I recommend to setting `require("haken").add_haken` to `<BR>` in normal mode.

---

## Usage

### Basic Workflow

* **Add a haken:**
  Run `:AddHaken` or map a key to this command (e.g., `<BS>` or any of your choice).
* **See your hakens:**
  Run `:ShowHakens` to print the list of currently tracked hakens.
* **Clear hakens:**
  Run `:ClearHakens` to clear manual tracking (does *not* alter the actual jumplist, just the haken marks).
* **Navigation:**
  Use Vim's default `<C-o>` and `<C-i>` for jumplist navigation. Haken will keep the jumplist clean as you add new marks.

---

### Example Mapping

You can map `<BS>` (Backspace) to add a haken:

```lua
vim.keymap.set("n", "<BS>", function() require("haken").add_haken() end, { desc = "Add haken" })
```

Or use the `:AddHaken` command directly.

---

### Commands

* `:AddHaken` — Add a haken at the current position.
* `:ShowHakens` — Show all currently tracked hakens in the jumplist.
* `:ClearHakens` — Clear all hakens from manual tracking (does *not* affect Neovim's actual jumplist).

---

### How It Works

1. When you add a haken, Haken checks if this position is different from your last haken. If no previous haken exists, it just adds the haken as a jump, without pruning the jumplist.
2. If another haken is in the jumplist, it prunes all jumplist entries after your last haken, then adds the new haken for the current position to the jumplist.
3. This ensures your jumplist contains only the entries you care about (your hakens), plus any automatic jumps since your last haken.

---

## Example Workflow

```
1. Open file A, line 10 -> :AddHaken (haken 1)
2. Move around, create automatic jumps
3. Go to file B, line 50 -> :AddHaken (haken 2, cleans up after haken 1)
4. More navigation...
5. Go to file C, line 100 -> :AddHaken (haken 3, cleans up after haken 2)

Your jumplist now only contains 3 jumps!

6. Navigate further (jumps etc.)

Your jumplist contains the first 3 haken (manual jump entries) and the standard jumps added by step 6!
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

---

## License

MIT License — see LICENSE file for details.

```

