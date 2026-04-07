-- Add this to your lazy.nvim configuration (typically in lua/plugins/init.lua or similar)

return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2", -- Make sure to use the harpoon2 branch
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")

			-- REQUIRED
			harpoon:setup({
				settings = {
					save_on_toggle = true,
					sync_on_ui_close = true,

					-- Preserve the last marked file when exiting Neovim
					save_on_change = true,

					-- Define which parts of harpoon state should be saved
					components = {
						-- Store marks (files that are harpooned)
						"marks",

						-- Store the tmux functionality
						"tmux",

						-- Store cmd_ui (command window) state
						"cmd_ui",
					},
				},
				-- Optional: override default command handlers
				-- If you don't specify these, harpoon will use default values
				default = {
					marks = 4, -- Max number of marks to show in UI
				},
			})

			-- Basic keymaps for managing marks
			local conf = require("telescope.config").values
			local function toggle_telescope(harpoon_files)
				local file_paths = {}
				for _, item in ipairs(harpoon_files.items) do
					table.insert(file_paths, item.value)
				end

				require("telescope.pickers")
					.new({}, {
						prompt_title = "Harpoon",
						finder = require("telescope.finders").new_table({
							results = file_paths,
						}),
						previewer = conf.file_previewer({}),
						sorter = conf.generic_sorter({}),
					})
					:find()
			end

			-- You can navigate using these keys while within Telescope

			-- Set up keymaps
			vim.keymap.set("n", "<leader>a", function()
				harpoon:list():add()
			end, { desc = "Harpoon: Add file" })
			--
			-- -- Toggle quick menu
			vim.keymap.set("n", "<leader>hh", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Harpoon: Toggle quick menu", noremap = true, silent = true })

			for i = 1, 9 do
				vim.keymap.set("n", "<leader>" .. i, function()
					harpoon:list():select(i)
				end, { desc = "Harpoon: Go to file " .. i })
			end

			-- Remove current file from harpoon list
			vim.keymap.set("n", "<leader>hr", function()
				harpoon:list():remove()
			end, { desc = "Harpoon: Remove current file" })

			-- Clear all marks
			vim.keymap.set("n", "<leader>hc", function()
				harpoon:list():clear()
			end, { desc = "Harpoon: Clear all marks" })
		end,
	},
}
