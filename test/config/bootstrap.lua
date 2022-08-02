local fmt = '%s/site/pack/packer/start/plenary.nvim'

vim.opt.runtimepath:prepend(string.format(fmt, vim.fn.stdpath('data')))
require('plenary.test_harness').test_directory(
  'test/specs',
  { minimal_init = 'test/config/init.lua' }
)
