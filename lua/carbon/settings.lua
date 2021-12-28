return {
  compress = true,
  auto_open = true,
  keep_netrw = false,
  sync_on_cd = not vim.opt.autochdir:get(),
  sync_delay = 30,
  indicators = {
    expand = '+',
    collapse = '-',
  },
  actions = {
    up = '-',
    down = '=',
    edit = '<cr>',
    split = '<c-x>',
    vsplit = '<c-v>',
  },
  exclude = {
    '~$',
    '#$',
    '%.git$',
    '%.bak$',
    '%.rbc$',
    '%.class$',
    '%.sw[a-p]$',
    '%.py[cod]$',
    '%.Trashes$',
    '%.DS_Store$',
    'Thumbs%.db$',
    '__pycache__',
    'node_modules',
  },
  highlights = {
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
  },
}
