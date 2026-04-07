return {
	{
		"ggandor/leap.nvim",
		enabled = false,
		keys = {
			{ "f", mode = { "n", "x", "o" }, desc = "Leap Forward to" },
			{ "F", mode = { "n", "x", "o" }, desc = "Leap Backward to" },
		},
		config = function(_, opts)
			local leap = require("leap")
			for k, v in pairs(opts) do
				leap.opts[k] = v
			end
			-- leap.add_default_mappings(true)
			--
			vim.keymap.set({ "n", "x", "o" }, "f", "<Plug>(leap-forward)")
			vim.keymap.set({ "n", "x", "o" }, "F", "<Plug>(leap-backward)")

			vim.keymap.del({ "x", "o" }, "x")
			vim.keymap.del({ "x", "o" }, "X")
		end,
	},
}
