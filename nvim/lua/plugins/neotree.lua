return {
	"nvim-neo-tree/neo-tree.nvim",
	cmd = { "Neotree", "NeoTreeReveal" },
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>e", ":Neotree toggle position=left<CR>", desc = "Toggle Explorer" },
	},
	config = function()
		require("neo-tree").setup({
			filesystem = {
				filtered_items = {
					visible = true,
					show_hidden_count = true,
					hide_dotfiles = false,
					hide_gitignored = true,
					hide_by_name = {
						".git",
						".DS_Store",
					},
					never_show = {},
				},
			},
		})
		vim.keymap.set(
			"n",
			"<leader>ee",
			":Neotree toggle position=left<CR>",
			{ desc = "Neotree", noremap = true, silent = true }
		) -- focus file explorer
		vim.keymap.set(
			"n",
			"<leader>eg",
			":Neotree float git_status<CR>",
			{ desc = "Git Status", noremap = true, silent = true }
		) -- open git status window
	end,
}
