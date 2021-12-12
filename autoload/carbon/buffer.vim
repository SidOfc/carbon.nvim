let s:buffer = luaeval('require("carbon.buffer")')

function! carbon#buffer#current(...)
  return call(s:buffer.current, a:000)
endfunction

function! carbon#buffer#set(...)
  return call(s:buffer.set, a:000)
endfunction

function! carbon#buffer#map(...)
  return call(s:buffer.map, a:000)
endfunction

function! carbon#buffer#show(...)
  return call(s:buffer.show, a:000)
endfunction

function! carbon#buffer#draw(...)
  return call(s:buffer.draw, a:000)
endfunction

function! carbon#buffer#cursor_entry(...)
  return call(s:buffer.cursor_entry, a:000)
endfunction

function! carbon#buffer#entries_to_lines(...)
  return call(s:buffer.entries_to_lines, a:000)
endfunction
