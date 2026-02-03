# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

sftp.nvim is a Neovim plugin that provides SFTP file synchronization, designed to be compatible with the VSCode SFTP extension configuration format (`.vscode/sftp.json`).

## Development

### Testing the Plugin Locally

```lua
-- Add to runtimepath and load
vim.opt.runtimepath:prepend('/home/jofre/projects/sftp.nvim')
require('sftp').setup({})
```

### Reloading During Development

```lua
-- Clear all module cache and reload
for name, _ in pairs(package.loaded) do
  if name:match("^sftp") then
    package.loaded[name] = nil
  end
end
require('sftp').setup({})
```

### Testing Commands

After loading, test with:
- `:SftpStatus` - Verify configuration is detected
- `:SftpTest` - Test connection to remote server
- `:SftpUpload` / `:SftpDownload` - Manual file transfer

## Architecture

```
lua/sftp/
├── init.lua     -- Entry point, setup(), autocmds for upload-on-save
├── config.lua   -- Project config loading from .vscode/sftp.json
├── sftp.lua     -- Core SFTP operations (upload/download via sftp CLI)
└── commands.lua -- User command registration (:SftpUpload, etc.)
```

### Module Responsibilities

**init.lua**: Plugin entry point. Creates `SftpAutoUpload` augroup with three autocmds:
- `BufWritePost` - triggers upload on save
- `FocusGained` - runs `:checktime` for external change detection
- `FileChangedShellPost` - uploads after external changes are reloaded

**config.lua**: Finds project root by searching upward for `.vscode/sftp.json`. Caches config per project. Provides `get_remote_path()` to map local paths to remote paths and `should_ignore()` for ignore pattern matching.

**sftp.lua**: Builds sftp CLI commands. Supports password auth via `sshpass` or key-based auth via `-i`. Uses `vim.fn.jobstart()` for async execution with batch mode (`-b -`).

**commands.lua**: Registers five user commands: `SftpUpload`, `SftpDownload`, `SftpTest`, `SftpStatus`, `SftpReload`.

### Configuration Format

The plugin reads `.vscode/sftp.json` (VSCode SFTP extension compatible):

```json
{
  "name": "My Server",
  "host": "example.com",
  "port": 22,
  "username": "user",
  "remotePath": "/var/www/project",
  "uploadOnSave": true,
  "privateKeyPath": "~/.ssh/id_rsa",
  "ignore": [".vscode", ".git", ".DS_Store"]
}
```

### External Dependencies

- `sftp` CLI (standard on most systems)
- `sshpass` (only if using password authentication)
