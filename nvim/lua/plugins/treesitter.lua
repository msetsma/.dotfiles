return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	main = "nvim-treesitter.configs",
	opts = {
		ensure_installed = {
			"c",
			"lua",
			"rust",
			"python",
			-- "javascript", -- ew
			-- "typescript", -- ew
			"vimdoc",
			"vim",
			"dockerfile",
			"toml",
			"json",
			"go",
			"yaml",
			"markdown",
			"bash",
		},
		auto_install = true,
		highlight = {
			enable = true,
		},
	},
}
