-- Single source of truth for which-key group labels. Individual binds live in
-- the plugin spec that owns them; this file only names the groups.
return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      { "<leader>gh", group = "github" },
      { "<leader>gx", group = "conflict" },
      { "<leader>dx", group = "debug extras" },
      { "<leader>sn", group = "messages" },
      { "<leader>tj", group = "java test" },
      { "<leader>tc", group = "cucumber" },
      { "<leader>ue", group = "edgebar" },
    },
    triggers = {
      { "<auto>", mode = "nxso" },
    },
  },
}
