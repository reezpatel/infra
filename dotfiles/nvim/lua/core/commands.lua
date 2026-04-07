-- set buffer to json
vim.api.nvim_create_user_command("Json", function()
	vim.bo.filetype = "json"
end, {
	desc = "Set buffer filetype to JSON",
	nargs = 0,
})

-- set buffer to js
vim.api.nvim_create_user_command("Js", function()
	vim.bo.filetype = "js"
end, {
	desc = "Set buffer filetype to JSON",
	nargs = 0,
})
