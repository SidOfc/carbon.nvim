local plenary_repo = 'https://github.com/nvim-lua/plenary.nvim'
local plenary_path = string.format(
  '%s/site/pack/packer/start/plenary.nvim',
  vim.fn.stdpath('data')
)

if vim.fn.isdirectory(plenary_path) == 0 then
  print('INFO: installing plenary.nvim...')
  vim.fn.mkdir(plenary_path, 'p')
  vim.fn.system(string.format('git clone %s %s', plenary_repo, plenary_path))
  print('INFO: installed plenary.nvim')
end

vim.opt.runtimepath:prepend(plenary_path)
require('plenary.test_harness').test_directory(
  'test/specs',
  { minimal_init = 'test/config/init.lua' }
)
