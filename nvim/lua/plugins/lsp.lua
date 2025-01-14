return {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
        { 'williamboman/mason.nvim', config = true },
        { 'williamboman/mason-lspconfig.nvim' },
        { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
        { 'saghen/blink.cmp' },
    },
    config = function()
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
            callback = function()
                vim.keymap.set(
                    'n',
                    'gd',
                    require('telescope.builtin').lsp_definitions,
                    { desc = 'LSP: [G]oto [D]efinition' }
                )
                vim.keymap.set(
                    'n',
                    'gr',
                    require('telescope.builtin').lsp_references,
                    { desc = 'LSP: [G]oto [R]eferences' }
                )
                vim.keymap.set(
                    'n',
                    'gI',
                    require('telescope.builtin').lsp_implementations,
                    { desc = 'LSP: [G]oto [I]mplementation' }
                )
                vim.keymap.set(
                    'n',
                    '<leader>D',
                    require('telescope.builtin').lsp_type_definitions,
                    { desc = 'LSP: Type [D]efinition' }
                )
                vim.keymap.set(
                    'n',
                    '<leader>ds',
                    require('telescope.builtin').lsp_document_symbols,
                    { desc = 'LSP: [D]ocument [S]ymbols' }
                )
                vim.keymap.set(
                    'n',
                    '<leader>ws',
                    require('telescope.builtin').lsp_dynamic_workspace_symbols,
                    { desc = 'LSP: [W]orkspace [S]ymbols' }
                )
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'LSP: [R]e[n]ame' })
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'LSP: [G]oto [D]eclaration' })
                vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { desc = 'LSP: [C]ode [A]ction' })
                vim.keymap.set('n', '<leader>th', function() -- inlay hints can move your code
                    vim.lsp.inlay_hint.enable(
                        not vim.lsp.inlay_hint.is_enabled({ bufnr = vim.api.nvim_get_current_buf() })
                    )
                end, { desc = 'LSP: [T]oggle Inlay [H]ints' })
            end,
        })
        --`:help lspconfig-all` list of all the pre-configured LSPs
        local lsp_config = require('lspconfig')
        lsp_config.nushell.setup({})

        -- LSP Settings
        local lsp_mason_servers = {
            dockerls = {},
            jsonls = {},
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

        require('lspconfig').nushell.setup({
            cmd = { 'nu', '--lsp' },
            filetypes = { 'nu' },
            root_dir = require('lspconfig.util').find_git_ancestor,
            single_file_support = true,
        })

        -- Pass LSP Settings to Mason
        require('mason-lspconfig').setup({
            ensure_installed = {
                'lua_ls',
                'rust_analyzer',
                'pylsp',
                'gopls',
                'ruff',
                'dockerls',
                'jsonls',
                'yamlls',
            },
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
