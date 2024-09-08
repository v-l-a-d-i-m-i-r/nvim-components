local md5 = require('md5')

local params = {
  components_path = 'not specified',
  lazy_install = false,
}
local components_names_list = {}
local components = {}

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

local setup = function(p)
  params = p
end

local install_components = function()
  for _, component_name in ipairs(components_names_list) do
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

local get_component = function(name)
  return components[name]
end

local add_component = function(options)
  local component = Component(options)
  local component_name = component.get_name()
  local is_component_installed = component.check_installed()

  if params.lazy_install and not is_component_installed then
    component.clear()
    component.install()
  end

  table.insert(components_names_list, component_name)
  components[component_name] = component
end

return {
  setup = setup,
  install_components = install_components,
  add_component = add_component,
  get_component = get_component,
}
