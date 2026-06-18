# nvim-components

A modular Lua-based component manager for Neovim. This project provides a mechanism to define, install, and manage components or plugins based on custom scripts, with support for dependency isolation and automated cleanup.

## Features

- **Component-based architecture**: Define individual components with installation logic.
- **Binary path management**: Access installed binaries from structured paths.
- **Customizable setup**: Configure the component system with a user-defined root path.
- **Component cleanup**: Remove stale component directories that are no longer registered.
- **Sync**: Install missing components and clean up unused ones in a single call.
- **Reusable utilities**: Includes helper functions to chain CLI commands using `|` or `&&`.

## Usage

1. **Setup the component manager**:
   ```lua
    local components_path = NVIM_CONFIG_ROOT .. '/components' -- add this folder to .gitignore
    local components_plugin_url = 'https://github.com/v-l-a-d-i-m-i-r/nvim-components'
    local components_plugin_commit = '21711de1320811f0ccdd67789a945c6f56edf718' -- actual commit hash
    local components_plugin_path = components_path .. '/components-nvim-' .. components_plugin_commit

    if not (vim.uv or vim.loop).fs_stat(components_plugin_path) then
      local command = {
        'git clone ' .. components_plugin_url .. ' ' .. components_plugin_path,
        'cd ' .. components_plugin_path,
        'git reset --hard ' .. components_plugin_commit,
      }

      vim.cmd('! ' .. table.concat(command, ' && '))
    end

    vim.opt.rtp:append(components_plugin_path)

    local components = require('components')

    components.setup({
      components_path = components_path,
      -- Directory name of this plugin inside components_path (used by clean_up_components
      -- to preserve it when removing stale directories).
      self_name = 'components-nvim-' .. components_plugin_commit,
    })
   ```

2. **Add a new component**:
   ```lua
   components.add_component({
     name = 'example',
     install_script = function()
       return "git clone https://github.com/example/plugin.git ."
     end,
     binaries_directory = "/bin",
     on_init = function()
       print("Initialized example plugin")
     end
   })
   ```

3. **Install all components**:
   ```vim
   :ComponentsInstall
   ```

4. **Clean up stale component directories** (removes directories under `components_path` that are not associated with any registered component, preserving the plugin's own directory):
   ```vim
   :ComponentsCleanUp
   ```

5. **Sync** (install missing + remove stale in one call):
   ```vim
   :ComponentsSync
   ```


## Utility Functions Usage

The `utils.lua` module provides helper functions to build command-line strings by joining commands with pipes (`|`) or logical AND (`&&`). It also includes a utility to generate Git clone commands with optional `commit` or `tag` parameters.

### `cli_pipe(commands_table: string[]): string`

Joins a list of shell commands using `|`, useful for creating pipelines.

```lua
local utils = require('components.utils')

local pipeline_command = utils.cli_pipe({
  "cat file.txt",
  "grep 'error'",
  "sort"
})

print(pipeline_command)
-- Output: cat file.txt | grep 'error' | sort
```

### `cli_and(commands_table: string[]): string`

Joins a list of shell commands using `&&`, ensuring sequential execution only if the previous command succeeds.

```lua
local utils = require('components.utils')

local sequential_command = utils.cli_and({
  "echo 'Starting build'",
  "make",
  "make install"
})

print(sequential_command)
-- Output: echo 'Starting build' && make && make install
```

### `clone_git_repo(params: { url: string, commit?: string, tag?: string }): string?`

Generates a Git command string to clone a repository, optionally checking out a specific commit or tag. Returns `nil` when neither `commit` nor `tag` is provided and the clone command cannot be constructed.

```lua
local utils = require('components.utils')

-- Clone specific commit
local clone_commit_cmd = utils.clone_git_repo({
  url = "https://github.com/example/project.git",
  commit = "abc123def"
})

print(clone_commit_cmd)
-- Output: git clone https://github.com/example/project.git . && git reset --hard abc123def

-- Clone specific tag
local clone_tag_cmd = utils.clone_git_repo({
  url = "https://github.com/example/project.git",
  tag = "v1.0.0"
})

print(clone_tag_cmd)
-- Output: git clone --depth 1 --branch v1.0.0 https://github.com/example/project.git .
```

## Examples

### Adding a Binary Component (Go)

```lua
local c = require('components')
local u = require('components.utils')

c.add_component({
  name = 'go',
  binaries_directory = '/bin',
  install_script = function()
    local version = '1.18.2'

    return u.cli_pipe({
      'curl -L https://go.dev/dl/go' .. version .. '.linux-amd64.tar.gz',
      'tar -xz --strip=1',
    })
  end,
})

c.add_component({
  name = 'gotools',
  binaries_directory = '/bin',
  install_script = function()
    local version = '0.12.4'

    return u.cli_and({
      'git clone --depth 1 --branch gopls/v' .. version .. '  https://github.com/golang/tools.git .',
      'cd ./gopls',
      c.get_component('go').bin('go') .. ' build -o ../bin/gopls',
    })
  end,
})
```

Then binary can be accessed via `get_component(<component_name>).bin(<binary_name>)`
```lua
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.go',
  callback = function()
    local gopls = c.get_component('gotools').bin('gopls')
    local gofmt = c.get_component('go').bin('gofmt')
    local current_buffer_path = vim.fn.expand('%:p')

    vim.cmd('silent !' .. gopls .. ' imports -w ' .. current_buffer_path)
    vim.cmd('silent !' .. gofmt .. ' -w ' .. current_buffer_path)
  end,
})
```

### Adding an Nvim Plugin Component (Lualine)

```lua
local c = require('components')
local u = require('components.utils')

c.add_component({
  name = 'lualine',
  install_script = function()
    return u.clone_git_repo({
      url = 'https://github.com/nvim-lualine/lualine.nvim',
      commit = 'de2c4beaf50552647273b5eaa33095e90a6d00a0',
    })
  end,
  on_init = function()
    c.load_plugin('lualine')
    require('lualine-setup')
  end,
})
```

## License

MIT

## Credits

- Includes [md5.lua](https://github.com/kikito/md5.lua) by kikito and contributors for local MD5 hashing.
