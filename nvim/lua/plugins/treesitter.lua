return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	main = "nvim-treesitter.configs",
	opts = {
		ensure_installed = {
			"c",
			"lua",
			"rust",
			"python",
			"go",
			"dockerfile",
			"toml",
			"json",
			"yaml",
			"markdown",
			"bash",
		},
		auto_install = true,
	},
}
