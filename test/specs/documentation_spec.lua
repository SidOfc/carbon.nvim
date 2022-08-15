require('test.config.assertions')

local util = require('carbon.util')
local helpers = require('test.config.helpers')

local neovim_txt = { tags = {}, refs = {} }
local carbon_txt = helpers.help_info(
  string.format('%s/doc/carbon.txt', vim.env.CARBON_REPO_ROOT)
)

carbon_txt.internal_refs = {}
carbon_txt.external_refs = {}

for ref in pairs(carbon_txt.refs) do
  local is_internal = vim.startswith(string.lower(ref), 'carbon')
  local type = is_internal and 'internal_refs' or 'external_refs'

  carbon_txt[type][ref] = (carbon_txt[type][ref] or 0) + 1
end

for _, rtp_path in ipairs(vim.opt.runtimepath:get()) do
  local docs = vim.fn.glob(string.format('%s/doc/**.txt', rtp_path), 1, 1)

  for _, doc_path in ipairs(docs) do
    for tag, count in pairs(helpers.help_info(doc_path).tags) do
      neovim_txt.tags[tag] = (neovim_txt.tags[tag] or 0) + count
    end
  end
end

describe('carbon.txt', function()
  describe('helptags', function()
    for tag, count in pairs(carbon_txt.tags) do
      it(string.format('check %s', tag), function()
        assert(
          count == 1,
          string.format('%s is not unique (%d found)', tag, count)
        )

        assert(
          vim.startswith(tag, 'carbon'),
          string.format('%s does not start with "carbon"', tag)
        )
      end)
    end
  end)

  describe('internal references', function()
    for ref in pairs(carbon_txt.internal_refs) do
      it(string.format('check %s', ref), function()
        assert(
          carbon_txt.tags[ref],
          string.format('helptag "%s" does not exist', ref)
        )
      end)
    end
  end)

  describe('external references', function()
    for reference in pairs(carbon_txt.external_refs) do
      it(string.format('check %s', reference), function()
        assert(
          util.tbl_find(neovim_txt.tags, function(_, helptag)
            return string.find(
              string.lower(helptag),
              string.lower(reference),
              1,
              true
            )
          end),
          string.format('helptag "%s" does not exist', reference)
        )
      end)
    end
  end)
end)
