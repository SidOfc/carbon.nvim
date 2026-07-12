local plugin_repo = 'https://github.com/nvim-mini/mini.doc'
local plugin_path =
  string.format('%s/site/pack/packer/start/mini.doc', vim.fn.stdpath('data'))

if not vim.uv.fs_stat(plugin_path) then
  print('INFO: installing mini.doc...')
  vim.fn.mkdir(plugin_path, 'p')
  vim.system({ 'git', 'clone', plugin_repo, plugin_path }):wait()
  print('INFO: installed mini.doc')
end

vim.opt.runtimepath:prepend(plugin_path)
local mini_doc = require('mini.doc')
local doc_config = { hooks = {} }
local indent_sizes = { header = 4, content = 8 }

local function fmt_section_header(ctx, section_id, callback, ...)
  if not ctx.skip_headers[section_id] then
    ctx.skip_headers[section_id] = true

    callback(...)
  end
end

local function indent_line(line, indent)
  return string.format(
    '%s%s',
    string.rep(' ', indent),
    string.gsub(line, '^%s+', '')
  )
end

local function indent_section(section, indent)
  for idx = 1, #section do
    section[idx] = indent_line(section[idx], indent)
  end

  return section
end

function doc_config.annotation_extractor(line)
  return string.find(line, '^%-%-%- (%S*) ?')
end

function doc_config.hooks.block_post(block)
  local ctx = { skip_headers = {} }
  local section_fns = {
    ['@signature'] = function()
      ctx.skip_headers = {}
    end,
    ['@class'] = function(section)
      fmt_section_header(ctx, '@class', function()
        section[1] = ''
        section[2] = indent_line(section[2], indent_sizes.content)
        table.insert(section, 2, indent_line('Class: ~', indent_sizes.header))
      end)
    end,
    ['@field'] = function(section)
      indent_section(section, indent_sizes.content)
      fmt_section_header(ctx, '@field', function()
        table.insert(section, 1, '')
        table.insert(section, 2, indent_line('Fields: ~', indent_sizes.header))
      end)
    end,
    ['@param'] = function(section)
      indent_section(section, indent_sizes.content)
      fmt_section_header(ctx, '@param', function()
        table.insert(section, 1, '')
        table.insert(
          section,
          2,
          indent_line('Parameters: ~', indent_sizes.header)
        )
      end)
    end,
    ['@return'] = function(section)
      indent_section(section, indent_sizes.content)
      fmt_section_header(ctx, '@return', function()
        section[1] = ''
        table.insert(section, 2, indent_line('Return: ~', indent_sizes.header))
      end)
    end,
  }

  for _, section in ipairs(block) do
    vim.print(section.info.id)

    if section_fns[section.info.id] then
      section_fns[section.info.id](section)
    end
  end

  return block
end

mini_doc.setup(doc_config)
mini_doc.generate(
  { 'lua/carbon/init.lua', 'lua/carbon/entry.lua' },
  'doc/doc_generated.txt'
)
