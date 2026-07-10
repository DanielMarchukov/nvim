local M = {}

function M.managed_update_languages()
  local ts = require("nvim-treesitter")
  local available = {}

  for _, lang in ipairs(ts.get_available()) do
    available[lang] = true
  end

  local managed = {}
  local external = {}

  for _, lang in ipairs(ts.get_installed()) do
    if available[lang] then
      managed[#managed + 1] = lang
    else
      external[#external + 1] = lang
    end
  end

  return managed, external
end

function M.update_managed_parsers(opts)
  local managed, external = M.managed_update_languages()

  if #external > 0 then
    vim.notify(
      "Skipping externally managed treesitter parsers: " .. table.concat(external, ", "),
      vim.log.levels.DEBUG
    )
  end

  if #managed == 0 then
    if opts and opts.summary then
      require("nvim-treesitter.log").info("No nvim-treesitter-managed parsers are installed")
    end
    return true
  end

  return require("nvim-treesitter").update(managed, opts)
end

return M
