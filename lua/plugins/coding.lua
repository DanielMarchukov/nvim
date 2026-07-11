-- Code-group additions layered onto LazyVim's LSP keymaps.
-- LSP call hierarchy (who calls this / what this calls), rendered in Trouble.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.keys = opts.keys or {}
      vim.list_extend(opts.keys, {
        {
          "<leader>ci",
          "<cmd>Trouble lsp_incoming_calls toggle<cr>",
          desc = "Incoming Calls",
          has = "callHierarchy",
        },
        {
          "<leader>co",
          "<cmd>Trouble lsp_outgoing_calls toggle<cr>",
          desc = "Outgoing Calls",
          has = "callHierarchy",
        },
      })
    end,
  },
}
