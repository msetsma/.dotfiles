local everforest = {
    'neanias/everforest-nvim',
    name = 'everforest',
    lazy = false,
    priority = 1000,
    config = function()
        require('everforest').setup({
            background = 'hard',
            transparent_background_level = 0,
            italics = true,
        })
        require('everforest').load()
    end,
}

local onedark = {
    'olimorris/onedarkpro.nvim',
    lazy = false,
    priority = 1000,
    config = function()
        require('onedarkpro').setup({})
        require('onedarkpro').load()
    end,
}

local night_owl = {
    'oxfist/night-owl.nvim',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
        require('night-owl').setup()
        vim.cmd.colorscheme('night-owl')
    end,
}

local catppuccin = {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    lazy = false,
    config = function()
        require('catppuccin').setup({
            flavour = 'auto', -- latte, frappe, macchiato, mocha
        })
        require('catppuccin').load()
    end,
}

return catppuccin
