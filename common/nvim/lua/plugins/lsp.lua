return {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
        { 'mason-org/mason.nvim', opts = {} },
        { 'mason-org/mason-lspconfig.nvim' },
        { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
        { 'saghen/blink.cmp' },
        { 'b0o/schemastore.nvim' },
    },
    config = function()
        local capabilities = require('blink.cmp').get_lsp_capabilities()

        -- Configure individual servers via vim.lsp.config (Nvim 0.11+)
        vim.lsp.config('dockerls', { capabilities = capabilities })
        vim.lsp.config('yamlls', { capabilities = capabilities })

        vim.lsp.config('jsonls', {
            capabilities = capabilities,
            settings = {
                json = {
                    validate = { enable = true },
                    format = { enable = true },
                    schemas = require('schemastore').json.schemas(),
                },
            },
        })

        vim.lsp.config('gopls', {
            capabilities = capabilities,
            settings = {
                gopls = {
                    hints = {
                        assignVariableTypes = true,
                        compositeLiteralFields = true,
                        compositeLiteralTypes = true,
                        constantValues = true,
                        functionTypeParameters = true,
                        parameterNames = true,
                        rangeVariableTypes = true,
                    },
                },
            },
        })

        vim.lsp.config('rust_analyzer', {
            capabilities = capabilities,
            settings = {
                ['rust-analyzer'] = {
                    cargo = { features = 'all' },
                    checkOnSave = true,
                    check = { command = 'clippy' },
                },
            },
        })

        vim.lsp.config('pylsp', {
            capabilities = capabilities,
            settings = {
                pylsp = {
                    plugins = { -- let ruff handle these
                        pyflakes = { enabled = false },
                        pycodestyle = { enabled = false },
                        autopep8 = { enabled = false },
                        yapf = { enabled = false },
                        mccabe = { enabled = false },
                        pylsp_mypy = { enabled = false },
                        pylsp_black = { enabled = false },
                        pylsp_isort = { enabled = false },
                    },
                },
            },
        })

        vim.lsp.config('lua_ls', {
            capabilities = capabilities,
            settings = {
                Lua = {
                    completion = { callSnippet = 'Replace' },
                    runtime = { version = 'LuaJIT' },
                    workspace = {
                        checkThirdParty = false,
                        library = { vim.env.VIMRUNTIME },
                    },
                    diagnostics = { disable = { 'missing-fields' } },
                    format = { enable = false },
                },
            },
        })

        vim.lsp.config('nushell', {
            capabilities = capabilities,
            cmd = { 'nu', '--lsp' },
            filetypes = { 'nu' },
            single_file_support = true,
        })

        -- mason-lspconfig auto-enables installed servers via vim.lsp.enable()
        local servers = {
            'dockerls',
            'jsonls',
            'yamlls',
            'gopls',
            'rust_analyzer',
            'pylsp',
            'lua_ls',
        }

        require('mason-lspconfig').setup({
            ensure_installed = servers,
        })

        require('mason-tool-installer').setup({
            ensure_installed = {
                'azure-pipelines-language-server',
                'terraform-ls',
            },
        })

        -- Enable nushell manually (not managed by mason)
        vim.lsp.enable('nushell')
    end,
}
