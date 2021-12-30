vim.opt.runtimepath:append({ vim.fn.getcwd() })
vim.opt.runtimepath:remove({ vim.env.HOME .. '/.config/nvim' })
vim.opt.packpath:remove({ vim.env.HOME .. '/.local/share/nvim/site' })
