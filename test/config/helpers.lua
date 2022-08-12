local entry = require('carbon.entry')
local constants = require('carbon.constants')
local helpers = {}

function helpers.type_keys(keys_to_type)
  return vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys_to_type, true, false, true),
    'x',
    true
  )
end

function helpers.autocmd(event, options)
  return vim.api.nvim_get_autocmds({
    group = constants.augroup,
    event = event,
    buffer = options and options.buffer,
  })[1] or {}
end

function helpers.entry(relative_path)
  return entry.find(string.format('%s/%s', vim.loop.cwd(), relative_path))
end

return helpers
