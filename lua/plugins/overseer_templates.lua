-- Custom overseer task templates
-- Add your project-specific run/build/test tasks here.
--
-- Example template:
--
--   overseer.register_template({
--     name = "My Task",
--     builder = function()
--       return {
--         cmd = { "make" },
--         args = { "build" },
--         cwd = vim.fn.expand("~/projects/my-project"),
--         env = { DEBUG = "1" },
--         components = { "default" },
--       }
--     end,
--   })

return {
  "stevearc/overseer.nvim",
  opts = function(_, opts)
    local overseer = require("overseer")

    -- Register custom templates below:
  end,
}
