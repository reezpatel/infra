vim.opt.termguicolors = true

vim.opt.number = true

vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- persistent file history
vim.opt.undofile = true

-- relative line numbers
vim.opt.relativenumber = true
vim.opt.number = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true

vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.smartcase = true

vim.opt.colorcolumn = "160"

-- Visual-mode commands
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 400

vim.opt.confirm = true

vim.opt.diffopt = {
	"internal", -- Use Vim's internal diff library
	"filler", -- Show filler lines for added/removed lines to align unchanged text
	"closeoff", -- Turn off diff mode when one of the compared windows is closed
	"indent-heuristic", -- Use indent heuristic for better diff alignment
	"linematch:60", -- Use line matching algorithm with max width of 60 characters
	"algorithm:histogram", -- Use the histogram diff algorithm (better than default)
	"context:20", -- Show 20 lines of context around changes
	"iwhiteall", -- Ignore all whitespace in diff comparison
}

vim.opt.swapfile = false
vim.opt.backup = false

-- Enables incremental search, which means Neovim will show matches for your search pattern as you type it, before you press Enter.
vim.opt.incsearch = true

vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.opt.wildignore:append({ "*/node_modules/*" })

vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"

vim.diagnostic.config({
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = vim.diagnostic.severity.ERROR },
	signs = vim.g.have_nerd_font and {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
	} or {},
	virtual_text = {
		source = "if_many",
		spacing = 2,
		format = function(diagnostic)
			local diagnostic_message = {
				[vim.diagnostic.severity.ERROR] = diagnostic.message,
				[vim.diagnostic.severity.WARN] = diagnostic.message,
				[vim.diagnostic.severity.INFO] = diagnostic.message,
				[vim.diagnostic.severity.HINT] = diagnostic.message,
			}
			return diagnostic_message[diagnostic.severity]
		end,
	},
})
