# buffer-conflict.nvim

Neovim plugin for resolving conflicts between unsaved buffer changes and disk files.
Compare versions side-by-side in diff-mode, detect external file changes automatically,
and navigate conflicts via an interactive list.

## Usage

### Commands

- `:BufferConflictDiff`
Opens a vertical split showing neovim-native diff-mode:
  - Left pane: Your current unsaved buffer
  - Right pane: Latest file content from disk
  - _Tip_: Use `:diffget`/`:diffput` (`dg`/`dp` keybindings) to synchronize changes between versions.

- `:BufferConflictList`
Displays list of all buffers with newer disk versions. Select an item to automatically focus the buffer

### Keybindings

```lua
-- Show diff between buffer and disk version
vim.keymap.set('n', '<leader>cd', '<cmd>BufferConflictDiff<cr>')

-- List modified buffers
vim.keymap.set('n', '<leader>cl', '<cmd>BufferConflictList<cr>')
```

### Optional: fzf-lua ui

For a better selector interface, add this to your config:

```lua
require("fzf-lua").register_ui_select()
```

This will replace the default selector with fzf-lua's interface when available.

## Installation

### Packer
```lua
use { 'ashurbekovz/buffer-conflict.nvim' }
```
### vim
```lua
Plug 'ashurbekovz/buffer-conflict.nvim'
```

### Lazy.nvim
```lua
{ 'ashurbekovz/buffer-conflict.nvim' }
```
