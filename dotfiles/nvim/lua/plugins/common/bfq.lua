-- In lua/plugins/bqf.lua
return {
	"kevinhwang91/nvim-bqf",
	ft = "qf",
	dependencies = {
		-- Optional but highly recommended dependencies
		"junegunn/fzf",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		auto_resize_height = true,
		preview = {
			win_height = 12,
			win_vheight = 12,
			delay_syntax = 80,
			border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
			show_title = false,
			should_preview_cb = function(bufnr, qwinid)
				local ret = true
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				local fsize = vim.fn.getfsize(bufname)
				if fsize > 100 * 1024 then
					-- Skip file size greater than 100k
					ret = false
				elseif bufname:match("^fugitive://") then
					-- Skip fugitive buffer
					ret = false
				end
				return ret
			end,
		},
		filter = {
			fzf = {
				extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "> " },
			},
		},
	},
}
