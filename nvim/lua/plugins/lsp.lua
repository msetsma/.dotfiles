return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason")
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lipconfig").setup({
				ensure_installed = {
					"lua_ls",
					"gopls",
					"ruff",
					"rust_analyzer",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")
			lspconfig.lua_ls.setup({})
			lspconfig.gopls.setup({})
			lspconfig.ruff.setup({})
			lspconfig.rust_analyzer.setup({})
		end,
	},
}
