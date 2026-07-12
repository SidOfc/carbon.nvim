local repo_root = vim.uv.cwd()
local tmp_dir = vim.fn.tempname()

vim.opt.runtimepath:prepend(tmp_dir)

vim.system({ 'cp', '-R', repo_root, tmp_dir }):wait()
vim.fn.chdir(tmp_dir)

require('carbon').setup()

vim.api.nvim_create_autocmd('VimLeavePre', {
  pattern = '*',
  callback = function()
    if repo_root then
      vim.fn.chdir(repo_root)
      vim.fs.rm(tmp_dir, { recursive = true })
    end
  end,
})
