-- Debug (DAP) extras layered onto LazyVim's dap.core: interactive eval, log
-- points, watches, and breakpoint management under the `dx` subgroup.
local remote_java_debug_port = 30613

local function optional_input(prompt, callback)
  vim.ui.input({ prompt = prompt }, function(value)
    value = value and vim.trim(value)
    callback(value ~= "" and value or nil)
  end)
end

local function set_breakpoint(condition, hit_condition, log_message)
  require("dap").set_breakpoint(condition, hit_condition, log_message)
end

local function set_logpoint()
  optional_input("Log message ({expression} interpolation): ", function(log_message)
    if not log_message then
      vim.notify("A logpoint needs a log message.", vim.log.levels.WARN)
      return
    end

    optional_input("Condition (optional): ", function(condition)
      optional_input("Hit condition (optional; ==3, >5, %10): ", function(hit_condition)
        set_breakpoint(condition, hit_condition, log_message)
      end)
    end)
  end)
end

local function set_advanced_breakpoint()
  vim.ui.select({ "Stop execution", "Log without stopping" }, {
    prompt = "Breakpoint mode",
  }, function(mode)
    if not mode then
      return
    end

    if mode == "Log without stopping" then
      set_logpoint()
      return
    end

    optional_input("Condition (optional): ", function(condition)
      optional_input("Hit condition (optional; ==3, >5, %10): ", function(hit_condition)
        set_breakpoint(condition, hit_condition)
      end)
    end)
  end)
end

local function attach_remote_java_debugger()
  local dap = require("dap")
  if not dap.adapters.java then
    vim.notify(
      "Java debug adapter unavailable. Open a Java source file and wait for JDTLS to attach.",
      vim.log.levels.ERROR
    )
    return
  end

  vim.ui.input({
    prompt = "Remote JVM tunnel port: ",
    default = tostring(remote_java_debug_port),
  }, function(value)
    if not value then
      return
    end

    local port = tonumber(vim.trim(value))
    if not port or port % 1 ~= 0 or port < 1 or port > 65535 then
      vim.notify("Remote JVM tunnel port must be an integer from 1 to 65535.", vim.log.levels.ERROR)
      return
    end

    remote_java_debug_port = port
    dap.run({
      type = "java",
      request = "attach",
      name = string.format("Attach Remote JVM (127.0.0.1:%d)", port),
      hostName = "127.0.0.1",
      port = port,
    })
  end)
end

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
        set_logpoint,
        desc = "Log Point",
      },
      {
        "<leader>dxa",
        set_advanced_breakpoint,
        desc = "Advanced Breakpoint",
      },
      {
        "<leader>dxr",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Clear Breakpoints",
      },
      {
        "<leader>dxs",
        attach_remote_java_debugger,
        desc = "Attach Remote Java JVM",
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
