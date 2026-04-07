local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight yanked text
autocmd("TextYankPost", {
	desc = "Highlight yanked text",
	group = augroup("YankHighlight", {}),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Disable eslint on node_modules
autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "**/node_modules/**", "node_modules", "/node_modules/*" },
	group = augroup("DisableEslintOnNodeModules", {}),
	callback = function()
		vim.diagnostic.enable(false)
	end,
})
