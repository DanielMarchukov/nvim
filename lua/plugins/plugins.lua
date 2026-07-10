local java_tools = require("config.java_tools")

local function current_or_recent_edgy_win()
  local editor = require("edgy.editor")
  local current = editor.get_win()
  if current and current:is_valid() then
    return current
  end

  local wins = {}
  for _, edgebar in pairs(require("edgy.config").layout) do
    for _, win in ipairs(edgebar.wins) do
      if win.visible and win:is_valid() then
        wins[#wins + 1] = win
      end
    end
  end

  table.sort(wins, function(a, b)
    return (vim.w[a.win].edgy_enter or 0) > (vim.w[b.win].edgy_enter or 0)
  end)

  return wins[1]
end

local function with_edgy_win(action)
  local win = current_or_recent_edgy_win()
  if not win then
    vim.notify("No Edgy sidebar window is open", vim.log.levels.WARN)
    return
  end
  action(win)
end

local function dismiss_messages_and_notifications()
  local noice_ok, noice = pcall(require, "noice")
  if noice_ok then
    noice.cmd("dismiss")
  end

  local snacks_ok, snacks = pcall(require, "snacks")
  if snacks_ok and snacks.notifier then
    snacks.notifier.hide()
  end
end

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
      spec = {
        { "<leader>dx", group = "debug extras" },
        { "<leader>gv", group = "fugitive" },
        { "<leader>sn", group = "messages" },
        { "<leader>tj", group = "java test" },
        { "<leader>ue", group = "edgebar" },
      },
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
      { "<leader>gvs", "<cmd>Git<cr>", desc = "Status" },
      { "<leader>gvd", "<cmd>Gdiffsplit<cr>", desc = "Diff Split" },
      { "<leader>gvD", "<cmd>Gvdiffsplit!<cr>", desc = "3-Way Merge" },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      local TS = require("nvim-treesitter")
      if not TS.get_installed then
        LazyVim.error("Please restart Neovim and run `:TSUpdate` to use the `nvim-treesitter` **main** branch.")
        return
      end

      package.loaded["lazyvim.util.treesitter"] = nil
      LazyVim.treesitter.build(function()
        require("config.treesitter").update_managed_parsers({ summary = true })
      end)
    end,
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
              "<leader>dxj",
              function()
                require("jdtls.dap").setup_dap_main_class_configs({ verbose = true })
              end,
              desc = "Java Main Configs",
            },
            {
              "<leader>tjg",
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
        "<leader>dxe",
        function()
          require("dapui").eval(vim.fn.input("Expression: "))
        end,
        desc = "Eval Input",
      },
      {
        "<leader>dxf",
        function()
          require("dapui").float_element("scopes", { enter = true })
        end,
        desc = "Float Scopes",
      },
      {
        "<leader>dxl",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point: "))
        end,
        desc = "Log Point",
      },
      {
        "<leader>dxr",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Clear Breakpoints",
      },
      {
        "<leader>dxw",
        function()
          require("dapui").elements.watches.add(vim.fn.input("Watch: "))
        end,
        desc = "Add Watch",
      },
    },
  },
  {
    "snacks.nvim",
    keys = {
      { "<leader>.", false },
      { "<leader>S", false },
      { "<leader>n", false },
      { "<leader>un", false },
      { "<leader>bs", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
      { "<leader>bS", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader>snn", function() Snacks.picker.notifications() end, desc = "Notification History" },
    },
    opts = {
      image = { enabled = false },
    },
  },
  {
    "folke/edgy.nvim",
    keys = {
      { "<leader>ue", false },
      { "<leader>uE", false },
      {
        "<leader>uec",
        function()
          require("edgy").close()
        end,
        desc = "Close Edgebars",
      },
      {
        "<leader>ueh",
        function()
          with_edgy_win(function(win)
            win:resize("width", -2)
          end)
        end,
        desc = "Shrink Width",
      },
      {
        "<leader>uej",
        function()
          with_edgy_win(function(win)
            win:resize("height", -2)
          end)
        end,
        desc = "Shrink Height",
      },
      {
        "<leader>uek",
        function()
          with_edgy_win(function(win)
            win:resize("height", 2)
          end)
        end,
        desc = "Grow Height",
      },
      {
        "<leader>uel",
        function()
          with_edgy_win(function(win)
            win:resize("width", 2)
          end)
        end,
        desc = "Grow Width",
      },
      {
        "<leader>uem",
        function()
          require("edgy").goto_main()
        end,
        desc = "Focus Main Window",
      },
      {
        "<leader>ueo",
        function()
          require("edgy").open()
        end,
        desc = "Open Edgebars",
      },
      {
        "<leader>ueq",
        function()
          with_edgy_win(function(win)
            win:close()
          end)
        end,
        desc = "Close Window",
      },
      {
        "<leader>ueQ",
        function()
          with_edgy_win(function(win)
            win.view.edgebar:close()
          end)
        end,
        desc = "Close Current Edgebar",
      },
      {
        "<leader>ues",
        function()
          require("edgy").select()
        end,
        desc = "Select Edgebar Window",
      },
      {
        "<leader>uet",
        function()
          require("edgy").toggle()
        end,
        desc = "Toggle Edgebars",
      },
      {
        "<leader>ue=",
        function()
          with_edgy_win(function(win)
            win.view.edgebar:equalize()
          end)
        end,
        desc = "Equalize Edgebar",
      },
    },
  },
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
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
  },
  {
    "folke/noice.nvim",
    keys = {
      { "<leader>snl", false },
      { "<leader>snh", false },
      { "<leader>sna", false },
      { "<leader>snd", false },
      { "<leader>snt", false },
      { "<leader>snl", function() require("noice").cmd("last") end, desc = "Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end, desc = "Message History" },
      { "<leader>sna", function() require("noice").cmd("all") end, desc = "All Messages" },
      { "<leader>snd", dismiss_messages_and_notifications, desc = "Dismiss Messages" },
      { "<leader>snp", function() require("noice").cmd("pick") end, desc = "Picker" },
    },
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
