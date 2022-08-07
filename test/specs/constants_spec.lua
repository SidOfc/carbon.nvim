local util = require('carbon.util')
local constants = require('carbon.constants')

describe('carbon.constants', function()
  describe('hl', function()
    it('refers to namespace "carbon"', function()
      assert.same(
        'carbon',
        util.tbl_key(vim.api.nvim_get_namespaces(), constants.hl)
      )
    end)
  end)

  describe('hl_tmp', function()
    it('refers to namespace "carbon:tmp"', function()
      assert.same(
        'carbon:tmp',
        util.tbl_key(vim.api.nvim_get_namespaces(), constants.hl_tmp)
      )
    end)
  end)

  describe('augroup', function()
    it('refers to augroup "carbon"', function()
      local autocmd =
        vim.api.nvim_get_autocmds({ group = constants.augroup })[1]

      assert.not_nil(autocmd)
      assert.same('carbon', autocmd.group_name)
    end)
  end)
end)
