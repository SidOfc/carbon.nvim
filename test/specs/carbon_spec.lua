local ns = require('carbon.ns')
local util = require('carbon.util')
local settings = require('carbon.settings')

local function cwd_dirname()
  return vim.fn.fnamemodify(vim.loop.cwd(), ':t') .. '/'
end

local function get_carbon_autocmd(event)
  return vim.api.nvim_get_autocmds({
    group = ns.augroup,
    event = event,
  })[1] or {}
end

describe('carbon', function()
  it('opens a buffer with name "carbon"', function()
    assert.equal('carbon', vim.fn.bufname())
  end)

  it('opens a buffer with filetype "carbon"', function()
    assert.equal('carbon', vim.o.filetype)
    assert.equal('carbon', vim.bo.filetype)
  end)

  it('displays the contents of the current directory', function()
    assert.same({
      cwd_dirname(),
      '  dev/init.lua',
      '+ doc/',
      '+ lua/',
      '  plugin/carbon.vim',
      '+ test/',
      '  .luacheckrc',
      '  LICENSE.md',
      '  Makefile',
      '  README.md',
      '  stylua.toml',
    }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
  end)

  describe('default autocommands', function()
    describe('DirChanged', function()
      local autocmd = get_carbon_autocmd('DirChanged')

      it('exists', function()
        assert.is_number(autocmd.id)
      end)

      it('not buffer local', function()
        assert.is_false(autocmd.buflocal)
      end)

      it('pattern is global', function()
        assert.is_same('global', autocmd.pattern)
      end)
    end)
  end)

  describe('plug mappings', function()
    for action in pairs(settings.actions) do
      local plug = util.plug(action)

      it(string.format('maps %s to carbon.%s()', plug, action), function()
        assert.is_number(
          string.find(string.lower(vim.fn.maparg(plug, 'n')), '<lua %w+')
        )
      end)
    end
  end)

  describe('action mappings', function()
    for action, key in pairs(settings.actions) do
      local plug = util.plug(action)

      it(string.format('maps %s to %s', key, plug), function()
        assert.same(string.lower(vim.fn.maparg(key, 'n')), plug)
      end)
    end
  end)
end)
