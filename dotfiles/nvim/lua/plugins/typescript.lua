return {

	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {},
	},
	{
		"yioneko/nvim-vtsls",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		event = "VeryLazy",
		config = function()
			local lspconfig = require("lspconfig")
			-- Configure the vtsls server through lspconfig
			lspconfig.vtsls.setup({
				-- Optional: Add capabilities for completion if you use nvim-cmp
				capabilities = vim.lsp.protocol.make_client_capabilities(),
				-- TypeScript settings
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
						},
						-- Add experimental options for better reference finding
						preferences = {
							includePackageJsonAutoImports = "on",
							lazyConfiguredProjectsEnabled = false,
						},
					},
					javascript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
						},
					},
					vtsls = {
						-- Experimental options specific to VTSLS
						experimental = {
							completion = {
								enableServerSideFuzzyMatch = true,
							},
							documentFeatures = {
								documentColor = true,
								documentFormatting = {
									defaultPrintWidth = 100,
								},
								documentSymbol = true,
								foldingRange = true,
							},
							updateImportsOnFileMove = {
								enabled = "always",
							},
							-- This can help with reference searching
							projectWideReferences = true,
						},
						-- Increased memory allocation for more thorough analysis
						memoryLimit = 4096,
					},
				},
				-- Add this to ensure the server indexes more files
				init_options = {
					hostInfo = "neovim",
					maxTsServerMemory = 4096,
					disableAutomaticTypingAcquisition = false,
					locale = "en",
					-- This can help with scanning more files
					preferences = {
						provideRefactorNotApplicableReason = true,
					},
				},
			})
		end,
	},
}
