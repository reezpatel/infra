return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		keys = {
			{ "<C-\\>", desc = "Toggle terminal" },
			{ "<leader>tmf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal float" },
			{ "<leader>tmh", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal horizontal" },
			{ "<leader>tmv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal vertical" },
		},
		opts = {
			size = function(term)
				if term.direction == "horizontal" then
					return 15
				elseif term.direction == "vertical" then
					return vim.o.columns * 0.4
				end
			end,
			open_mapping = [[<C-\>]],
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			direction = "horizontal",
			close_on_exit = true,
			shell = vim.o.shell,
			float_opts = {
				border = "curved",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
			winbar = {
				enabled = true,
				name_formatter = function(term)
					return term.name
				end,
			},
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)

			function _G.set_terminal_keymaps()
				local opts = { noremap = true }
				-- Navigate between windows while in terminal mode
				vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
				vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
				vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
				vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
				-- Exit terminal mode with Escape
				vim.api.nvim_buf_set_keymap(0, "t", "<Esc>", [[<C-\><C-n>]], opts)
			end

			-- Auto command to set terminal keymaps when entering terminal mode
			vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

			-- Create a lazygit terminal
			local Terminal = require("toggleterm.terminal").Terminal
			local lazygit = Terminal:new({
				cmd = "lazygit",
				hidden = true,
				direction = "float",
				float_opts = {
					border = "curved",
				},
			})

			-- Function to toggle lazygit terminal
			function _G.toggle_lazygit()
				lazygit:toggle()
			end

			-- Lazygit mapping
			vim.api.nvim_set_keymap(
				"n",
				"<leader>tg",
				"<cmd>lua toggle_lazygit()<CR>",
				{ noremap = true, silent = true, desc = "Terminal lazygit" }
			)
		end,
	},
}
