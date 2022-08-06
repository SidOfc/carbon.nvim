local repo_root = vim.loop.cwd()
local tmp_dir = vim.fn.tempname()

vim.opt.runtimepath:prepend(repo_root)

vim.fn.system(string.format('cp -R %s %s', repo_root, tmp_dir))
vim.fn.chdir(tmp_dir)

require('carbon').initialize()

vim.api.nvim_create_autocmd('VimLeavePre', {
  pattern = '*',
  callback = function()
    vim.fn.chdir(repo_root)
    vim.fn.delete(tmp_dir, 'rf')
  end,
})
