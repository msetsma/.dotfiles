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
