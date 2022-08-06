local constants = require('carbon.constants')
local helpers = {}

function helpers.autocmd(event, options)
  return vim.api.nvim_get_autocmds({
    group = constants.augroup,
    event = event,
    buffer = options and options.buffer,
  })[1] or {}
end

return helpers
