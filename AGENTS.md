# Repository Guidelines

## Project Structure & Module Organization
Core plugin code lives in `lua/sftp/`:
- `init.lua`: entry point (`setup`), autocmd lifecycle, and public API passthroughs.
- `config.lua`: project discovery and `.vscode/sftp.json` parsing/caching.
- `sftp.lua`: async upload/download/test logic using `sftp`/`sshpass`.
- `commands.lua`: user commands (`:SftpUpload`, `:SftpTest`, etc.).
- `watcher.lua`: file-system watcher and debounced auto-upload.

Repository docs are in `README.md`; implementation notes for agent workflows are in `CLAUDE.md`.

## Build, Test, and Development Commands
This plugin has no build step. Use Neovim for local development:
- `nvim --clean` then in Lua: `vim.opt.runtimepath:prepend('/home/jofre/projects/sftp.nvim')`
- `:lua require('sftp').setup({})`: initialize plugin.
- `:SftpStatus`: verify config/project detection.
- `:SftpTest`: validate remote connectivity.
- `:SftpUpload` / `:SftpDownload`: validate transfer behavior.

Reload during iteration:
```lua
for name, _ in pairs(package.loaded) do
  if name:match('^sftp') then package.loaded[name] = nil end
end
require('sftp').setup({})
```

## Coding Style & Naming Conventions
- Language: Lua (Neovim API + `vim.uv`).
- Indentation: 2 spaces; keep functions small and module-scoped.
- Naming: snake_case for locals/functions (`build_sftp_cmd`, `should_ignore`); module tables use `local M = {}`.
- Prefer explicit error notifications (`vim.notify`) and non-blocking operations (`vim.fn.jobstart`).
- Keep comments concise and explain intent, not syntax.

## Testing Guidelines
There is currently no automated test suite in this repository. Validate changes with manual Neovim scenarios:
- both auth paths (SSH key and password via `sshpass`),
- upload-on-save behavior,
- watcher start/stop and external file change handling,
- config reload (`:SftpReload`) and ignore-pattern behavior.

## Commit & Pull Request Guidelines
Current history uses short, direct commit subjects (for example, `updated readme`). Follow that style with imperative, scope-aware messages (for example, `add watcher debounce guard`).

For PRs, include:
- a brief problem/solution summary,
- reproduction and verification steps (commands used),
- config snippets or terminal output when behavior depends on `.vscode/sftp.json`.
