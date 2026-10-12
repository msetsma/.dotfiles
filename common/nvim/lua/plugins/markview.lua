return {
    'OXY2DEV/markview.nvim',
    lazy = false,
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'echasnovski/mini.icons',
    },
    keys = {
        {
            '<leader>uh',
            '<cmd>Markview toggle<CR>',
            ft = 'html',
            desc = 'Toggle HTML preview',
        },
        {
            '<leader>uH',
            '<cmd>Markview splitToggle<CR>',
            ft = 'html',
            desc = 'Toggle HTML split preview',
        },
    },
    opts = {
        preview = {
            filetypes = { 'html' },
        },
    },
}
