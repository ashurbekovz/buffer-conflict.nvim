local actions = require("buffer-conflict.actions")

local M = {}

local default_config = {
    autosave = {
        enabled = true,
        interval = 3000
    },
}

local autosave_timer = nil

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", default_config, opts or {})

    vim.api.nvim_create_user_command("BufferConflictDiff", actions.buffer_conflict_diff, {})

    local group = vim.api.nvim_create_augroup("BufferConflict", { clear = true })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = group,
        pattern = "*",
        callback = function(args)
            if vim.api.nvim_buf_is_valid(args.buf) and vim.api.nvim_buf_get_name(args.buf) ~= "" then
                vim.defer_fn(function()
                    if vim.api.nvim_buf_is_valid(args.buf) then
                       actions.update_buffer_modtime(args.buf)
                    end
                end, 100)
            end
        end,
    })

    if autosave_timer then
        autosave_timer:close()
        autosave_timer = nil
    end

    if M.config.autosave.enabled and M.config.autosave.interval > 0 then
        autosave_timer = vim.loop.new_timer()
        autosave_timer:start(M.config.autosave.interval, M.config.autosave.interval, vim.schedule_wrap(function()
            local current_buf = vim.api.nvim_get_current_buf()
            if vim.api.nvim_buf_get_option(current_buf, "modifiable") and vim.api.nvim_buf_get_name(current_buf) ~= "" then
                 actions.attempt_save(current_buf)
             end
        end))
    end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if autosave_timer then
            pcall(function() autosave_timer:close() end)
            autosave_timer = nil
        end
    end,
})

return M
