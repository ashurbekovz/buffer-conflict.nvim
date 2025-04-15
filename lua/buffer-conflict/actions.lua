local M = {}

local function get_file_modtime(file_path)
    local stat = vim.loop.fs_stat(file_path)
    if stat then
        return stat.mtime.sec * 1e9 + stat.mtime.nsec
    end
    return nil
end

local function get_buffer_disk_modtime(bufnr)
    return vim.b[bufnr].buffer_conflict_disk_modtime
end

local function set_buffer_disk_modtime(bufnr, modtime)
    vim.b[bufnr].buffer_conflict_disk_modtime = modtime
end

function M.update_buffer_modtime(bufnr)
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    if file_path and file_path ~= "" then
        local current_modtime = get_file_modtime(file_path)
        set_buffer_disk_modtime(bufnr, current_modtime)
    end
end

local function check_disk_change(bufnr)
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    if not file_path or file_path == "" then return false end

    local stored_modtime = get_buffer_disk_modtime(bufnr)
    local current_modtime = get_file_modtime(file_path)

    if stored_modtime == nil and current_modtime == nil then return false end
    if stored_modtime == current_modtime then return false end

    return true
end

local function force_save(bufnr)
     if not vim.api.nvim_buf_is_valid(bufnr) then return end
     vim.api.nvim_buf_call(bufnr, function()
         vim.cmd("write")
     end)
end

local function force_load(bufnr)
     if not vim.api.nvim_buf_is_valid(bufnr) then return end
     local file_path = vim.api.nvim_buf_get_name(bufnr)
     if not file_path or file_path == "" then
         vim.notify("Cannot load, buffer has no file path.", vim.log.levels.WARN)
         return
     end

     local stat = vim.loop.fs_stat(file_path)
      if not stat then
         vim.notify("Cannot load, file not found on disk: " .. file_path, vim.log.levels.ERROR)
         return
      end

     vim.api.nvim_buf_call(bufnr, function()
         vim.cmd("noautocmd edit! " .. vim.fn.fnameescape(file_path))
     end)
end

function M.buffer_conflict_diff()
    local original_buf_id = vim.api.nvim_get_current_buf()
    local original_win_id = vim.api.nvim_get_current_win()
    local file_path = vim.api.nvim_buf_get_name(original_buf_id)

    if file_path == "" then
        vim.notify("Buffer is not associated with a file", vim.log.levels.ERROR)
        return
    end

    local stat = vim.loop.fs_stat(file_path)
    if not stat then
       vim.notify("File does not exist on disk: " .. file_path, vim.log.levels.ERROR)
       return
    end

    local read_ok, file_content_lines = pcall(vim.api.nvim_read_file, file_path, {})
    if not read_ok or not file_content_lines then
        vim.notify("Failed to read file content: " .. file_path, vim.log.levels.ERROR)
        return
    end

    local temp_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, file_content_lines)
    vim.api.nvim_buf_set_option(temp_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(temp_buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(temp_buf, "swapfile", false)
    vim.api.nvim_buf_set_name(temp_buf, "[disk] " .. vim.fn.fnamemodify(file_path, ":t"))
    vim.api.nvim_buf_set_option(temp_buf, "readonly", true)

    vim.api.nvim_set_current_win(original_win_id)
    vim.cmd("rightbelow vsplit")
    local temp_win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(temp_win_id, temp_buf)

    vim.api.nvim_win_set_option(temp_win_id, "diff", true)
    vim.api.nvim_win_set_option(temp_win_id, "scrollbind", true)
    vim.api.nvim_win_set_option(original_win_id, "diff", true)
    vim.api.nvim_win_set_option(original_win_id, "scrollbind", true)

    vim.api.nvim_set_current_win(original_win_id)
end

local function prompt_conflict_resolution(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local choices = { "S&ave buffer (overwrite disk)", "L&oad from disk (discard buffer changes)", "D&iff changes", "&Cancel" }

    vim.schedule(function()
        vim.ui.select(choices, {
            prompt = "Conflict detected for " .. vim.fn.fnamemodify(file_path, ":t") .. ". File changed on disk. Choose action:",
            format_item = function(item) return item:gsub("&", "") end
        }, function(choice)
            if not choice then
                vim.notify("Conflict resolution cancelled.")
                return
            end

            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(bufnr) then return end -- Re-check validity

                if choice == choices[1] then
                    force_save(bufnr)
                elseif choice == choices[2] then
                    force_load(bufnr)
                elseif choice == choices[3] then
                    vim.api.nvim_set_current_buf(bufnr)
                    M.buffer_conflict_diff()
                elseif choice == choices[4] then
                    vim.notify("Conflict resolution cancelled.")
                end
           end)
        end)
    end)
end

function M.attempt_save(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_name(bufnr) == "" then return end

    if not vim.api.nvim_buf_get_option(bufnr, "modified") then
        return
    end

    if check_disk_change(bufnr) then
        vim.notify("Conflict detected for " .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t'), vim.log.levels.WARN)
        prompt_conflict_resolution(bufnr)
    else
        force_save(bufnr)
    end
end


return M
