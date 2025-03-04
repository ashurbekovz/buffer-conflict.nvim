local M = {}

local default_config = {}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", default_config, opts or {})

    vim.api.nvim_create_autocmd({"BufRead", "BufWritePost"}, {
        callback = function(args)
            local buf = args.buf
            if vim.bo[buf].buftype == "" then
                local filename = vim.api.nvim_buf_get_name(buf)
                if filename ~= "" then
                    local stat = vim.loop.fs_stat(filename)
                    if stat then
                        vim.b[buf].file_sec = stat.mtime.sec
                        vim.b[buf].file_nsec = stat.mtime.nsec
                    end
                end
            end
        end
    })

    vim.api.nvim_create_user_command("BufferConflictList", function()
        local modified_buffers = {}

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].buftype == "" then
                local filename = vim.api.nvim_buf_get_name(buf)
                if filename ~= "" and vim.fn.filereadable(filename) == 1 then
                    local disk_stat = vim.loop.fs_stat(filename)
                    if disk_stat then
                        local disk_sec = disk_stat.mtime.sec
                        local disk_nsec = disk_stat.mtime.nsec

                        local saved_sec = vim.b[buf].file_sec or 0
                        local saved_nsec = vim.b[buf].file_nsec or 0

                        if disk_sec > saved_sec or (disk_sec == saved_sec and disk_nsec > saved_nsec) then
                            table.insert(modified_buffers, {
                                buf = buf,
                                name = filename,
                            })
                        end
                    end
                end
            end
        end

        local choices = {}
        for i, buf_info in ipairs(modified_buffers) do
            table.insert(choices, string.format("%d: %s", i, buf_info.name))
        end

        vim.ui.select(choices, {
            prompt = "Select a buffer to open:",
            format_item = function(item)
                return item
            end,
        }, function(choice)
                if choice then
                    local buf_index = tonumber(string.match(choice, "%d+"))
                    local buf_info = modified_buffers[buf_index]
                    vim.api.nvim_set_current_buf(buf_info.buf)
                end
            end)
    end, {})
end

return M
