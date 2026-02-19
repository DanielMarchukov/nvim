return {
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
  {
    "folke/which-key.nvim",
    opts = {
      triggers = {
        { "<auto>", mode = "nxso" },
      },
    },
  },
  {
    "nanotee/zoxide.vim",
    cmd = { "Z", "Zi", "Lz", "Lzi" },
  },
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "GBrowse" },
    keys = {
      { "<leader>gF", "<cmd>Git<cr>", desc = "Fugitive Status" },
      { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Fugitive Diff Split" },
      { "<leader>gD", "<cmd>Gvdiffsplit!<cr>", desc = "Fugitive 3-Way Merge" },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = {
          keys = {},
          settings = {
            java = {
              jdt = {
                ls = {
                  vmargs = "-XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx4G -Xms512m",
                  lombokSupport = { enabled = true },
                },
              },
            },
          },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        sqlfluff = {
          args = {
            "lint",
            "--format=sql",
            -- note: users will have to replace the --dialect argument accordingly
            "--dialect=postgres",
          },
        },
      },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
  -- Rust: neotest adapter via rustaceanvim (neotest-rust is archived)
  {
    "mrcjkb/rustaceanvim",
    opts = {
      tools = {
        test_executor = "neotest",
      },
    },
  },
  -- Neotest: register adapters for Rust and Java
  {
    "nvim-neotest/neotest",
    dependencies = {
      "mrcjkb/rustaceanvim",
      "rcasia/neotest-java",
    },
    opts = {
      adapters = {
        ["rustaceanvim.neotest"] = {},
        ["neotest-java"] = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sql = { "sqlfluff" },
      },
      formatters = {
        sqlfluff = {
          command = "sqlfluff",
          args = { "fix", "--dialect=postgres", "-" },
          stdin = true,
          cwd = function()
            return require("lspconfig.util").root_pattern(".sqlfluff.toml", ".sqlfluff", ".git")(vim.fn.expand("%:p"))
          end,
        },
      },
    },
  },
}
