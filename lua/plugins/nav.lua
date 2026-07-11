-- Seamless pane navigation across the tmux <-> Neovim boundary.
-- Uses christoomey/vim-tmux-navigator to match the plugin already loaded in
-- tmux.conf, so <C-hjkl> moves between nvim splits and tmux panes uniformly.
-- (Replaces nathom/tmux.nvim, which did not cooperate with the tmux-side plugin.)
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to Left Window/Pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to Lower Window/Pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to Upper Window/Pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to Right Window/Pane" },
    },
  },
}
