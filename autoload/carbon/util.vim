let s:util = luaeval('require("carbon.util")')

function! carbon#util#ls(...)
  return call(s:util.ls, a:000)
endfunction

function! carbon#util#has(...)
  return call(s:util.has, a:000)
endfunction

function! carbon#util#entry(...)
  return call(s:util.entry, a:000)
endfunction

function! carbon#util#expand(...)
  return call(s:util.expand, a:000)
endfunction

function! carbon#util#ternary(...)
  return call(s:util.ternary, a:000)
endfunction

function! carbon#util#highlight(...)
  return call(s:util.highlight, a:000)
endfunction

function! carbon#util#is_directory(...)
  return call(s:util.is_directory, a:000)
endfunction
