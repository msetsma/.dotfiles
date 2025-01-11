return {
	{
		"echasnovski/mini.icons",
		version = false,
	},
	{ -- Auto tabstop & shiftwidth
		"tpope/vim-sleuth",
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
		opts = {},
	},
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
	},
	{
	  "folke/lazydev.nvim",
	  ft = "lua",
	  cmd = "LazyDev",
	  opts = {
		library = {
		  { path = "${3rd}/luv/library", words = { "vim%.uv" } },
		  { path = "snacks.nvim", words = { "Snacks" } },
		  { path = "lazy.nvim", words = { "LazyVim" } },
			{ path = "wezterm-types", mods = { "wezterm" } },
		},
	  },
	}
}
