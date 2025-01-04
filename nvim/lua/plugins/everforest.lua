return {
	"neanias/everforest-nvim",
	version = false,
	name = "everforest",
	lazy = false,
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function()
		require("everforest").setup({
			background = "medium",
			transparent_background_level = 0,
			italics = true,
		})
		require("everforest").load()
	end,
}