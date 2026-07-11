-- Language server configuration: per-server settings, root patterns, and the
-- Java (jdtls) integration. Buffer-local LSP keymaps (calls, cucumber steps)
-- are added where they belong; group labels live in whichkey.lua.
local java_tools = require("config.java_tools")

return {
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
}
