local md5 = require('md5')

---@class Params
---@field components_path string
--@field lazy_install boolean

---@type Params
local params = {
  components_path = 'not specified',
  lazy_install = false,
}

---@type string[]
local components_names_list = {}

---@type { [string]: Component }
local components = {}

---@class ComponentOptions
---@field name string
---@field install_script fun(): string
---@field binaries_directory? string
---@field on_init? fun()

---@class Component
---@field get_name fun(): string
---@field install fun()
---@field init fun()
---@field bin fun(binary_name: string): string
---@field clear fun()
---@field check_installed fun(): boolean

---@param options ComponentOptions
---@return Component
local function Component(options)
  local name = options.name
  local install_script_string = options.install_script()
  local hash = md5.sumhexa(install_script_string)
  local installation_path = params.components_path .. '/' .. name .. '-' .. hash
  local binaries_directory = table.concat({
    installation_path,
    options.binaries_directory or '/',
  }, '')

  return {
    get_name = function()
      return name
    end,

    install = function()
      local command_table = {
        '! mkdir -p ' .. installation_path,
        'cd ' .. installation_path,
        install_script_string,
      }

      vim.cmd(table.concat(command_table, ' && '))
    end,

    init = function()
      if options.on_init then
        options.on_init()
      end
    end,

    bin = function(binary_name)
      if binary_name == nil or binary_name == '' then
        return binaries_directory
      else
        return binaries_directory .. '/' .. binary_name
      end
    end,

    clear = function()
      vim.cmd('! rm -rf ' .. installation_path)
    end,

    check_installed = function()
      if os.execute('! test -d ' .. binaries_directory) ~= 0 then
        return true
      else
        return false
      end
    end,
  }
end

local M = {}

---@param p Params
M.setup = function(p)
  params = p
end

M.install_components = function()
  for _, component_name in ipairs(components_names_list) do
    ---@type Component
    local component = components[component_name]
    local is_component_installed = component.check_installed()

    if not is_component_installed then
      print('Installing ' .. component_name)
      component.clear()
      component.install()
    else
      print(component_name .. ' already installed')
    end
  end
end

---@param name string
--@return Component
M.get_component = function(name)
  return components[name]
end

---@param options ComponentOptions
M.add_component = function(options)
  ---@type Component
  local component = Component(options)
  local component_name = component.get_name()
  local is_component_installed = component.check_installed()

  if params.lazy_install and not is_component_installed then
    component.clear()
    component.install()
  end

  table.insert(components_names_list, component_name)
  components[component_name] = component

  component.init()
end

---@param name string
M.load_plugin = function(name)
  local path = M.get_component(name).bin('')
  local rtp = path:sub(1, string.len(path) - 1)
  local after = rtp .. '/after'
  local doc_dir = rtp .. '/doc'
  local tags_file = doc_dir .. '/tags'

  vim.opt.rtp:append(rtp)

  local after_stat = vim.loop.fs_stat(after)
  if after_stat and after_stat.type == 'directory' then
    vim.opt.rtp:append(after)
  end

  local doc_dir_stat = vim.loop.fs_stat(doc_dir)
  if not (doc_dir_stat and doc_dir_stat.type == 'directory') then
    return
  end

  local tags_file_stat = vim.loop.fs_stat(tags_file)
  if tags_file_stat and tags_file_stat.type == 'file' then
    return
  end

  vim.cmd("silent! execute 'helptags' '" .. doc_dir .. "/'")
end

return M
