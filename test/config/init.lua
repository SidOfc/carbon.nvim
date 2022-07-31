local repo_root = vim.loop.cwd()
local test_util = require('test.config.util')
local tmp_dir = vim.fn.tempname()

test_util.copy(repo_root, tmp_dir)
vim.fn.chdir(tmp_dir)

vim.api.nvim_create_autocmd('VimLeavePre', {
  pattern = '*',
  callback = function()
    vim.fn.chdir(repo_root)
    vim.fn.delete(tmp_dir, 'rf')
  end,
})
