# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Neovim plugin written in Lua that provides SFTP functionality. The plugin follows standard Neovim plugin conventions.

## Development

### Testing the Plugin Locally

Load the plugin in Neovim by adding the project directory to the runtime path:

```lua
-- In Neovim or init.lua
vim.opt.runtimepath:prepend('/home/jofre/projects/sftp')
require('sftp').setup({})
```

Or use a plugin manager like lazy.nvim with a local path:

```lua
{ dir = '/home/jofre/projects/sftp' }
```

### Reloading During Development

To reload changes without restarting Neovim:

```lua
package.loaded['sftp'] = nil
package.loaded['sftp.init'] = nil
require('sftp').setup({})
```

## Architecture

The plugin uses the standard Neovim Lua plugin structure:

- `lua/sftp/init.lua` - Main module entry point with `setup()` function for configuration
- Additional modules should be added under `lua/sftp/` and required from `init.lua`

### Configuration Pattern

The plugin uses the common Neovim pattern of merging user options with defaults via `vim.tbl_deep_extend("force", M.config, opts)`.
