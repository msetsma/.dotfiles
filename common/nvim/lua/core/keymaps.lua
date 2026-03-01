local keymap = vim.keymap
local helper = require('core.helper')
local opts = { noremap = true, silent = true }

-- Set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Yank
vim.keymap.set('n', '<leader>ya', ':%y<CR>', { desc = 'Yank entire file' })
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv") -- move line down
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv") -- move line up

-- Search
keymap.set('n', '<leader>nh', ':nohl<CR>', { desc = 'Clear search highlights' })
keymap.set(
    'n',
    '<leader>sr',
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = 'search & replace word' }
)

-- Buffers
keymap.set('n', '<Tab>', ':bnext<CR>', opts) -- Go to next buffer
keymap.set('n', '<S-Tab>', ':bprevious<CR>', opts) -- Go to previous buffer
keymap.set('n', '<leader>bx', ':bdelete!<CR>', opts) -- Close buffer
keymap.set('n', '<leader>bo', ':%bdelete|edit#|bdelete#<CR>', opts) -- Close all but active buffer

-- Find and Center
keymap.set('n', 'n', 'nzzzv', opts) -- Next search result and center
keymap.set('n', 'N', 'Nzzzv', opts) -- Previous search result and center

-- Resize Windows with Arrows
keymap.set('n', '<c-Up>', ':resize -2<CR>', opts) -- Decrease height
keymap.set('n', '<c-Down>', ':resize +2<CR>', opts) -- Increase height
keymap.set('n', '<c-Left>', ':vertical resize +2<CR>', opts) -- Decrease width
keymap.set('n', '<c-Right>', ':vertical resize -2<CR>', opts) -- Increase width

-- Indentation in Visual Mode
keymap.set('v', '<', '<gv', opts) -- Stay in indent mode (decrease indent)
keymap.set('v', '>', '>gv', opts) -- Stay in indent mode (increase indent)

-- Register
keymap.set('v', 'p', '"_dP', opts) -- Paste Without Overwriting

-- Delete Without Copying
keymap.set('n', 'x', '"_x', opts) -- Delete character without copying to register

-- Formatting
keymap.set('n', '<leader>fmt', vim.lsp.buf.format)

-- Window Management
keymap.set('n', '<leader>wv', '<C-w>v', { desc = 'Split window vertically', unpack(opts) })
keymap.set('n', '<leader>wh', '<C-w>s', { desc = 'Split window horizontally', unpack(opts) })
keymap.set('n', '<leader>we', '<C-w>=', { desc = 'Equalize split window sizes', unpack(opts) })
keymap.set('n', '<leader>wx', ':close<CR>', { desc = 'Close current split', unpack(opts) })
keymap.set('n', '<leader>ws', helper.toggle_split_orientation, { desc = 'Window Orientation Switch' })
