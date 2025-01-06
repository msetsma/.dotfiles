local keymap = vim.keymap

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local opts = { buffer = event.buf }

		keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
		keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
		keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
		keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
		keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
		keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
		keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
		keymap.set("n", "grn", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
		keymap.set({ "n", "x" }, "<leader>fmt", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
		keymap.set("n", "ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
	end,
})
