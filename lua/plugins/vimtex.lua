return {
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        options = {
          "-lualatex",
          "-interaction=nonstopmode",
          "-synctex=1",
        },
      }
      -- SumatraPDF on Windows via WSL
      vim.g.vimtex_view_method = "general"
      vim.g.vimtex_view_general_viewer = "SumatraPDF.exe"
      vim.g.vimtex_view_general_options = "-reuse-instance -forward-search @tex @line @pdf"
    end,
  },
}
