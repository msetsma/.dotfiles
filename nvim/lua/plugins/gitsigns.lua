-- Adds git related signs to the gutter, as well as utilities for managing changes
return {
"lewis6991/gitsigns.nvim",  
event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
		add          = { text = '┃' },
		change       = { text = '┃' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' },
	  },
	  signs_staged = {
		add          = { text = '┃' },
		change       = { text = '┃' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' },
	  },
  },
}
