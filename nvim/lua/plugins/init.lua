return {
    { 'echasnovski/mini.icons', version = false },
    { 'tpope/vim-sleuth', event = { 'BufReadPre', 'BufNewFile' } },
    { 'windwp/nvim-autopairs', event = 'InsertEnter', config = true, opts = {} },
    { 'folke/todo-comments.nvim', ops = {}, event = { 'BufReadPre', 'BufNewFile' } },
    { 'norcalli/nvim-colorizer.lua', opts = {}, event = { 'BufReadPre', 'BufNewFile' } },
    { 'numToStr/Comment.nvim', event = { 'BufReadPre', 'BufNewFile' } },
    { 'folke/which-key.nvim', event = 'VeryLazy', opts = {} },
}
