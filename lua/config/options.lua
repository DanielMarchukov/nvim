-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character

-- Show diagnostics as virtual lines below the code (wraps naturally, never goes off-screen)
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
})
