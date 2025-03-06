local actions = require("buffer-conflict.actions")

local M = {}

local default_config = {}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", default_config, opts or {})

    vim.api.nvim_create_user_command("BufferConflictDiff", actions.buffer_conflict_diff, {})

    vim.api.nvim_create_autocmd({"BufRead", "BufWritePost"}, { callback = actions.update_buf_meta })
    vim.api.nvim_create_user_command("BufferConflictList", actions.buffer_conflict_list, {})
end

return M
