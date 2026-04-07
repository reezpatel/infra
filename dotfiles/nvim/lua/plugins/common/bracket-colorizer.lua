-- Place this in your Neovim config, typically in lua/plugins/rainbow-delimiters.lua
-- or include it in your main plugins configuration file

return {
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- Load the rainbow-delimiters module
			local rainbow_delimiters = require("rainbow-delimiters")

			-- Configure the plugin
			require("rainbow-delimiters.setup").setup({
				-- Default strategies
				strategy = {
					[""] = rainbow_delimiters.strategy["global"],
					vim = rainbow_delimiters.strategy["local"],
				},

				-- Default query names
				query = {
					[""] = "rainbow-delimiters",
					lua = "rainbow-blocks",
				},

				-- Default highlight priority
				priority = {
					[""] = 110,
				},

				-- Default delimiter colors
				highlight = {
					"RainbowDelimiterRed",
					"RainbowDelimiterYellow",
					"RainbowDelimiterBlue",
					"RainbowDelimiterOrange",
					"RainbowDelimiterGreen",
					"RainbowDelimiterViolet",
					"RainbowDelimiterCyan",
				},
			})

			-- Optionally set custom colors
		end,
	},
}
