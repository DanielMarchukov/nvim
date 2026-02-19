-- Cargo overseer task templates for Rust development
return {
  "stevearc/overseer.nvim",
  opts = function(_, opts)
    local overseer = require("overseer")

    overseer.register_template({
      name = "Cargo Build",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "build" },
          components = { "default" },
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Build (Release)",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "build", "--release" },
          components = { "default" },
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Test",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "test" },
          components = { "default" },
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Bench",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "bench" },
          components = { "default" },
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Clippy",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "clippy", "--all-targets", "--", "-W", "clippy::pedantic", "-W", "clippy::nursery" },
          components = { "default" },
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Doc (Open)",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "doc", "--open", "--no-deps" },
          components = { "default" },
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })
  end,
}
