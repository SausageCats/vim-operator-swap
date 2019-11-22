function! operator#swap#predot#set() abort
  let s:winview = winsaveview()
endfunction


function! operator#swap#predot#restore() abort
  if exists('s:winview')
    call winrestview(s:winview)
  endif
endfunction
