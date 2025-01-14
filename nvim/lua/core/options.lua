local o = vim.o     -- Global options
local wo = vim.wo   -- Window options
local opt = vim.opt -- Miscellaneous options

-- Line Numbers
wo.number = true        -- Enable line numbers
o.relativenumber = true -- Enable relative line numbers
o.numberwidth = 4       -- Set the width of the number column

-- Indentation
o.autoindent = true  -- Copy indent from the current line when starting a new one
o.smartindent = true -- Enable smart indenting
o.shiftwidth = 4     -- Number of spaces inserted for each indentation
o.tabstop = 4        -- Number of spaces a tab character represents
o.softtabstop = 4    -- Number of spaces a tab counts for while editing
o.expandtab = true   -- Convert tabs to spaces

-- Scrolling and Cursor Behavior
o.scrolloff = 10    -- Minimal number of lines to keep above/below the cursor
o.sidescrolloff = 4 -- Minimal number of columns to keep on either side of the cursor
o.cursorline = true -- highlighting the current line

-- Splits and Window Management
o.splitbelow = true -- Horizontal splits open below the current window
o.splitright = true -- Vertical splits open to the right of the current window

-- Clipboard and Input
o.clipboard = "unnamedplus"      -- Sync clipboard between OS and Neovim
o.backspace = "indent,eol,start" -- Allow unrestricted backspacing
o.mouse = "a"                    -- Enable mouse support
o.whichwrap = "bs<>[]hl"         -- Allow specified keys to wrap lines
--o.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Searching
o.ignorecase = true -- Case-insensitive searching unless capital letters are used
o.smartcase = true  -- Enable smart case search
o.hlsearch = false  -- Disable search highlighting

-- File and Encoding
o.swapfile = false       -- Disable swapfile creation
o.backup = false         -- Disable backup files
o.writebackup = false    -- Prevent editing a file if it's being edited elsewhere
o.undofile = true        -- Enable undo history
o.fileencoding = "utf-8" -- Set file encoding to UTF-8

-- Display and Appearance
o.wrap = false           -- Display lines as one long line
o.linebreak = true       -- Prevent breaking words at the end of lines
opt.termguicolors = true -- Enable true color support
o.pumheight = 10         -- Set popup menu height
o.conceallevel = 0       -- Make backticks visible in markdown
wo.signcolumn = "yes"    -- Always show the sign column
o.cmdheight = 1          -- Command line height
o.showtabline = 2        -- Always show the tab bar
o.showmode = false       -- Disable display of mode (e.g., -- INSERT --)
o.breakindent = true     -- Enable break indent

-- Performance
o.updatetime = 750 -- Reduce update time for faster feedback
o.timeoutlen = 100 -- Time to wait for a mapped sequence (in ms)

-- Completion and Shortcuts
o.completeopt = "menuone,noselect" -- Better completion experience
opt.shortmess:append("c")          -- Suppress completion messages
opt.iskeyword:append("-")          -- Treat hyphenated words as single words

-- Formatting
opt.formatoptions:remove({ "c", "r", "o" }) -- Avoid auto-inserting comment leaders

-- Plugins and Runtime Path
opt.runtimepath:remove("/usr/share/vim/vimfiles") -- Avoid Vim plugins interfering with Neovim
