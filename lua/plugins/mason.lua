return {
  {
    "williamboman/mason.nvim",
    dependencies = {},
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "clangd",
        "clang-format",
        "cmakelang",
        "gradle-language-server",
        "jdtls",
      },
    },
  },
}
