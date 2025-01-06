local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Search
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
keymap.set("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Search and replace the word under the cursor

-- Buffers
keymap.set("n", "<Tab>", ":bnext<CR>", opts) -- Go to next buffer
keymap.set("n", "<S-Tab>", ":bprevious<CR>", opts) -- Go to previous buffer
keymap.set("n", "<leader>bx", ":bdelete!<CR>", opts) -- Close buffer
keymap.set("n", "<leader>bn", "<cmd>enew<CR>", opts) -- New buffer

-- Find and Center
keymap.set("n", "n", "nzzzv", opts) -- Next search result and center
keymap.set("n", "N", "Nzzzv", opts) -- Previous search result and center

-- Resize Windows with Arrows
keymap.set("n", "<Up>", ":resize -2<CR>", opts) -- Decrease height
keymap.set("n", "<Down>", ":resize +2<CR>", opts) -- Increase height
keymap.set("n", "<Left>", ":vertical resize +2<CR>", opts) -- Decrease width
keymap.set("n", "<Right>", ":vertical resize -2<CR>", opts) -- Increase width

-- Window Management
keymap.set("n", "<leader>sv", "<C-w>v", opts) -- Split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", opts) -- Split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", opts) -- Equalize split window sizes
keymap.set("n", "<leader>sx", ":close<CR>", opts) -- Close current split

-- Navigate between splits
vim.keymap.set("n", "<C-k>", ":wincmd k<CR>", opts)
vim.keymap.set("n", "<C-j>", ":wincmd j<CR>", opts)
vim.keymap.set("n", "<C-h>", ":wincmd h<CR>", opts)
vim.keymap.set("n", "<C-l>", ":wincmd l<CR>", opts)

-- Tabs
keymap.set("n", "<leader>to", ":tabnew<CR>", opts) -- Open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>", opts) -- Close current tab
keymap.set("n", "<leader>tn", ":tabn<CR>", opts) -- Go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>", opts) -- Go to previous tab

-- Toggle Line Wrapping
keymap.set("n", "<leader>lw", "<cmd>set wrap!<CR>", opts) -- Toggle wrap

-- Indentation in Visual Mode
keymap.set("v", "<", "<gv", opts) -- Stay in indent mode (decrease indent)
keymap.set("v", ">", ">gv", opts) -- Stay in indent mode (increase indent)

-- Register
keymap.set("v", "p", '"_dP', opts) -- Paste Without Overwriting

-- Delete Without Copying
keymap.set("n", "x", '"_x', opts) -- Delete character without copying to register

-- Diagnostics
keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- Formatting
keymap.set("n", "<leader>fmt", vim.lsp.buf.format)
