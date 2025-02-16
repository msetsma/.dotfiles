return {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-fzf-native.nvim',
        'nvim-telescope/telescope-ui-select.nvim',
        'nvim-tree/nvim-web-devicons',
    },
    config = function()
        require('telescope').setup({
            pickers = {
                find_files = {
                    file_ignore_patterns = { 'node_modules', '.git', '.venv' },
                    hidden = true,
                },
            },
            live_grep = {
                file_ignore_patterns = { 'node_modules', '.git', '.venv' },
                additional_args = function(_)
                    return { '--hidden' }
                end,
            },
        })

        pcall(require('telescope').load_extension, 'fzf')

        -- See `:help telescope.builtin`
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp Tags' })
        vim.keymap.set('n', '<leader>fq', builtin.quickfix, { desc = '[F]ind [Q]uick Fix' })
        vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' })
        vim.keymap.set('n', '<leader>ft', builtin.builtin, { desc = '[F]ind [T]elescope' })
        vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })
        vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = '[F]ind [R]esume' })
        vim.keymap.set('n', '<leader>fc', builtin.current_buffer_fuzzy_find, { desc = '[F]ind in [C]urrent Buffer' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '[F]ind [B]uffer' })
        vim.keymap.set('n', '<leader>fs', builtin.spell_suggest, { desc = '[F]ind [S]pelling' })
    end,
}
