return {
  "folke/noice.nvim",
  dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
  },
  config = function()
      require("noice").setup({
	views = {
	  cmdline_popup = {
	    position = {
	      row = 10,
	      col = "50%",
	    },
	    size = {
	      width = 60,
	      height = "auto",
	    },
	  },
	  popupmenu = {
	    relative = "editor",
	    position = {
	      row = 13,
	      col = "50%",
	    },
	    size = {
	      width = 60,
	      height = 10,
	    },
	    border = {
	      style = "rounded",
	      padding = { 0, 1 },
	    },
	    win_options = {
	      winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
	    },
	  },
	},
    })
  end,
}
