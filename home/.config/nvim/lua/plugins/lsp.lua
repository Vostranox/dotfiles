return {
    "neovim/nvim-lspconfig",
    config = function()
        local lsp = require("lspconfig")
    end,
    vim.diagnostic.config({
        virtual_text = false,
        signs = false,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
    })
}
