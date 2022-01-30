return {
  compress = true,
  auto_open = true,
  keep_netrw = false,
  sync_on_cd = not vim.opt.autochdir:get(),
  sync_delay = 30,
  sidebar_width = 30,
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
  indicators = {
    expand = '+',
    collapse = '-',
  },
  float_settings = function()
    local columns = vim.opt.columns:get()
    local rows = vim.opt.lines:get()
    local width = math.min(50, columns * 0.8)
    local height = math.min(20, rows * 0.8)

    return {
      relative = 'editor',
      style = 'minimal',
      border = 'single',
      width = width,
      height = height,
      col = math.floor(columns / 2 - width / 2),
      row = math.floor(rows / 2 - height / 2 - 2),
    }
  end,
  actions = {
    up = '[',
    down = ']',
    edit = '<cr>',
    reset = '.',
    split = '<c-x>',
    vsplit = '<c-v>',
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
