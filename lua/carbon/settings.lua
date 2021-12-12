local settings = {
  auto_open = true,
  disable_netrw = true,
  create_mappings = true,
  highlight_groups = {
    CarbonDir = {
      ctermfg = 'DarkBlue',
      guifg = '#00aaff',
      cterm = 'bold',
      gui = 'bold',
    },
    CarbonFile = {
      ctermfg = 'LightGray',
      guifg = '#f8f8f8',
      cterm = 'bold',
      gui = 'bold',
    },
    CarbonExe = {
      ctermfg = 'Green',
      guifg = '#22cc22',
      cterm = 'bold',
      gui = 'bold',
    },
    CarbonSymlink = {
      ctermfg = 'Magenta',
      guifg = '#d77ee0',
      cterm = 'bold',
      gui = 'bold',
    },
    CarbonBrokenSymlink = {
      ctermfg = 'Brown',
      guifg = '#ea871e',
      cterm = 'bold',
      gui = 'bold',
    },
    CarbonIndicator = {
      ctermfg = 'DarkGray',
      guifg = 'Gray',
      cterm = 'bold',
      gui = 'bold',
    },
    CarbonIndicatorSelected = {
      ctermfg = 'Red',
      guifg = 'Red',
      cterm = 'bold',
      gui = 'bold',
    },
    CarbonIndicatorPartial = {
      ctermfg = 'Yellow',
      guifg = 'Yellow',
      cterm = 'bold',
      gui = 'bold',
    },
  },
}

function settings.extend(user_settings)
  local next = vim.tbl_deep_extend('force', settings, user_settings or {})

  for setting, value in pairs(next) do
    settings[setting] = value
  end

  return next
end

return settings
