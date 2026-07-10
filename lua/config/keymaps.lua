-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Bottom terminal split (~1/3 screen)
local function bottom_terminal()
  Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 0.33 } })
end

vim.keymap.set({ "n", "t" }, "<C-/>", bottom_terminal, { desc = "Toggle Bottom Terminal" })
vim.keymap.set({ "n", "t" }, "<C-_>", bottom_terminal, { desc = "Toggle Bottom Terminal" }) -- WSL sends C-/ as C-_

-- Git UI: use gitui (installed via Mason) instead of LazyVim's default lazygit,
-- so the setup doesn't depend on a tool we don't use.
local function gitui(cwd)
  Snacks.terminal.toggle("gitui", {
    cwd = cwd,
    win = { position = "float", width = 0.95, height = 0.95 },
  })
end

vim.keymap.set("n", "<leader>gg", function()
  gitui(LazyVim.root())
end, { desc = "gitui (Root Dir)" })
vim.keymap.set("n", "<leader>gG", function()
  gitui(vim.fn.getcwd())
end, { desc = "gitui (cwd)" })

-- Buffer-local diagnostics toggle (doesn't affect other splits/buffers)
vim.keymap.set("n", "<leader>ux", function()
  local buf = vim.api.nvim_get_current_buf()
  local enabled = vim.diagnostic.is_enabled({ bufnr = buf })
  vim.diagnostic.enable(not enabled, { bufnr = buf })
  vim.notify("Buffer diagnostics " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
end, { desc = "Toggle Buffer Diagnostics" })
