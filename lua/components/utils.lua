local M = {}

M.cli_pipe = function(commands_table)
  return table.concat(commands_table, ' | ')
end

M.cli_and = function(commands_table)
  return table.concat(commands_table, ' && ')
end

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

return M
