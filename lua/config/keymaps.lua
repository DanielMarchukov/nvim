-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Bottom terminal split (~1/3 screen)
local function bottom_terminal()
  Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 0.33 } })
end

vim.keymap.set({ "n", "t" }, "<C-/>", bottom_terminal, { desc = "Toggle Bottom Terminal" })
vim.keymap.set({ "n", "t" }, "<C-_>", bottom_terminal, { desc = "Toggle Bottom Terminal" }) -- WSL sends C-/ as C-_
vim.keymap.set("n", "<leader>fT", bottom_terminal, { desc = "Toggle Bottom Terminal" })

-- Buffer-local diagnostics toggle (doesn't affect other splits/buffers)
vim.keymap.set("n", "<leader>ux", function()
  local buf = vim.api.nvim_get_current_buf()
  local enabled = vim.diagnostic.is_enabled({ bufnr = buf })
  vim.diagnostic.enable(not enabled, { bufnr = buf })
  vim.notify("Buffer diagnostics " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
end, { desc = "Toggle Buffer Diagnostics" })
