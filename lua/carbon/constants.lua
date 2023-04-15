return {
  hl = vim.api.nvim_create_namespace('carbon'),
  hl_tmp = vim.api.nvim_create_namespace('carbon:tmp'),
  augroup = vim.api.nvim_create_augroup('carbon', { clear = false }),
  directions = { left = 'h', right = 'l', up = 'k', down = 'j' },
}
