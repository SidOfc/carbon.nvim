--- @alias carbon.settings.SidebarPosition 'left' | 'right'

--- @class carbon.settings.Settings
--- @field sync_pwd boolean
--- @field compress boolean
--- @field auto_open boolean
--- @field keep_netrw boolean
--- @field file_icons boolean
--- @field sync_on_cd boolean
--- @field sync_delay integer
--- @field open_on_dir boolean
--- @field auto_reveal boolean
--- @field sidebar_width integer
--- @field sidebar_toggle_focus boolean
--- @field sidebar_position carbon.settings.SidebarPosition
--- @field exclude string[]
--- @field indicators { expand: string, collapse: string }
--- @field flash { delay: integer, duration: integer }
--- @field float_settings fun(...): vim.api.keyset.win_config
--- @field actions table<string, boolean | string | string[]>
--- @field highlights table<string, vim.api.keyset.highlight>

--- @class carbon.settings.UserSettings : carbon.settings.Settings
--- @field sync_pwd? boolean
--- @field compress? boolean
--- @field auto_open? boolean
--- @field keep_netrw? boolean
--- @field file_icons? boolean
--- @field sync_on_cd? boolean
--- @field sync_delay? integer
--- @field open_on_dir? boolean
--- @field auto_reveal? boolean
--- @field sidebar_width? integer
--- @field sidebar_toggle_focus? boolean
--- @field sidebar_position? 'left' | 'right'
--- @field exclude? string[]
--- @field indicators? { expand: string, collapse: string }
--- @field flash? { delay: integer, duration: integer }
--- @field float_settings? fun(...): vim.api.keyset.win_config
--- @field actions? boolean | table<string, boolean | string | string[]>
--- @field highlights? boolean | table<string, vim.api.keyset.highlight>

--- @class carbon.settings.SettingsWithDefaults : carbon.settings.Settings
--- @field defaults carbon.settings.Settings

--- @type carbon.settings.Settings
local defaults = {
  sync_pwd = false,
  compress = true,
  auto_open = true,
  keep_netrw = false,
  file_icons = pcall(require, 'nvim-web-devicons') and true or false,
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
    local width = math.min(80, math.floor(columns * 0.9))
    local height = math.min(40, math.floor(rows * 0.9))

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
    tabe = '<c-t>',
    edit = '<cr>',
    move = 'm',
    reset = 'u',
    split = { '<c-x>', '<c-s>' },
    vsplit = '<c-v>',
    create = { 'c', '%' },
    delete = 'd',
    close_parent = '-',
    toggle_hidden = '*',
    toggle_recursive = '!',
  },
  highlights = {
    CarbonDir = { link = 'Directory' },
    CarbonFile = { link = 'Text' },
    CarbonExe = { link = '@function.builtin' },
    CarbonSymlink = { link = '@include' },
    CarbonBrokenSymlink = { link = 'DiagnosticError' },
    CarbonIndicator = { fg = 'Gray', ctermfg = 'DarkGray', bold = true },
    CarbonFloat = { bg = '#111111', ctermbg = 'black' },
    CarbonFloatBorder = { link = 'CarbonFloat' },
    CarbonDanger = { link = 'Error' },
    CarbonPending = { link = 'Search' },
    CarbonFlash = { link = 'Visual' },
  },
}

---@type carbon.settings.SettingsWithDefaults
return vim.tbl_extend('force', vim.deepcopy(defaults), { defaults = defaults })
