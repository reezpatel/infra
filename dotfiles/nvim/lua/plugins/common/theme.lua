return {
	-- {
	-- 	"cdmill/neomodern.nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	config = function()
	-- 		require("neomodern").setup({
	-- 			-- optional configuration here
	-- 		})
	-- 		require("neomodern").load()
	-- 	end,
	-- },
	-- {
	-- 	"dgox16/oldworld.nvim",
	-- 	lazy = false,
	-- 	priority = 1000, -- Ensures it loads early, before other plugins
	-- 	config = function()
	-- 		-- Set moonfly as your colorscheme
	-- 		vim.cmd("colorscheme oldworld")
	-- 	end,
	-- },
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
		config = function()
			-- Set moonfly as your colorscheme
			vim.cmd("colorscheme tokyonight-night")
		end,
	}
}
