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

      -- <localleader>lV: view the compiled PDF inside the terminal with tdf,
      -- opened in a new tmux split. TUI counterpart to <localleader>lv
      -- (SumatraPDF + SyncTeX). Buffer-local so it lives in vimtex's own
      -- <localleader>l group, right next to the standard view command.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "tex",
        callback = function(ev)
          vim.keymap.set("n", "<localleader>lV", function()
            if not vim.env.TMUX then
              return vim.notify("tdf view needs a tmux session", vim.log.levels.WARN)
            end
            if vim.fn.executable("tdf") == 0 then
              return vim.notify("tdf not found (install via bootstrap.sh)", vim.log.levels.WARN)
            end
            local ok, tex = pcall(vim.fn.eval, "b:vimtex.tex")
            if not ok or not tex or tex == "" then
              return vim.notify("vimtex: no main tex file", vim.log.levels.WARN)
            end
            local pdf = vim.fn.fnamemodify(tex, ":r") .. ".pdf"
            if vim.fn.filereadable(pdf) == 0 then
              return vim.notify("No compiled PDF yet — run <localleader>ll first", vim.log.levels.WARN)
            end
            vim.fn.jobstart({ "tmux", "split-window", "-h", "tdf", pdf })
          end, { buffer = ev.buf, desc = "View PDF in terminal (tdf)" })
        end,
      })
    end,
  },
}
