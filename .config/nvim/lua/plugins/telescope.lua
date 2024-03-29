-- Function to find the git root directory based on the current buffer's path
local function find_git_root()
	-- Use the current buffer's path as the starting point for the git search
	local current_file = vim.api.nvim_buf_get_name(0)
	local current_dir
	local cwd = vim.fn.getcwd()
	-- If the buffer is not associated with a file, return nil
	if current_file == "" then
		current_dir = cwd
	else
		-- Extract the directory from the current file's path
		current_dir = vim.fn.fnamemodify(current_file, ":h")
	end

	-- Find the Git root directory from the current file's path
	local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		print("Not a git repository. Searching on current working directory")
		return cwd
	end
	return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
	local git_root = find_git_root()
	if git_root then
		require("telescope.builtin").live_grep({
			search_dirs = { git_root },
		})
	end
end

vim.api.nvim_create_user_command("LiveGrepGitRoot", live_grep_git_root, {})

-- Function to create keymaps easily
local map = function(keys, func, desc)
	vim.keymap.set("n", keys, func, { desc = desc })
end

return {
	{ "nvim-telescope/telescope-ui-select.nvim" },
	{ "nvim-telescope/telescope-dap.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
		},
		config = function()
			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
							["<C-u>"] = false,
							["<C-d>"] = false,
						},
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})
			-- Load extensions
			require("telescope").load_extension("fzf")
			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("dap")

			local builtin = require("telescope.builtin")
			local function telescope_live_grep_open_files()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end

			-- Keymaps
			map("<leader>/", function()
				-- You can pass additional configuration to telescope to change theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, "[/] Fuzzily search in current buffer")
			map("<leader>s/", telescope_live_grep_open_files, "[S]earch [/] in Open Files")
			map("<leader>?", builtin.oldfiles, "[?] Find recently opened files")
			map("<leader><space>", builtin.buffers, "[ ] Find existing buffers")
			map("<leader>ss", builtin.builtin, "[S]earch [S]elect Telescope")
			map("<leader>sf", builtin.find_files, "[S]earch [F]iles")
			map("<leader>sh", builtin.help_tags, "[S]earch [H]elp")
			map("<leader>sw", builtin.grep_string, "[S]earch current [W]ord")
			map("<leader>sg", builtin.live_grep, "[S]earch by [G]rep")
			map("<leader>sd", builtin.diagnostics, "[S]earch [D]iagnostics")
			map("<leader>sr", builtin.resume, "[S]earch [R]esume")
			map("<leader>sF", builtin.git_files, "[S]earch git [F]iles")
			map("<leader>sC", builtin.git_commits, "[S]earch git [C]ommits")
			map("<leader>sG", ":LiveGrepGitRoot<cr>", "[S]earch by [G]rep on Git Root")
		end,
	},
}
