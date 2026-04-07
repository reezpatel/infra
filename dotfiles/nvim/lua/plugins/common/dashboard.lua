return {
	{
		"goolord/alpha-nvim",
		dependencies = { "echasnovski/mini.icons", "RileyGabrielson/inspire.nvim" },
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")
			local inspire = require("inspire")
			local header = {
				"                                                     ",
				"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
				"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
				"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
				"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
				"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
				"  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
				"                                                     ",
			}
			local quote = inspire.get_quote()
			local centered_quote = inspire.center_text(quote.text, quote.author, 52, 8, 52)
			for _, line_text in pairs(centered_quote) do
				table.insert(header, line_text)
			end
			dashboard.section.header.val = header

			-- Updated buttons to match the previous dashboard-nvim configuration
			dashboard.section.buttons.val = {
				dashboard.button("f", "󰈞  > Find File", ":Telescope find_files<CR>"),
				dashboard.button("g", "󰊄  > Find Text", ":Telescope live_grep<CR>"),
				dashboard.button("r", "󰋚  > Recent Files", ":Telescope oldfiles<CR>"),
				dashboard.button("n", "󰈔  > New File", ":enew<CR>"),
				dashboard.button("c", "󰒓  > Config", ":e ~/.config/nvim/init.lua<CR>"),
				dashboard.button("q", "󰩈  > Quit", ":qa<CR>"),
			}

			-- You can also add a footer if desired
			local function footer()
				return "🚀 Neovim loaded in "
					.. vim.fn.printf("%.2f", vim.fn.reltimefloat(vim.fn.reltime(vim.g.start_time or vim.fn.reltime())))
					.. " ms"
			end
			dashboard.section.footer.val = footer()

			alpha.setup(dashboard.opts)
		end,
	},
}
