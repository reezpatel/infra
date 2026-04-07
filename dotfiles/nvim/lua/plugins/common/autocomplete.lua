return {
	{
		"gelguy/wilder.nvim",
		event = "CmdlineEnter",
		dependencies = {
			"romgrk/fzy-lua-native", -- optional for improved fuzzy finding
		},
		config = function()
			local wilder = require("wilder")
			wilder.setup({
				modes = { ":", "/", "?" },
			})

			-- Enable fuzzy matching for commands and buffers
			-- Use popup menu for wildmenu display
			wilder.set_option(
				"renderer",
				wilder.popupmenu_renderer({
					highlighter = {
						wilder.lua_pcre2_highlighter(), -- requires `luarocks install pcre2`
						wilder.lua_fzy_highlighter(), -- requires fzy-lua-native vim plugin found
						-- at https://github.com/romgrk/fzy-lua-native
					},
					highlights = {
						accent = wilder.make_hl(
							"WilderAccent",
							"Pmenu",
							{ { a = 1 }, { a = 1 }, { foreground = "#f4468f" } }
						),
					},
				})
			)
		end,
	},
}
