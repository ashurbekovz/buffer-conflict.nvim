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

return M
