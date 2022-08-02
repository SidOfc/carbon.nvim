local util = require('carbon.util')
local settings = require('carbon.settings')

describe('carbon', function()
  it('opens a buffer with name "carbon"', function()
    assert.equal('carbon', vim.fn.bufname())
  end)

  it('opens a buffer with filetype "carbon"', function()
    assert.equal('carbon', vim.o.filetype)
    assert.equal('carbon', vim.bo.filetype)
  end)

  it('displays the contents of the current directory', function()
    assert.same(vim.api.nvim_buf_get_lines(0, 0, -1, true), {
      vim.fn.fnamemodify(vim.loop.cwd(), ':t') .. '/',
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
    })
  end)

  for action, key in pairs(settings.actions) do
    local plug = util.plug(action)
    local plug_maparg = string.lower(vim.fn.maparg(util.plug(action), 'n'))
    local key_maparg = string.lower(vim.fn.maparg(key, 'n'))

    it(string.format('maps %s to carbon.%s', plug, action), function()
      assert.not_nil(string.find(plug_maparg, '<lua function %d+>'))
    end)

    it(string.format('maps %s to %s', key, plug), function()
      assert.same(key_maparg, plug)
    end)
  end
end)
