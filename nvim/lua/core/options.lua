local opt = vim.opt

-- Line Numbers
opt.relativenumber = true
opt.number = true

-- Indentation
opt.autoindent = true
opt.smartindent = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.expandtab = true

-- Scrolling and Cursor Behavior
opt.scrolloff = 10
opt.cursorline = true

-- Splits and Window Management
opt.splitbelow = true
opt.splitright = true

-- Clipboard and Input
opt.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim
opt.backspace = 'indent,eol,start' -- Allow unrestricted backspacing
opt.mouse = 'a'
opt.whichwrap = 'bs<>[]hl' -- Allow specified keys to wrap lines
-- opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Searching
opt.ignorecase = true
opt.smartcase = true

-- File and Encoding
opt.swapfile = false
opt.backup = false
opt.writebackup = false -- Prevent editing a file if it's being edited elsewhere
opt.undofile = true -- Enable undo history
opt.fileencoding = 'utf-8' -- Set file encoding to UTF-8

-- Display and Appearance
opt.wrap = false
opt.linebreak = true
opt.termguicolors = true
opt.conceallevel = 0
opt.signcolumn = 'yes'

-- Performance
opt.updatetime = 50 -- Reduce update time for faster feedback
opt.timeoutlen = 100 -- Time to wait for a mapped sequence (in ms)

-- Completion and Shortcuts
opt.completeopt = 'menuone,noselect' -- Better completion experience
opt.shortmess:append('c') -- Suppress completion messages
opt.iskeyword:append('-') -- Treat hyphenated words as single words

-- Formatting
opt.formatoptions:remove({ 'o', 'r' })
opt.list = true
opt.listchars = {
    tab = '» ',
    trail = '·',
    extends = '>',
    precedes = '<',
    nbsp = '␣',
}
