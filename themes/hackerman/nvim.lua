return {
	{
		"bjarneo/hackerman.nvim",
		dependencies = { "bjarneo/aether.nvim" }, -- Ensure aether is loaded first
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("hackerman")
		end,
	},
}