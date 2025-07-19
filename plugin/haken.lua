-- Prevent loading the plugin multiple times
if vim.g.haken_loaded then
  return
end
vim.g.haken_loaded = 1

-- Check Neovim version compatibility
if vim.fn.has('nvim-0.10') == 0 then
  vim.api.nvim_err_writeln('haken.nvim requires Neovim 0.10.0+')
  return
end
