-- UI / appearance: colorscheme, edgebar (edgy) window management, Trouble
-- diagnostics, noice messages, and copilot ghost-text tuning.

-- Edgy sidebar helpers (used by the edgebar keymaps below).
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
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
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
    init = function()
      -- Ergonomic in-panel resize: while focused inside any Trouble split,
      -- <C-Up>/<C-Down> grow/shrink it (height, since it docks at the bottom).
      -- This complements the global <leader>uej/<leader>uek edgebar controls.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "trouble",
        callback = function(ev)
          vim.keymap.set("n", "<C-Up>", function()
            with_edgy_win(function(win)
              win:resize("height", 3)
            end)
          end, { buffer = ev.buf, desc = "Grow Panel" })
          vim.keymap.set("n", "<C-Down>", function()
            with_edgy_win(function(win)
              win:resize("height", -3)
            end)
          end, { buffer = ev.buf, desc = "Shrink Panel" })
        end,
      })
    end,
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
    opts = {
      -- Open EVERY Trouble view at the bottom. Several modes (symbols, lsp)
      -- default to a right sidebar; this global win, plus the symbols override
      -- (symbols has its own built-in position=right), forces them all bottom.
      win = { position = "bottom", size = 0.5 },
      modes = {
        symbols = {
          win = { position = "bottom" },
        },
        lsp = {
          -- The built-in lsp mode also sets position=right; override it.
          win = { position = "bottom" },
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
      {
        "<leader>snl",
        function()
          require("noice").cmd("last")
        end,
        desc = "Last Message",
      },
      {
        "<leader>snh",
        function()
          require("noice").cmd("history")
        end,
        desc = "Message History",
      },
      {
        "<leader>sna",
        function()
          require("noice").cmd("all")
        end,
        desc = "All Messages",
      },
      { "<leader>snd", dismiss_messages_and_notifications, desc = "Dismiss Messages" },
      {
        "<leader>snp",
        function()
          require("noice").cmd("pick")
        end,
        desc = "Picker",
      },
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
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
}
