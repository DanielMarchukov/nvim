-- Debug (DAP) extras layered onto LazyVim's dap.core: interactive eval, log
-- points, watches, and breakpoint management under the `dx` subgroup.
local dap_output_buffer

local function dap_input(opts, callback)
  vim.ui.input(vim.tbl_extend("force", {
    border = "rounded",
    max_width = 0.9,
    min_width = 48,
    prefer_width = 0.7,
    relative = "editor",
  }, opts), callback)
end

local function optional_input(prompt, callback)
  dap_input({ prompt = prompt }, function(value)
    value = value and vim.trim(value)
    callback(value ~= "" and value or nil)
  end)
end

local function set_breakpoint(condition, hit_condition, log_message)
  vim.wo.signcolumn = "yes"
  if log_message then
    vim.fn.sign_define("DapLogPoint", { text = "󰌵 ", texthl = "DiagnosticInfo" })
  end
  require("dap").set_breakpoint(condition, hit_condition, log_message)
end

local function get_dap_output_buffer()
  if dap_output_buffer and vim.api.nvim_buf_is_valid(dap_output_buffer) then
    return dap_output_buffer
  end

  dap_output_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(dap_output_buffer, "DAP Output")
  vim.bo[dap_output_buffer].bufhidden = "hide"
  vim.bo[dap_output_buffer].buftype = "nofile"
  vim.bo[dap_output_buffer].filetype = "dap-output"
  vim.bo[dap_output_buffer].modifiable = false
  return dap_output_buffer
end

local function open_dap_output()
  local buffer = get_dap_output_buffer()
  for _, window in ipairs(vim.fn.win_findbuf(buffer)) do
    return window
  end

  local current_window = vim.api.nvim_get_current_win()
  vim.cmd("botright 12new")
  local window = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(window, buffer)
  vim.wo[window].winbar = " DAP Output"
  vim.api.nvim_set_current_win(current_window)
  return window
end

local function append_dap_output(_, body)
  if body.category == "telemetry" or not body.output or body.output == "" then
    return
  end

  local buffer = get_dap_output_buffer()
  local lines = vim.split(body.output:gsub("\r", ""), "\n", { plain = true })
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, -1, -1, false, lines)
  vim.bo[buffer].modifiable = false

  local window = open_dap_output()
  vim.api.nvim_win_set_cursor(window, { vim.api.nvim_buf_line_count(buffer), 0 })
end

local function set_logpoint()
  optional_input("Log message ({expression} interpolation): ", function(log_message)
    if not log_message then
      vim.notify("A logpoint needs a log message.", vim.log.levels.WARN)
      return
    end

    set_breakpoint(nil, nil, log_message)
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

  dap_input({
    prompt = "Remote JVM tunnel port: ",
  }, function(value)
    if not value then
      return
    end

    local port = tonumber(vim.trim(value))
    if not port or port % 1 ~= 0 or port < 1 or port > 65535 then
      vim.notify("Remote JVM tunnel port must be an integer from 1 to 65535.", vim.log.levels.ERROR)
      return
    end

    dap.defaults.java = dap.defaults.java or {}
    dap.defaults.java.on_output = append_dap_output
    dap.run({
      type = "java",
      request = "attach",
      name = string.format("Attach Remote JVM (127.0.0.1:%d)", port),
      hostName = "127.0.0.1",
      port = port,
    })
  end)
end

local dap_ui_winbars = {
  dapui_breakpoints = " Breakpoints",
  dapui_scopes = " Variables",
  dapui_stacks = " Stack",
  dapui_watches = " Watches",
  ["dap-repl"] = " REPL",
  dapui_console = " Console",
}

local function configure_dap_ui_labels()
  local group = vim.api.nvim_create_augroup("DapUiLabels", { clear = true })
  local function set_winbar(args)
    local title = dap_ui_winbars[vim.bo[args.buf].filetype]
    if not title then
      return
    end

    for _, window in ipairs(vim.fn.win_findbuf(args.buf)) do
      vim.wo[window].winbar = title
    end
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = vim.tbl_keys(dap_ui_winbars),
    callback = set_winbar,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = set_winbar,
  })
end

return {
  {
    "mfussenegger/nvim-dap",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        once = true,
        callback = function()
          vim.fn.sign_define("DapLogPoint", { text = "󰌵 ", texthl = "DiagnosticInfo" })
        end,
      })
    end,
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
        "<leader>dxq",
        function()
          require("dap").list_breakpoints()
        end,
        desc = "List Breakpoints",
      },
      {
        "<leader>dxo",
        open_dap_output,
        desc = "Show DAP Output",
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
  {
    "rcarriga/nvim-dap-ui",
    init = configure_dap_ui_labels,
    opts = {
      layouts = {
        {
          elements = {
            { id = "breakpoints", size = 0.25 },
            { id = "stacks", size = 0.3 },
            { id = "scopes", size = 0.3 },
            { id = "watches", size = 0.15 },
          },
          position = "left",
          size = 44,
        },
        {
          elements = {
            { id = "repl", size = 0.5 },
            { id = "console", size = 0.5 },
          },
          position = "bottom",
          size = 12,
        },
      },
    },
  },
}
