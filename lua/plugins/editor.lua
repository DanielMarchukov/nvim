-- Editor-level keymap tweaks: snacks non-git overrides and find/search
-- de-duplication (git snacks keys live in git.lua). Flash motions (s/S/r/R)
-- and grug-far project search-replace (<leader>sr) come from LazyVim as-is.
return {
  {
    "folke/snacks.nvim",
    keys = {
      -- LazyVim defaults we don't use
      { "<leader>.", false },
      { "<leader>S", false },
      { "<leader>n", false },
      { "<leader>un", false },
      -- Explorer: keep e / E, drop the fe / fE duplicates
      { "<leader>fe", false },
      { "<leader>fE", false },
      -- Buffers: keep fb, drop the fB (all) duplicate
      { "<leader>fB", false },
      -- Scratch + notifications
      {
        "<leader>bs",
        function()
          Snacks.scratch()
        end,
        desc = "Toggle Scratch Buffer",
      },
      {
        "<leader>bS",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select Scratch Buffer",
      },
      {
        "<leader>snn",
        function()
          Snacks.picker.notifications()
        end,
        desc = "Notification History",
      },
    },
    opts = {
      image = { enabled = false },
    },
  },
  {
    "nanotee/zoxide.vim",
    cmd = { "Z", "Zi", "Lz", "Lzi" },
  },
  -- Harpoon: keep the fast <leader>1-9 jumps but hide them from the which-key
  -- menu (they cluttered the top level). <leader>h (menu) / <leader>H (add) stay
  -- visible. This keys function fully replaces LazyVim's, so it re-declares all.
  {
    "ThePrimeagen/harpoon",
    keys = function()
      local keys = {
        {
          "<leader>H",
          function()
            require("harpoon"):list():add()
          end,
          desc = "Harpoon File",
        },
        {
          "<leader>h",
          function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Harpoon Quick Menu",
        },
      }
      for i = 1, 9 do
        keys[#keys + 1] = {
          "<leader>" .. i,
          function()
            require("harpoon"):list():select(i)
          end,
          desc = "which_key_ignore",
        }
      end
      return keys
    end,
  },
}
