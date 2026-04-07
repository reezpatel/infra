return {
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		lazy = true,
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
	{
		"echasnovski/mini.nvim",
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.move").setup()
			require("mini.pairs").setup()
			require("mini.operators").setup({
				replace = {
					prefix = "P",
					reindent_linewise = true,
				},
				exchange = { disable = true },
				multiply = { disable = true },
				sort = { disable = true },
			})
			require("mini.comment").setup({
				options = {
					custom_commentstring = function()
						return require("ts_context_commentstring.internal").calculate_commentstring()
							or vim.bo.commentstring
					end,
				},
			})
			require("mini.bracketed").setup()
		end,
	},
}
