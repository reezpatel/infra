return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "williamboman/mason.nvim", opts = {} },
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		"hrsh7th/cmp-nvim-lsp",
	},
	event = "VeryLazy",
	config = function()
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

		local servers = {
			lua_ls = require("plugins.lsp.servers.lua_ls"),
			tailwindcss = require("plugins.lsp.servers.tailwindcss"),
			cssls = require("plugins.lsp.servers.cssls"),
			eslint = require("plugins.lsp.servers.eslint"),
			ts_ls = require("plugins.lsp.servers.tsls"),
			vtsls = require("plugins.lsp.servers.vtsls"),
			jsonls = require("plugins.lsp.servers.jsonls"),
			yamlls = require("plugins.lsp.servers.yamlls"),
			bashls = require("plugins.lsp.servers.bash"),
			gopls = require("plugins.lsp.servers.gopls"),
			terraform_ls = require("plugins.lsp.servers.terraformls"),
		}

		local ensure_installed = vim.tbl_keys(servers or {})

		vim.list_extend(ensure_installed, {
			"stylua", -- Used to format Lua code
			"js-debug-adapter",
			"black",
			"gofumpt",
		})

		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		capabilities.textDocument.foldingRange = {
			dynamicRegistration = false,
			lineFoldingOnly = true,
		}

		require("mason-lspconfig").setup({
			ensure_installed = {},
			automatic_installation = false,
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})

					require("lspconfig")[server_name].setup(server)

					print(vim.inspect(server_name))

					if config and server.keys then
						for _, key in ipairs(config.keys) do
							vim.keymap.set("n", key[1], key[2], { desc = key.desc })
						end
					end
				end,
			},
		})

		require("plugins.lsp.functions.attach")

		-- setup_server("stylelint_lsp")
		-- setup_server("basedpyright")
		-- setup_server("jsonls", require("plugins.lsp.servers.jsonls"))
		-- setup_server("yamlls", require("plugins.lsp.servers.yamlls"))
		-- setup_server("bashls", require("plugins.lsp.servers.bashls"))
		-- setup_server("tailwindcss", require("plugins.lsp.servers.tailwindcss"))
		-- setup_server("cssls", require("plugins.lsp.servers.cssls"))
		-- setup_server("eslint", require("plugins.lsp.servers.eslint"))
		-- setup_server("vtsls", require("plugins.lsp.servers.vtsls"))
		-- setup_server("gopls", require("plugins.lsp.servers.gopls"))
	end,
}
