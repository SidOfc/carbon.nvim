local defaults = {
  sync_pwd = false,
  compress = true,
  auto_open = true,
  keep_netrw = false,
  sync_on_cd = not vim.opt.autochdir:get(),
  sync_delay = 20,
  sidebar_width = 30,
  sidebar_toggle_focus = true,
  sidebar_position = 'left',
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
    reset = 'u',
    split = { '<c-x>', '<c-s>' },
    vsplit = '<c-v>',
    create = { 'c', '%' },
    delete = 'd',
    close_parent = '-',
    toggle_recursive = '!',
  },
  highlights = {
    CarbonDir = { link = 'Directory' },
    CarbonFile = { link = 'Text' },
    CarbonExe = { link = 'NetrwExe' },
    CarbonSymlink = { link = 'NetrwSymLink' },
    CarbonBrokenSymlink = { link = 'ErrorMsg' },
    CarbonIndicator = { fg = 'Gray', ctermfg = 'DarkGray', bold = true },
    CarbonDanger = { link = 'Error' },
    CarbonPending = { link = 'Search' },
    CarbonFlash = { link = 'Visual' },
  },
}

return vim.tbl_extend('force', vim.deepcopy(defaults), { defaults = defaults })
