local M = {}

function M.buffer_conflict_diff()
    local original_win_id = vim.api.nvim_get_current_win()
    local original_buf_id = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(original_buf_id)

    if file_path == "" then
        vim.notify("Buffer is not associated with a file", vim.log.levels.ERROR)
        return
    end

    local file_content = vim.fn.readfile(file_path)
    if not file_content then
        vim.notify("Failed to read file: " .. file_path, vim.log.levels.ERROR)
        return
    end

    local temp_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(temp_buf, 0, -1, true, file_content)
    vim.api.nvim_buf_set_option(temp_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(temp_buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(temp_buf, "swapfile", false)
    vim.api.nvim_buf_set_name(temp_buf, "[disk] " .. file_path)

    vim.cmd("rightbelow vsplit")
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), temp_buf)
    vim.cmd("diffthis")

    vim.api.nvim_set_current_win(original_win_id)
    vim.cmd("diffthis")
end

function M.update_buf_meta(args)
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

function M.buffer_conflict_list()
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

            vim.cmd("set eventignore=all") -- игнорируем все события
            vim.cmd("noautocmd silent! buffer " .. buf_info.buf) -- переключаем буфер без триггеров
            vim.cmd("set eventignore=") -- восстанавливаем настройки

            end
        end)
end

return M
