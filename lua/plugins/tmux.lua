return {
  {
    "nathom/tmux.nvim",
    config = function()
      local map = vim.api.nvim_set_keymap
      map("n", "<C-h>", [[<cmd>lua require('tmux').move_left()<cr>]], { desc = "Move to left tmux pane" })
      map("n", "<C-j>", [[<cmd>lua require('tmux').move_down()<cr>]], { desc = "Move to bottom tmux pane" })
      map("n", "<C-k>", [[<cmd>lua require('tmux').move_up()<cr>]], { desc = "Move to top tmux pane" })
      map("n", "<C-l>", [[<cmd>lua require('tmux').move_right()<cr>]], { desc = "Move to right tmux pane" })
    end,
  },
}
