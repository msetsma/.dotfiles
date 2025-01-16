local M = {}

function M.toggle_split_orientation()
    local layout = vim.fn.winlayout()
    if layout[1] == 'row' then
        print('in the row logic')
        vim.cmd('wincmd K')
    elseif layout[1] == 'col' then
        vim.cmd('wincmd H')
    end
end
return M
