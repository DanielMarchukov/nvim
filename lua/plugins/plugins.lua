local java_tools = require("config.java_tools")

return {
  {
    "nvim-metals",
    ft = { "scala", "sbt" },
  },
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
    init = function()
      -- Ensure .feature files always resolve to the cucumber filetype.
      vim.filetype.add({
        extension = {
          feature = "cucumber",
        },
      })
    end,
    opts = {
      servers = {
        cucumber_language_server = {
          root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern(
              "settings.gradle",
              "settings.gradle.kts",
              "build.gradle",
              "build.gradle.kts",
              "pom.xml",
              ".git"
            )(fname)
          end,
          settings = {
            cucumber = {
              features = {
                "src/test/resources/**/*.feature",
                "src/test/**/*.feature",
                "features/**/*.feature",
                "tests/**/*.feature",
              },
              glue = {
                "src/test/**/*.java",
                "src/test/**/*.kt",
                "src/test/**/*.scala",
                "features/**/*.java",
                "features/**/*.kt",
                "features/**/*.scala",
                "tests/**/*.java",
                "tests/**/*.kt",
                "tests/**/*.scala",
              },
              parameterTypes = {},
              snippetTemplates = {},
            },
          },
          keys = {
            { "<leader>tc", "", desc = "+cucumber" },
            { "<leader>tcd", vim.lsp.buf.definition, desc = "Step Definition", has = "definition" },
            { "<leader>tcr", vim.lsp.buf.references, desc = "Step References", has = "references" },
            { "<leader>tca", vim.lsp.buf.code_action, desc = "Step Code Actions", has = "codeAction" },
            {
              "<leader>tcL",
              "<cmd>LspRestart cucumber_language_server<cr>",
              desc = "Restart Cucumber LSP",
            },
            {
              "<leader>tcf",
              function()
                require("conform").format({ async = false, lsp_format = "fallback" })
              end,
              desc = "Format Feature File",
            },
          },
        },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--query-driver=/usr/bin/clang++",
          },
        },
        pyright = {
          root_dir = function(fname)
            local util = require("lspconfig.util")
            -- We tell it to search up from the current file for pyrightconfig.json or a .git folder
            return util.root_pattern("pyrightconfig.json", ".git")(fname)
          end,
          settings = {
            pyright = {
              disableOrganizeImports = false,
            },
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local util = require("lspconfig.util")
      local github_env = java_tools.github_gradle_env()

      opts.root_dir = function(fname)
        return util.root_pattern("settings.gradle", "settings.gradle.kts", "gradlew", ".git")(fname)
      end

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          autobuild = {
            enabled = false,
          },
          maxConcurrentBuilds = 1,
          completion = {
            maxResults = 150,
          },
          jdt = {
            ls = {
              vmargs = "-XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx4G -Xms512m",
              lombokSupport = { enabled = true },
            },
          },
          project = {
            resourceFilters = {
              "node_modules",
              "\\.git",
              "build",
              "\\.gradle",
              "target",
              "out",
              "dist",
            },
          },
        },
      })

      -- Large Gradle multi-module repos can fail and stall on eager DAP main-class scans.
      -- Keep JDTLS attach/debug stable by disabling that background scan.
      opts.dap_main = false

      opts.jdtls = function(config)
        config.cmd_env = java_tools.merge_env(config.cmd_env, github_env)
        config.init_options = vim.tbl_deep_extend("force", config.init_options or {}, {
          bundles = java_tools.jdtls_bundles(),
        })
        return config
      end

      local existing_on_attach = opts.on_attach
      opts.on_attach = function(args)
        if existing_on_attach then
          existing_on_attach(args)
        end

        require("which-key").add({
          {
            mode = "n",
            buffer = args.buf,
            {
              "<leader>dJ",
              function()
                require("jdtls.dap").setup_dap_main_class_configs({ verbose = true })
              end,
              desc = "Java Main Configs",
            },
            {
              "<leader>tg",
              function()
                require("jdtls.tests").generate()
              end,
              desc = "Generate Test",
            },
          },
        })
      end
    end,
  },
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dE",
        function()
          require("dapui").eval(vim.fn.input("Expression: "))
        end,
        desc = "Eval Input",
      },
      {
        "<leader>dF",
        function()
          require("dapui").float_element("scopes", { enter = true })
        end,
        desc = "Float Scopes",
      },
      {
        "<leader>dL",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point: "))
        end,
        desc = "Log Point",
      },
      {
        "<leader>dR",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Clear Breakpoints",
      },
      {
        "<leader>dW",
        function()
          require("dapui").elements.watches.add(vim.fn.input("Watch: "))
        end,
        desc = "Add Watch",
      },
    },
  },
  {
    "snacks.nvim",
    opts = {
      image = { enabled = false },
    },
  },
  {
    "folke/trouble.nvim",
    opts = {
      modes = {
        lsp = {
          auto_preview = false,
          auto_refresh = false,
          follow = true,
        },
        lsp_base = {
          auto_preview = false,
          auto_refresh = false,
          follow = true,
        },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics (Trouble)" },
    },
  },
  {
    "folke/noice.nvim",
    opts = {
      routes = {
        {
          filter = {
            event = "notify",
            find = "has been overwritten by another plugin%?",
          },
          opts = { skip = true },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "jdtls",
        "java-debug-adapter",
        "java-test",
        "cucumber-language-server",
        "reformat-gherkin",
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
        java = { "palantir-java-format" },
        cucumber = { "reformat-gherkin" },
        sql = { "sqlfluff" },
        markdown = { "prettier" },
      },
      formatters = {
        ["palantir-java-format"] = {
          command = java_tools.palantir_java_format_command(),
        },
        prettier = {
          prepend_args = { "--prose-wrap", "always" },
        },
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
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "lewis6991/async.nvim",
    },
  },
}
