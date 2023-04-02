local defaults = {
  sync_pwd = false,
  compress = true,
  auto_open = true,
  keep_netrw = false,
  file_icons = pcall(require, 'nvim-web-devicons'),
  sync_on_cd = not vim.opt.autochdir:get(),
  sync_delay = 20,
  open_on_dir = true,
  auto_reveal = false,
  sidebar_width = 30,
  sidebar_toggle_focus = true,
  sidebar_position = 'left',
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
    CarbonFloat = { bg = '#111111', ctermbg = 'black' },
    CarbonDanger = { link = 'Error' },
    CarbonPending = { link = 'Search' },
    CarbonFlash = { link = 'Visual' },
  },
}

return vim.tbl_extend('force', vim.deepcopy(defaults), { defaults = defaults })
