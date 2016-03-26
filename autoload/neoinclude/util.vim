"=============================================================================
" FILE: util.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!isdirectory('/proc') && executable('sw_vers')))
let s:is_unix = has('unix')

function! neoinclude#util#is_windows() abort
  return s:is_windows
endfunction

function! neoinclude#util#is_cygwin() abort
  return s:is_cygwin
endfunction

function! neoinclude#util#is_mac() abort
  return s:is_mac
endfunction

function! neoinclude#util#uniq(list) abort "{{{
  let dict = {}
  for item in a:list
    if !has_key(dict, item)
      let dict[item] = item
    endif
  endfor

  return values(dict)
endfunction"}}}

function! neoinclude#util#glob(pattern, ...) abort "{{{
  if a:pattern =~ "'"
    " Use glob('*').
    let cwd = getcwd()
    let base = neoinclude#util#substitute_path_separator(
          \ fnamemodify(a:pattern, ':h'))
    execute 'lcd' fnameescape(base)

    let files = map(split(neoinclude#util#substitute_path_separator(
          \ glob('*')), '\n'), "base . '/' . v:val")

    execute 'lcd' fnameescape(cwd)

    return files
  endif

  " let is_force_glob = get(a:000, 0, 0)
  let is_force_glob = get(a:000, 0, 1)

  if !is_force_glob && a:pattern =~ '^[^\\*]\+/\*'
        \ && neoinclude#util#has_vimproc() && exists('*vimproc#readdir')
    return filter(vimproc#readdir(a:pattern[: -2]), 'v:val !~ "/\\.\\.\\?$"')
  else
    " Escape [.
    if neoinclude#util#is_windows()
      let glob = substitute(a:pattern, '\[', '\\[[]', 'g')
    else
      let glob = escape(a:pattern, '[')
    endif

    return split(neoinclude#util#substitute_path_separator(glob(glob)), '\n')
  endif
endfunction"}}}

function! neoinclude#util#substitute_path_separator(path) abort "{{{
  return s:is_windows ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction"}}}

function! neoinclude#util#set_default_dictionary(variable, keys, value) abort "{{{
  call neoinclude#util#set_dictionary_helper({a:variable}, a:keys, a:value)
endfunction"}}}
function! neoinclude#util#set_dictionary_helper(variable, keys, pattern) abort "{{{
  for key in split(a:keys, '\s*,\s*')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}

function! neoinclude#util#system(command) abort "{{{
  let command = s:iconv(a:command, &encoding, 'char')

  let output = neoinclude#util#has_vimproc() ?
        \ vimproc#system(command) : system(command)

  let output = s:iconv(output, 'char', &encoding)

  return substitute(output, '\n$', '', '')
endfunction"}}}

function! neoinclude#util#has_vimproc() abort "{{{
  " Initialize.
  if !exists('s:exists_vimproc')
    " Check vimproc.
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif

  return s:exists_vimproc
endfunction"}}}
function! s:iconv(expr, from, to) abort "{{{
  if a:from == '' || a:to == '' || a:from ==? a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction"}}}

function! neoinclude#util#get_context_filetype() abort "{{{
  " context_filetype.vim installation check.
  if !exists('s:exists_context_filetype')
    try
      call context_filetype#version()
      let s:exists_context_filetype = 1
    catch
      let s:exists_context_filetype = 0
    endtry
  endif

  return s:exists_context_filetype ?
        \ context_filetype#get_filetype() : &filetype
endfunction"}}}

function! neoinclude#util#get_buffer_config(
      \ filetype, buffer_var, user_var, default_var, ...) "{{{
  let default_val = get(a:000, 0, '')

  if exists(a:buffer_var)
    return {a:buffer_var}
  endif

  let filetype = !has_key(a:user_var, a:filetype)
        \ && !has_key(a:default_var, a:filetype) ? '_' : a:filetype

  return get(a:user_var, filetype,
        \   get(a:default_var, filetype, default_val))
endfunction"}}}

function! neoinclude#util#head_match(checkstr, headstr) abort "{{{
  let checkstr = &ignorecase ?
        \ tolower(a:checkstr) : a:checkstr
  let headstr = &ignorecase ?
        \ tolower(a:headstr) : a:headstr
  return stridx(checkstr, headstr) == 0
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
