local defaults = {
  sync_pwd = false,
  compress = true,
  auto_open = true,
  keep_netrw = false,
  sync_on_cd = not vim.opt.autochdir:get(),
  sync_delay = 20,
  open_on_dir = true,
  auto_reveal = false,
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
  flash = {
    delay = 50,
    duration = 500,
  },
  float_settings = function()
    local columns = vim.opt.columns:get()
    local rows = vim.opt.lines:get()
    local width = math.min(40, math.floor(columns * 0.9))
    local height = math.min(20, math.floor(rows * 0.9))

    return {
      relative = 'editor',
      style = 'minimal',
      border = 'rounded',
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
    CarbonFloat = { bg = '#111111', ctermbg = 'black' },
    CarbonFlash = { link = 'Visual' },
  },
}

return vim.tbl_extend('force', vim.deepcopy(defaults), { defaults = defaults })
