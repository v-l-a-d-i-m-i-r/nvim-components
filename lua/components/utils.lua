local M = {}

---@class Utils
---@field cli_pipe fun(commands_table: string[]): string
---@field cli_and fun(commands_table: string[]): string
---@field clone_git_repo fun(params: {url: string, commit?: string, tag?: string}): string?
---@field clone_git_repo_at_commit fun(params: {url: string, commit: string}): string
---@field clone_git_repo_at_tag fun(params: {url: string, tag: string}): string

---@param commands_table string[]
---@return string
M.cli_pipe = function(commands_table)
  return table.concat(commands_table, ' | ')
end

---@param commands_table string[]
---@return string
M.cli_and = function(commands_table)
  return table.concat(commands_table, ' && ')
end

---@param params {url: string, commit?: string, tag?: string}
---@return string?
M.clone_git_repo = function(params)
  local url = params.url
  local commit = params.commit
  local tag = params.tag

  if commit ~= nil then
    return 'git clone ' .. url .. ' . && git reset --hard ' .. commit
  end

  if tag ~= nil then
    return 'git clone --depth 1 --branch ' .. tag .. ' ' .. url .. ' .'
  end
end

---@param params {url: string, commit: string}
---@return string
M.clone_git_repo_at_commit = function(params)
  local url = params.url
  local commit = params.commit

  return 'git clone ' .. url .. ' . && git reset --hard ' .. commit
end

---@param params {url: string, tag: string}
---@return string
M.clone_git_repo_at_tag = function(params)
  local url = params.url
  local tag = params.tag

  return 'git clone --depth 1 --branch ' .. tag .. ' ' .. url .. ' .'
end

return M
