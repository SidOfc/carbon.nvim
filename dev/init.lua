vim.opt.termguicolors = true
vim.opt.packpath:remove({ vim.env.HOME .. '/.local/share/nvim/site' })
vim.opt.runtimepath:remove({ vim.env.HOME .. '/.config/nvim' })
vim.opt.runtimepath:append({
  vim.env.HOME .. '/Dev/sidofc/lua/carbon.nvim',
  vim.env.HOME .. '/.local/share/nvim/site/pack/packer/start/nvim-web-devicons',
})

require('carbon').setup({ file_icons = false })
