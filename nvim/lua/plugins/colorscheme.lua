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

local tokyonight = {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
        require('tokyonight').setup()
        require('tokyonight').load()
    end,
}

return tokyonight
