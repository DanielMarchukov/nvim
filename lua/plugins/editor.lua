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
      -- NOTE: <leader>e/E are remap aliases to <leader>fe/fE, so those targets
      -- must stay mapped. (Do NOT disable fe/fE.)
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
  -- Harpoon: everything under one tidy <leader>h submenu (no top-level 1-9
  -- pollution). `ha` add, `hm` menu, `h1`-`h9` jump. This keys function fully
  -- replaces LazyVim's default, so it declares the complete harpoon keymap.
  {
    "ThePrimeagen/harpoon",
    keys = function()
      local keys = {
        {
          "<leader>ha",
          function()
            require("harpoon"):list():add()
          end,
          desc = "Add File",
        },
        {
          "<leader>hm",
          function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Toggle Menu",
        },
      }
      for i = 1, 9 do
        keys[#keys + 1] = {
          "<leader>h" .. i,
          function()
            require("harpoon"):list():select(i)
          end,
          desc = "Jump to File " .. i,
        }
      end
      return keys
    end,
  },
}
