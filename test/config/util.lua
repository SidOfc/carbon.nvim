local util = {}

function util.tmpdir()
  return vim.fn.tempname()
end

function util.cwd_dirname()
  return vim.fn.fnamemodify(vim.loop.cwd(), ':t')
end

function util.buf_tostring(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf or 0, 0, -1, true), '\n')
end

function util.copy(source, destination)
  for name, type in vim.fs.dir(source) do
    local next_source = string.format('%s/%s', source, name)
    local next_destination = string.format('%s/%s', destination, name)

    if type == 'directory' then
      if vim.fn.isdirectory(next_destination) ~= 1 then
        vim.fn.mkdir(next_destination, 'p')
      end

      util.copy(next_source, next_destination)
    else
      if vim.fn.isdirectory(destination) ~= 1 then
        vim.fn.mkdir(destination, 'p')
      end

      vim.fn.writefile({ '' }, next_destination)
    end
  end
end

return util
