return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
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
						-- add extension names you want to explicitly exclude
						-- '.git',
						-- '.DS_Store',
						-- 'thumbs.db',
					},
					never_show = {},
				},
			},
		})
		vim.keymap.set("n", "<leader>ee", ":Neotree toggle position=left<CR>", { noremap = true, silent = true }) -- focus file explorer
		vim.keymap.set("n", "<leader>ngs", ":Neotree float git_status<CR>", { noremap = true, silent = true }) -- open git status window
	end,
}
