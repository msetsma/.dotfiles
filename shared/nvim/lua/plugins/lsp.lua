return {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
        { 'williamboman/mason.nvim', config = true },
        { 'williamboman/mason-lspconfig.nvim' },
        { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
        { 'saghen/blink.cmp' },
        { 'b0o/schemastore.nvim' },
    },
    config = function()
        --`:help lspconfig-all` list of all the pre-configured LSPs
        local lsp_config = require('lspconfig')
        local lsp_mason_servers = {
            dockerls = {},
            jsonls = {
                settings = {
                    json = {
                        validate = { enable = true },
                        format = { enable = true },
                        schemas = require('schemastore').json.schemas(),
                    },
                },
            },
            yamlls = {},
            gopls = {
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
            },
            rust_analyzer = {
                cargo = {
                    features = 'all',
                },
                checkOnSave = true,
                check = {
                    command = 'clippy',
                },
            },
            pylsp = {
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
            },
            lua_ls = {
                settings = {
                    Lua = {
                        completion = {
                            callSnippet = 'Replace',
                        },
                        runtime = { version = 'LuaJIT' },
                        workspace = {
                            checkThirdParty = false,
                            library = { vim.env.VIMRUNTIME },
                        },
                        diagnostics = { disable = { 'missing-fields' } },
                        format = {
                            enable = false,
                        },
                    },
                },
            },
        }

        local ensure_installed = vim.tbl_keys(lsp_mason_servers)

        table.insert(ensure_installed, { 'azure-pipelines-language-server', 'terraform-ls' })
        require('mason').setup()
        require('mason-tool-installer').setup({ ensure_installed = ensure_installed })

        lsp_config.nushell.setup({
            cmd = { 'nu', '--lsp' },
            filetypes = { 'nu' },
            root_dir = require('lspconfig.util').find_git_ancestor,
            single_file_support = true,
            capabilities = require('blink.cmp').get_lsp_capabilities(),
        })

        require('mason-lspconfig').setup({
            handlers = {
                function(server_name)
                    local server = lsp_mason_servers[server_name] or {}
                    -- Merge Blink capabilities with any existing ones
                    server.capabilities = require('blink.cmp').get_lsp_capabilities(server.capabilities or {})
                    lsp_config[server_name].setup(server)
                end,
            },
        })
    end,
}
