-- Language tooling: treesitter, Mason packages, test adapters (neotest),
-- formatters (conform), refactoring, and Scala (metals).
local java_tools = require("config.java_tools")

return {
  {
    "nvim-metals",
    ft = { "scala", "sbt" },
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
        markdown = { "prettier" },
      },
      formatters = {
        ["palantir-java-format"] = {
          command = java_tools.palantir_java_format_command(),
        },
        prettier = {
          prepend_args = { "--prose-wrap", "always" },
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
