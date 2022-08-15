vim.env.CARBON_REPO_ROOT = vim.loop.cwd()

local test_options = { minimal_init = 'test/config/init.lua' }
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

if vim.env.only then
  for spec in vim.fs.dir('test/specs') do
    if string.find(spec, vim.env.only) then
      return require('plenary.test_harness').test_directory(
        string.format('test/specs/%s', spec),
        test_options
      )
    end
  end
else
  return require('plenary.test_harness').test_directory(
    'test/specs',
    test_options
  )
end
