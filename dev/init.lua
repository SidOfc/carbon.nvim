vim.opt.termguicolors = true
vim.opt.runtimepath:append({ vim.env.HOME .. '/Dev/sidofc/lua/carbon.nvim' })
vim.opt.runtimepath:remove({ vim.env.HOME .. '/.config/nvim' })
vim.opt.packpath:remove({ vim.env.HOME .. '/.local/share/nvim/site' })

require('carbon').setup({ sync_pwd = true, auto_reveal = true })
