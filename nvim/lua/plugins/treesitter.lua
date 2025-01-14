return {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPre', 'BufNewFile' },
    build = ':TSUpdate',
    config = function()
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
                'markdown',
                'bash',
                'nu',
            },
            auto_install = true,
            highlights = {
                enable = true,
            },
        })
    end,
}
