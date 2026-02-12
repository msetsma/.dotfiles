return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nushell/tree-sitter-nu',
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        event = { 'BufReadPre', 'BufNewFile' },
        build = ':TSUpdate',
        config = function()
            vim.defer_fn(function()
                require('nvim-treesitter.configs').setup({
                    ensure_installed = {
                        'bash',
                        'dockerfile',
                        'lua',
                        'c',
                        'lua',
                        'rust',
                        'python',
                        'go',
                        'dockerfile',
                        'toml',
                        'json',
                        'yaml',
                        'toml',
                        'markdown',
                        'bash',
                        'nu',
                    },
                    sync_install = false,
                    auto_install = true,
                    highlights = {
                        enable = true,
                    },
                    textobjects = {
                        select = {
                            enable = true,
                            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                            keymaps = {
                                -- You can use the capture groups defined in textobjects.scm
                                ['aa'] = '@parameter.outer',
                                ['ia'] = '@parameter.inner',
                                ['af'] = '@function.outer',
                                ['if'] = '@function.inner',
                                ['ac'] = '@class.outer',
                                ['ic'] = '@class.inner',
                            },
                        },
                    },
                })
            end, 0)
        end,
    },

    {
        'nvim-treesitter/nvim-treesitter-context',
        config = function()
            local tc = require('treesitter-context')
            tc.setup({
                enable = true,
                max_lines = 5,
                min_window_height = 0,
                line_numbers = true,
                multiline_threshold = 20,
                trim_scope = 'outer',
                mode = 'cursor',
                separator = '-',
                zindex = 20,
            })
            vim.keymap.set('n', '<leader>ct', tc.toggle, { silent = true })
            vim.keymap.set('n', '<leader>cu', tc.go_to_context, { silent = true })
        end,
    },
}
