-- tests/buffer-conflict_spec.lua
local assert = require("luassert")
local mock = require('luassert.mock')

describe("buffer-conflict.nvim", function()
    local test_dir = "/tmp/nvim_buffer_conflict_test"
    local test_file = test_dir .. "/test_file.txt"

    before_each(function()
        clear()
        vim.cmd("silent !rm -rf " .. test_dir)
        vim.cmd("silent !mkdir -p " .. test_dir)
        vim.cmd("silent !echo 'initial content' > " .. test_file)

        package.loaded["buffer-conflict"] = nil
        require("buffer-conflict").setup()
    end)

    after_each(function()
        vim.cmd("silent !rm -rf " .. test_dir)
    end)

    it("should register BufferConflictList command", function()
        local commands = vim.api.nvim_get_commands({})
        assert.truthy(commands.BufferConflictList)
    end)

    it("should detect modified files", function()
        vim.cmd("edit! " .. test_file)
        local buf = vim.api.nvim_get_current_buf()

        local new_mtime = {
            sec = os.time() + 1000,
            nsec = 0
        }

        mock(vim.loop, "fs_stat", function()
            return { mtime = new_mtime }
        end)

        local selected_buf
        mock(vim.ui, "select", function(_, _, cb)
            selected_buf = buf
            cb(1)
        end)

        vim.cmd("BufferConflictList")

        assert.equals(buf, vim.api.nvim_get_current_buf())
    end)

    it("should not detect unmodified files", function()
        vim.cmd("edit! " .. test_file)
        local original_mtime = vim.loop.fs_stat(test_file).mtime

        mock(vim.loop, "fs_stat", function()
            return { mtime = original_mtime }
        end)

        local ui_called = false
        mock(vim.ui, "select", function()
            ui_called = true
        end)

        vim.cmd("BufferConflictList")
        assert.is_false(ui_called)
    end)

    it("should handle multiple buffers", function()
        for i = 1, 3 do
            local f = test_dir .. "/file" .. i .. ".txt"
            vim.fn.writefile({"content " .. i}, f)
            vim.cmd("edit! " .. f)
        end

        mock(vim.loop, "fs_stat", function()
            return { mtime = { sec = os.time() + 1000, nsec = 0 } }
        end)

        local selection
        mock(vim.ui, "select", function(items, _, cb)
            selection = items
            cb(2) -- select second item
        end)

        vim.cmd("BufferConflictList")

        assert.equals(3, #selection)
        assert.equals("2: " .. test_dir .. "/file2.txt", selection[2])
        assert.equals(2, vim.fn.bufnr("%"))
    end)

    it("should ignore non-file buffers", function()
        vim.cmd("edit! " .. test_file)
        vim.cmd("vnew | set buftype=nofile")

        mock(vim.loop, "fs_stat", function()
            return { mtime = { sec = os.time() + 1000, nsec = 0 } }
        end)

        local ui_called = false
        mock(vim.ui, "select", function()
            ui_called = true
        end)

        vim.cmd("BufferConflictList")
        assert.is_false(ui_called)
    end)
end)
