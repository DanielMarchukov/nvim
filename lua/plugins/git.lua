-- Git: one coherent stack with four non-overlapping roles.
--   fugitive     -> operations (status/commit/blame/diff/merge/push/pull/browse)
--   mini.diff    -> inline hunks (signs, stage/reset via gh/gH, overlay)
--   snacks       -> fuzzy browse (log / branches / stash)
--   octo         -> GitHub (issues/PRs/repos) under the `gh` subgroup
--   git-conflict -> in-buffer conflict nav (]x/[x) + `gx` resolve submenu
-- which-key group labels for `g`, `gh`, `gx` live in whichkey.lua.
return {
  -- Operations cockpit ------------------------------------------------------
  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" }, -- GitHub URLs for :GBrowse
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "GBrowse" },
    keys = {
      { "<leader>gg", "<cmd>Git<cr>", desc = "Status (cockpit)" },
      { "<leader>gc", "<cmd>Git commit<cr>", desc = "Commit" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Blame" },
      { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Diff This File" },
      { "<leader>gm", "<cmd>Gvdiffsplit!<cr>", desc = "Merge / 3-Way Conflict" },
      { "<leader>gB", "<cmd>GBrowse!<cr>", mode = { "n", "x" }, desc = "Copy Web Link" },
      { "<leader>gp", "<cmd>Git push<cr>", desc = "Push" },
      { "<leader>gP", "<cmd>Git pull<cr>", desc = "Pull" },
    },
  },

  -- Inline hunks ------------------------------------------------------------
  {
    "echasnovski/mini.diff",
    keys = {
      { "<leader>go", false }, -- overlay moved to gv (keeps `go` out of git)
      {
        "<leader>gv",
        function()
          require("mini.diff").toggle_overlay(0)
        end,
        desc = "Toggle Diff Overlay",
      },
    },
  },

  -- Fuzzy browse (snacks pickers) ------------------------------------------
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gd", false }, -- -> fugitive Diff This File
      { "<leader>gD", false }, -- drop diff-origin (redundant)
      { "<leader>gs", false }, -- status handled by the fugitive cockpit (gg)
      {
        "<leader>gl",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Log",
      },
      {
        "<leader>gL",
        function()
          Snacks.picker.git_log_file()
        end,
        desc = "Log (this file)",
      },
      {
        "<leader>gr",
        function()
          Snacks.picker.git_branches()
        end,
        desc = "Branches",
      },
      -- gS (stash) is inherited from the snacks_picker extra once octo's
      -- override of gS is removed below.
    },
  },

  -- GitHub (octo) under the `gh` subgroup ----------------------------------
  {
    "pwntester/octo.nvim",
    keys = {
      { "<leader>gi", false },
      { "<leader>gI", false },
      { "<leader>gp", false },
      { "<leader>gP", false },
      { "<leader>gr", false },
      { "<leader>gS", false }, -- reclaim gS for snacks stash
      { "<leader>ghi", "<cmd>Octo issue list<CR>", desc = "Issues" },
      { "<leader>ghI", "<cmd>Octo issue search<CR>", desc = "Search Issues" },
      { "<leader>ghp", "<cmd>Octo pr list<CR>", desc = "PRs" },
      { "<leader>ghP", "<cmd>Octo pr search<CR>", desc = "Search PRs" },
      { "<leader>ghr", "<cmd>Octo repo list<CR>", desc = "Repos" },
      { "<leader>ghs", "<cmd>Octo search<CR>", desc = "Search GitHub" },
    },
  },

  -- In-buffer conflict navigation + resolution -----------------------------
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "VeryLazy",
    opts = {
      default_mappings = false, -- avoid shadowing c/ct/co change-motions
      disable_diagnostics = true, -- conflict markers make LSP diagnostics noise
    },
    keys = {
      { "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next Conflict" },
      { "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev Conflict" },
      { "<leader>gxo", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose Ours" },
      { "<leader>gxt", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose Theirs" },
      { "<leader>gxb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose Both" },
      { "<leader>gx0", "<cmd>GitConflictChooseNone<cr>", desc = "Choose None" },
      { "<leader>gxl", "<cmd>GitConflictListQf<cr>", desc = "List Conflicts (qf)" },
    },
  },

  -- GitLab MR / review workflow (work) -------------------------------------
  {
    "harrisoncramer/gitlab.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "stevearc/dressing.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    build = function()
      require("gitlab.server").build(true)
    end,
    config = function()
      require("gitlab").setup()
    end,
  },
}
