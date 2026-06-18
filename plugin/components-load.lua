vim.cmd("command! ComponentsInstall lua require('components').install_components()")
vim.cmd("command! ComponentsCleanUp lua require('components').clean_up_components()")
vim.cmd("command! ComponentsSync lua require('components').sync_components()")
