-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting
vim.opt.clipboard = "unnamedplus"
vim.g.lazyvim_python_lsp = "pyright"

-- WSL: keep Neovim sockets on a Linux runtime dir.
-- Some setups inherit /mnt/wslg/runtime-dir, which can break server socket creation.
if vim.fn.has("wsl") == 1 then
  local runtime_dir = vim.env.XDG_RUNTIME_DIR or ""
  local uv = vim.uv or vim.loop
  local uid = (uv and uv.os_getuid and uv.os_getuid()) or tonumber(vim.env.UID) or 1000
  local uid_runtime_dir = string.format("/run/user/%d", uid)
  if runtime_dir:match("^/mnt/wslg/runtime%-dir/?$") and vim.fn.isdirectory(uid_runtime_dir) == 1 then
    vim.env.XDG_RUNTIME_DIR = uid_runtime_dir
  end
end

-- Neovim 0.11 compatibility for plugins still reading old LSP protocol internals.
do
  local protocol = vim.lsp and vim.lsp.protocol or nil
  if protocol then
    protocol._request_name_to_server_capability = protocol._request_name_to_server_capability
      or protocol._request_name_to_capability

    if protocol._provider_to_client_registration == nil then
      local provider_to_client = {}
      for method, capability_path in pairs(protocol._request_name_to_capability or {}) do
        if type(capability_path) == "table" and #capability_path > 0 then
          local provider = capability_path[#capability_path]
          if type(provider) == "string" and provider ~= "" and provider_to_client[provider] == nil then
            provider_to_client[provider] = vim.split(method, "/", { plain = true })
          end
        end
      end
      protocol._provider_to_client_registration = provider_to_client
    end
  end
end

-- Show diagnostics as virtual lines below the code (wraps naturally, never goes off-screen)
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
})
