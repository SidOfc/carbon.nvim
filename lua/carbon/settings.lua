local defaults = {
  sync_pwd = false,
  compress = true,
  auto_open = true,
  keep_netrw = false,
  sync_on_cd = not vim.opt.autochdir:get(),
  sync_delay = 20,
  sidebar_width = 30,
  always_reveal = false,
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
  flash = {
    delay = 50,
    duration = 500,
  },
  float_settings = function()
    local columns = vim.opt.columns:get()
    local rows = vim.opt.lines:get()
    local width = math.min(50, math.floor(columns * 0.8))
    local height = math.min(20, math.floor(rows * 0.8))

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
    quit = 'q',
    edit = '<cr>',
    move = 'm',
    reset = '.',
    split = '<c-x>',
    vsplit = '<c-v>',
    create = 'c',
    delete = 'd',
    close_parent = '-',
    toggle_recursive = '!',
  },
  highlights = {
    CarbonDir = { link = 'Directory' },
    CarbonFile = { link = 'Text' },
    CarbonExe = { fg = '#22cc22', ctermfg = 'Green', bold = true },
    CarbonSymlink = { fg = '#d77ee0', ctermfg = 'Magenta', bold = true },
    CarbonBrokenSymlink = { fg = '#ea871e', ctermfg = 'Brown', bold = true },
    CarbonIndicator = { fg = 'Gray', ctermfg = 'DarkGray', bold = true },
    CarbonDanger = { fg = '#ff3333', ctermfg = 'Red', bold = true },
    CarbonPending = { fg = '#ffee00', ctermfg = 'Yellow', bold = true },
    CarbonFlash = { link = 'Visual' },
  },
}

return vim.tbl_extend('force', vim.deepcopy(defaults), { defaults = defaults })
