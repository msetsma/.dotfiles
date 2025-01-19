-- Auto resize splits when the terminal's window is resized
vim.api.nvim_create_autocmd('VimResized', {
    command = 'wincmd =',
})

-- Automatically switch to the next buffer when creating a new split
vim.api.nvim_create_autocmd('WinNew', {
    callback = function()
        -- Get a list of all buffers
        local buffers = vim.tbl_filter(function(buf)
            return vim.fn.buflisted(buf) == 1
        end, vim.api.nvim_list_bufs())

        local current = vim.api.nvim_get_current_buf()

        -- Find the next listed buffer
        local nextbuf = nil
        for _, buf in ipairs(buffers) do
            if buf > current then
                nextbuf = buf
                break
            end
        end

        -- If no next buffer, cycle back to the first one
        if not nextbuf and #buffers > 0 then
            nextbuf = buffers[1]
        end

        -- Switch to the next buffer
        if nextbuf then
            vim.api.nvim_set_current_buf(nextbuf)
        end
    end,
})

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
    callback = function()
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', 'gd', builtin.lsp_definitions, { desc = '[G]oto [D]efinition' })
        vim.keymap.set('n', 'gr', builtin.lsp_references, { desc = '[G]oto [R]eferences' })
        vim.keymap.set('n', 'gI', builtin.lsp_implementations, { desc = '[G]oto [I]mplementation' })
        vim.keymap.set('n', '<leader>D', builtin.lsp_type_definitions, { desc = 'Type [D]efinition' })
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = '[G]oto [D]eclaration' })
        vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { desc = '[C]ode [A]ction' })
        vim.keymap.set('n', '<leader>uh', function() -- inlay hints can move your code
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = vim.api.nvim_get_current_buf() }))
        end, { desc = '[T]oggle Inlay [H]ints' })
    end,
})
