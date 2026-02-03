# sftp.nvim

A lightweight SFTP plugin for Neovim with automatic upload on save. Compatible with the VSCode SFTP extension configuration format.

## Features

- **Upload on save** - Automatically sync files to remote server when saving
- **VSCode compatible** - Uses `.vscode/sftp.json` configuration format
- **Async operations** - Non-blocking file transfers using Neovim's job control
- **Multiple auth methods** - SSH key or password authentication
- **Ignore patterns** - Skip files matching specified patterns
- **External change detection** - Uploads files modified by external tools

## Requirements

- Neovim >= 0.8.0
- `sftp` CLI (included with OpenSSH on most systems)
- `sshpass` (optional, only for password authentication)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "jofre/sftp.nvim",
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "jofre/sftp.nvim",
  config = function()
    require("sftp").setup()
  end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'jofre/sftp.nvim'

" In your init.lua or after/plugin:
lua require("sftp").setup()
```

## Configuration

### Plugin Setup

```lua
require("sftp").setup({
  -- Enable upload on save globally (default: true)
  upload_on_save = true,
  -- Suppress success notifications, only show errors (default: false)
  silent = false,
})
```

### Project Configuration

Create `.vscode/sftp.json` in your project root:

```json
{
  "name": "My Server",
  "host": "example.com",
  "port": 22,
  "username": "deploy",
  "remotePath": "/var/www/myproject",
  "uploadOnSave": true,
  "privateKeyPath": "~/.ssh/id_rsa",
  "ignore": [".vscode", ".git", ".DS_Store", "node_modules"]
}
```

#### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | `nil` | Display name for the connection |
| `host` | string | **required** | Remote server hostname or IP |
| `port` | number | `22` | SSH port |
| `username` | string | `nil` | SSH username |
| `password` | string | `nil` | SSH password (requires `sshpass`) |
| `privateKeyPath` | string | `nil` | Path to SSH private key |
| `remotePath` | string | `"/"` | Remote base directory |
| `uploadOnSave` | boolean | `true` | Auto-upload when saving files |
| `ignore` | string[] | `[".vscode", ".git", ".DS_Store"]` | Patterns to ignore |

> **Note:** If both `password` and `privateKeyPath` are set, password authentication takes precedence.

## Commands

| Command | Description |
|---------|-------------|
| `:SftpUpload` | Upload current file to remote server |
| `:SftpDownload` | Download current file from remote server |
| `:SftpTest` | Test connection to remote server |
| `:SftpStatus` | Show current SFTP configuration |
| `:SftpReload` | Reload configuration from `.vscode/sftp.json` |

## Lua API

```lua
local sftp = require("sftp")

-- Upload current buffer
sftp.upload()

-- Upload specific file with callback
sftp.upload("/path/to/file.lua", function(success, err)
  if success then
    print("Upload complete")
  else
    print("Error: " .. err)
  end
end)

-- Download current buffer
sftp.download()

-- Download specific file with callback
sftp.download("/path/to/file.lua", function(success, err)
  -- handle result
end)

-- Test connection
sftp.test_connection(function(success, err)
  -- handle result
end)

-- Get current project config
local config = sftp.get_config()
```

## Keymaps

The plugin does not set any keymaps by default. Example mappings:

```lua
vim.keymap.set("n", "<leader>su", "<cmd>SftpUpload<cr>", { desc = "SFTP Upload" })
vim.keymap.set("n", "<leader>sd", "<cmd>SftpDownload<cr>", { desc = "SFTP Download" })
vim.keymap.set("n", "<leader>st", "<cmd>SftpTest<cr>", { desc = "SFTP Test" })
vim.keymap.set("n", "<leader>ss", "<cmd>SftpStatus<cr>", { desc = "SFTP Status" })
```

## License

MIT
