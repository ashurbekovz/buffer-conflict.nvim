local actions = require("buffer-conflict.actions")

local M = {}

local default_config = {}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", default_config, opts or {})

    vim.api.nvim_create_user_command("BufferConflictDiff", actions.buffer_conflict_diff, {})
end

return M
