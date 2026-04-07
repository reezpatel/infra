return {
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = true,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = {}
				local lsp_format_opt
				if disable_filetypes[vim.bo[bufnr].filetype] then
					lsp_format_opt = "never"
				else
					lsp_format_opt = "fallback"
				end
				return {
					timeout_ms = 500,
					lsp_format = lsp_format_opt,
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				["*"] = { "prettier" },
				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
				--
				-- You can use 'stop_after_first' to run the first available formatter from the list
				json = { "prettierd", "prettier", "jq", "fixjson", stop_after_first = true },
				css = { "prettierd", "prettier", "stylelint", stop_after_first = true },
				mdx = { "prettierd", "prettier", "markdownlint", "mdformat", stop_after_first = true },
				markdown = { "prettierd", "prettier", "markdownlint", "mdformat", stop_after_first = true },
				yaml = { "prettierd", "prettier", "yamlfmt", "yamlfix", stop_after_first = true },
				scss = { "prettierd", "prettier", "stylelint", stop_after_first = true },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				bash = { "beautysh" },
				zsh = { "beautysh" },
				http = { "kulala-fmt" },
				python = { "black" },
				go = { "gofmt" },
			},
		},
	},
}
