return {
	"nvim-telescope/telescope.nvim",
	event = "VimEnter",
	branch = "0.1.x",
	dependencies = {
		'nvim-lua/plenary.nvim',
		'nvim-telescope/telescope-fzf-native.nvim',
		'nvim-telescope/telescope-ui-select.nvim',
		'nvim-tree/nvim-web-devicons',
	},
	config = function()
		require("telescope").setup({
			pickers = {
				find_files = {
					file_ignore_patterns = { "node_modules", ".git", ".venv" },
					hidden = true,
				},
			},
			live_grep = {
				file_ignore_patterns = { "node_modules", ".git", ".venv" },
				additional_args = function(_)
					return { "--hidden" }
				end,
			},
		})

		pcall(require("telescope").load_extension, "fzf")

		-- See `:help telescope.builtin`
		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
		vim.keymap.set("n", "<leader>fs", builtin.builtin, { desc = "[F]ind [S]elect Telescope" })
		vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "[F]ind current [W]ord" })
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
		vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "[F]ind [R]esume" })
	end,
}
