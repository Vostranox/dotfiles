return {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim", "nvim-lspconfig" },
    config = function()
        require("mason-lspconfig").setup {
            handlers = {
                function(server)
                    require("lspconfig")[server].setup {}
                end,
            },
        }
    end
}
