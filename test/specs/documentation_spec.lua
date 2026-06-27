local util = require('carbon.util')
local helpers = require('test.config.helpers')

local neovim_txt = { tags = {}, refs = {} }
local readme_md = helpers.markdown_info(helpers.repo_path('README.md'))
local carbon_txt = helpers.help_info(helpers.repo_path('doc/carbon.txt'))

readme_md.internal_refs = {}
readme_md.external_refs = {}
carbon_txt.internal_refs = {}
carbon_txt.external_refs = {}

for ref in pairs(readme_md.refs) do
  local is_internal = vim.startswith(string.lower(ref), 'carbon')
  local type = is_internal and 'internal_refs' or 'external_refs'

  readme_md[type][ref] = (readme_md[type][ref] or 0) + 1
end

for ref in pairs(carbon_txt.refs) do
  local is_internal = vim.startswith(string.lower(ref), 'carbon')
  local type = is_internal and 'internal_refs' or 'external_refs'

  carbon_txt[type][ref] = (carbon_txt[type][ref] or 0) + 1
end

for _, rtp_path in ipairs(vim.opt.runtimepath:get()) do
  local docs = vim.fn.glob(string.format('%s/doc/**.txt', rtp_path), true, true)

  for _, doc_path in ipairs(docs) do
    for tag, count in pairs(helpers.help_info(doc_path).tags) do
      neovim_txt.tags[tag] = (neovim_txt.tags[tag] or 0) + count
    end
  end
end

describe('documentation', function()
  describe('carbon.txt', function()
    describe('Lua API helptag', function()
      for _, mod_name in ipairs({ 'entry', 'util', 'view', 'watcher' }) do
        local expected_tags = {}
        local mod = require(string.format('carbon.%s', mod_name))

        for property, value in pairs(mod) do
          if
            type(value) == 'function' and not vim.startswith(property, '__')
          then
            local property_tag = string.gsub(property, '_', '-')

            expected_tags[#expected_tags + 1] = {
              help_name = string.format('carbon-%s-%s', mod_name, property_tag),
              module_name = mod_name,
              method_name = property,
            }
          end
        end

        for _, tag in ipairs(expected_tags) do
          it(tag.help_name, function()
            assert(
              (carbon_txt.tags[tag.help_name] or 0) >= 1,
              string.format('%s is not documented', tag.help_name)
            )
          end)
        end
      end
    end)

    describe('helptags', function()
      for tag, count in pairs(carbon_txt.tags) do
        it(tag, function()
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

    describe('internal refs', function()
      for ref in pairs(carbon_txt.internal_refs) do
        it(ref, function()
          assert(
            carbon_txt.tags[ref],
            string.format('helptag "%s" does not exist', ref)
          )
        end)
      end
    end)

    describe('external refs', function()
      for ref in pairs(carbon_txt.external_refs) do
        it(ref, function()
          assert(
            util.tbl_find(neovim_txt.tags, function(_, helptag)
              return string.find(
                string.lower(helptag),
                string.lower(ref),
                1,
                true
              )
            end),
            string.format('helptag "%s" does not exist', ref)
          )
        end)
      end
    end)
  end)

  describe('README.md', function()
    describe('internal refs', function()
      for ref in pairs(readme_md.internal_refs) do
        it(ref, function()
          assert(
            carbon_txt.tags[ref],
            string.format('helptag "%s" does not exist', ref)
          )
        end)
      end
    end)

    describe('external refs', function()
      for ref in pairs(readme_md.external_refs) do
        it(string.format('check %s', ref), function()
          assert(
            carbon_txt.tags[ref],
            string.format('helptag "%s" does not exist', ref)
          )
        end)
      end
    end)

    describe('fragment refs', function()
      for ref in pairs(readme_md.header_refs) do
        it(string.format('check %s', ref), function()
          assert(
            readme_md.header_tags[ref],
            string.format('header fragment "%s" does not exist', ref)
          )
        end)
      end
    end)
  end)
end)
