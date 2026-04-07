return {
	"klen/nvim-test",
	config = function()
		require("nvim-test").setup({
			run = true, -- run tests (using for debug)
			commands_create = true, -- create commands (TestFile, TestLast, ...)
			filename_modifier = ":.", -- modify filenames before tests run(:h filename-modifiers)
			silent = false, -- less notifications
			term = "toggleterm", -- a terminal to run ("terminal"|"toggleterm")
			termOpts = {
				direction = "vertical", -- terminal's direction ("horizontal"|"vertical"|"float")
				width = 96, -- terminal's width (for vertical|float)
				height = 24, -- terminal's height (for horizontal|float)
				go_back = true, -- return focus to original window after executing
				stopinsert = "auto", -- exit from insert mode (true|false|"auto")
				keep_one = true, -- keep only one terminal for testing
			},
			runners = { -- setup tests runners
				cs = "nvim-test.runners.dotnet",
				go = "nvim-test.runners.go-test",
				haskell = "nvim-test.runners.hspec",
				javascriptreact = "nvim-test.runners.jest",
				javascript = "nvim-test.runners.jest",
				lua = "nvim-test.runners.busted",
				python = "nvim-test.runners.pytest",
				ruby = "nvim-test.runners.rspec",
				rust = "nvim-test.runners.cargo-test",
				typescript = "nvim-test.runners.jest",
				typescriptreact = "nvim-test.runners.jest",
			},
			vim.api.nvim_set_keymap(
				"n",
				"<leader>tt",
				":TestNearest<CR>",
				{ noremap = true, silent = true, desc = "Run nearest test" }
			),
			vim.api.nvim_set_keymap(
				"n",
				"<leader>tf",
				":TestFile<CR>",
				{ noremap = true, silent = true, desc = "Run file tests" }
			),
			vim.api.nvim_set_keymap(
				"n",
				"<leader>ts",
				":TestSuite<CR>",
				{ noremap = true, silent = true, desc = "Run test suite" }
			),
			vim.api.nvim_set_keymap(
				"n",
				"<leader>tl",
				":TestLast<CR>",
				{ noremap = true, silent = true, desc = "Run last test" }
			),
			vim.api.nvim_set_keymap(
				"n",
				"<leader>tv",
				":TestVisit<CR>",
				{ noremap = true, silent = true, desc = "Visit test file" }
			),
			require("nvim-test.runners.jest"):setup({
				command = "jest", -- a command to run the test runner
				args = { "--collectCoverage=false" }, -- default arguments

				file_pattern = "\\v(__tests__/.*|(spec|test))\\.(js|jsx|coffee|ts|tsx)$", -- determine whether a file is a testfile
				find_files = { "{name}.test.{ext}", "{name}.spec.{ext}" }, -- find testfile for a file

				filename_modifier = nil, -- modify filename before tests run (:h filename-modifiers)
				working_directory = nil, -- set working directory (cwd by default)
			}),
		})
	end,
}
