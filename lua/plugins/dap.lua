-- Debug (DAP) extras layered onto LazyVim's dap.core: interactive eval, log
-- points, watches, and breakpoint management under the `dx` subgroup.
return {
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
}
