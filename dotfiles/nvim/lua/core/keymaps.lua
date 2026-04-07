local keyset = vim.keymap.set

keyset("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Handle movement across panes
keyset("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
keyset("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
keyset("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
keyset("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.keymap.set("n", "<A-S-A>", "<c-w>5>", { desc = "Move window left" })
vim.keymap.set("n", "<A-S-D>", "<c-w>5<", { desc = "Move window right" })
vim.keymap.set("n", "<A-S-W>", "<c-w>+", { desc = "Move window up" })
vim.keymap.set("n", "<A-S-S>", "<c-w>-", { desc = "Move window down" })

-- Normal-mode commands
vim.keymap.set("n", "<A-Down>", ":MoveLine 1<CR>", { noremap = true, silent = true, desc = "Move line up" })
vim.keymap.set("n", "<A-Up>", ":MoveLine -1<CR>", { noremap = true, silent = true, desc = "Move line down" })
vim.keymap.set("n", "<A-S-Left>", ":MoveWord -1<CR>", { noremap = true, silent = true, desc = "Move word left" })
vim.keymap.set("n", "<A-S-Right>", ":MoveWord 1<CR>", { noremap = true, silent = true, desc = "Move word right" })

vim.keymap.set("x", "<A-Up>", ":MoveBlock 1<CR>", { noremap = true, silent = true, desc = "Move selected block up" })
vim.keymap.set(
	"x",
	"<A-Down>",
	":MoveBlock -1<CR>",
	{ noremap = true, silent = true, desc = "Move selected block down" }
)
vim.keymap.set(
	"v",
	"<A-Left>",
	":MoveHBlock -1<CR>",
	{ noremap = true, silent = true, desc = "Move selected block left" }
)
vim.keymap.set(
	"v",
	"<A-Right>",
	":MoveHBlock 1<CR>",
	{ noremap = true, silent = true, desc = "Move selected block right" }
)

keyset("n", "tn", ":tabnew %<CR>", { desc = "New tab" })

keyset("n", "<leader><leader>x", function()
	vim.cmd("so")
end, { desc = "Source current buffer" })

keyset("n", "<leader>wf", ":noautocmd w<CR>", { desc = "Save without formatting" })

-- try it later
keyset("n", "<C-p>", "<cmd>cprev<CR>zz", { desc = "Previous quickfix item" })
keyset("n", "<C-n>", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })

keyset("n", "<leader>gf", ":top Git<CR>", { desc = "Fugitive: Open git console" })

keyset("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic list" })

-- search for highlighted text
keyset("x", "<leader>/", 'y/\\V<C-r>"<CR>', { noremap = true, silent = true })

-- Open terminal below
keyset("n", "<leader>st", function()
	vim.cmd.new()
	vim.cmd.wincmd("J") -- Move to the window below
	vim.api.nvim_win_set_height(0, 12)
	vim.wo.winfixheight = true
	vim.cmd.term()
end, { desc = "Open terminal below" })

keyset("t", "<C-z>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- cmd = { "TodoTelescope", "TodoTrouble", "TodoLocList", "TodoQuickFix" },
-- keys = {
-- 	{ "<leader>sc", "<cmd>TodoTelescope<cr>", desc = "Todo Telescope" },
-- 	{ "<leader>xT", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
-- },
