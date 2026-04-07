return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			{ "windwp/nvim-ts-autotag", opts = {} },
			{ "nvim-treesitter/nvim-treesitter-context", opts = { enable = false } },
		},
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")
			local parsers = require("nvim-treesitter.parsers")

			configs.setup({
				ensure_installed = {
					"c",
					"lua",
					"vim",
					"vimdoc",
					"bash",
					"css",
					"diff",
					"dockerfile",
					"go",
					"gomod",
					"gowork",
					"graphql",
					"html",
					"javascript",
					"jsdoc",
					"json",
					"json5",
					"lua",
					"markdown",
					"markdown_inline",
					"php",
					"prisma",
					"python",
					"regex",
					"rust",
					"scss",
					"sql",
					"tsx",
					"typescript",
					"vim",
					"vimdoc",
					"yaml",
				},
				sync_install = false,
				highlight = { enable = true },
				indent = { enable = true },
			})

			local parser_configs = parsers.get_parser_configs()
			parser_configs.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
		end,
	},
}
