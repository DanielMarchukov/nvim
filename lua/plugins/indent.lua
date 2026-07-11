-- Rainbow indent guides via snacks.indent (already shipped by LazyVim, so no
-- extra plugin and no conflict). The indent guide's `hl` accepts a list of
-- highlight groups that snacks cycles through per indent level.
--
-- Colors are pulled from the active Catppuccin palette so they match the theme
-- (and re-derive on colorscheme/flavor switches), with a Mocha fallback.
return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local levels = 7

    local function set_rainbow_hl()
      local ok, palettes = pcall(require, "catppuccin.palettes")
      local p = ok and palettes.get_palette() or {}
      local colors = {
        p.red or "#f38ba8",
        p.peach or "#fab387",
        p.yellow or "#f9e2af",
        p.green or "#a6e3a1",
        p.teal or "#94e2d5",
        p.blue or "#89b4fa",
        p.mauve or "#cba6f7",
      }
      for i = 1, levels do
        vim.api.nvim_set_hl(0, "SnacksIndent" .. i, { fg = colors[i], nocombine = true })
      end
    end

    set_rainbow_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = set_rainbow_hl,
      desc = "Re-apply rainbow indent colors on theme change",
    })

    local groups = {}
    for i = 1, levels do
      groups[i] = "SnacksIndent" .. i
    end

    opts.indent = opts.indent or {}
    opts.indent.indent = vim.tbl_deep_extend("force", opts.indent.indent or {}, { hl = groups })
    return opts
  end,
}
