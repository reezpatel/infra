-- Place this in your Neovim config folder
-- If using init.lua: Add to your init.lua
-- If using separate files: ~/.config/nvim/lua/plugins/lualine.lua
return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "kvrohit/mellow.nvim" },
	event = "VeryLazy", -- Load after UI is ready
	config = function()
		-- Use mellow colors instead of kanagawa
		local colors = {
			bg = "#161617",
			fg = "#c9c7cd",
			yellow = "#e0d561",
			cyan = "#74dfc4",
			darkblue = "#7aa4a1",
			green = "#61af88",
			orange = "#f49d75",
			violet = "#b4a4de",
			magenta = "#cf9bc2",
			blue = "#91b9c7",
			red = "#ee6a70",
		}

		local mellow_lualine = {
			normal = {
				a = { bg = colors.blue, fg = colors.bg },
				b = { bg = "#212122", fg = colors.fg },
				c = { bg = "#1b1b1c", fg = colors.fg },
			},
			insert = {
				a = { bg = colors.green, fg = colors.bg },
				b = { bg = "#212122", fg = colors.fg },
				c = { bg = "#1b1b1c", fg = colors.fg },
			},
			visual = {
				a = { bg = colors.violet, fg = colors.bg },
				b = { bg = "#212122", fg = colors.fg },
				c = { bg = "#1b1b1c", fg = colors.fg },
			},
			replace = {
				a = { bg = colors.orange, fg = colors.bg },
				b = { bg = "#212122", fg = colors.fg },
				c = { bg = "#1b1b1c", fg = colors.fg },
			},
			command = {
				a = { bg = colors.yellow, fg = colors.bg },
				b = { bg = "#212122", fg = colors.fg },
				c = { bg = "#1b1b1c", fg = colors.fg },
			},
			inactive = {
				a = { bg = "#181819", fg = colors.fg },
				b = { bg = "#181819", fg = colors.fg },
				c = { bg = "#181819", fg = colors.fg },
			},
		}

		require("lualine").setup({
			options = {
				theme = mellow_lualine,
				component_separators = { left = "|", right = "|" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				globalstatus = true,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
				},
			},
			sections = {
				lualine_a = {
					{
						"mode",
						fmt = function(str)
							return str:sub(1, 1)
						end,
					},
				},
				lualine_b = {
					{ "diff", colored = true },
					{ "diagnostics", sources = { "nvim_diagnostic" } },
				},
				lualine_c = {
					{ "filename", path = 1 }, -- 0 = just filename, 1 = relative path, 2 = absolute path
				},
				lualine_x = {
					{ "filetype", colored = true, icon_only = false },
					"encoding",
				},
				lualine_z = { "location" },
				lualine_y = {
					{
						function()
							local buf_clients = vim.lsp.get_clients()
							if next(buf_clients) == nil then
								return "No LSP"
							else
								-- Just return the first client name
								for _, client in pairs(buf_clients) do
									return client.name
								end
							end
						end,
						color = { fg = colors.magenta },
					},
				},
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {
				"nvim-tree",
				"toggleterm",
				"fugitive",
				"quickfix",
				"lazy",
			},
		})
	end,
}
