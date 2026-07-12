vim.env.CARBON_REPO_ROOT = vim.uv.cwd()

local test_options = { minimal_init = 'test/config/init.lua' }
local plugin_repo = 'https://github.com/nvim-lua/plenary.nvim'
local plugin_path = string.format(
  '%s/site/pack/packer/start/plenary.nvim',
  vim.fn.stdpath('data')
)

if not vim.uv.fs_stat(plugin_path) then
  print('INFO: installing plenary.nvim...')
  vim.fn.mkdir(plugin_path, 'p')
  vim.system({ 'git', 'clone', plugin_repo, plugin_path }):wait()
  print('INFO: installed plenary.nvim')
end

vim.opt.runtimepath:prepend(plugin_path)

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
