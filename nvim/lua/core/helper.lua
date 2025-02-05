local M = {}

function M.toggle_split_orientation()
    local layout = vim.fn.winlayout()
    if layout[1] == 'row' then
        vim.cmd('wincmd K')
    elseif layout[1] == 'col' then
        vim.cmd('wincmd H')
    end
end

function M.get_os()
    if jit then
        return jit.os
    end
    local fh, _ = assert(io.popen('uname -o 2>/dev/null', 'r'))
    if fh then
        OSname = fh:read()
    end

    return OSname or 'Windows'
end

return M
