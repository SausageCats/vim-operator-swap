function! s:delhl(id, winid) abort
  let winid = win_getid()
  if winid == a:winid
    call matchdelete(a:id)
  else
    noautocmd call win_gotoid(a:winid)
    call matchdelete(a:id)
    noautocmd call win_gotoid(winid)
  endif
endfunction


function! operator#swap#highlight#timer(group, pattern, time, ...) abort
  if a:time == 0 | return | endif
  let priority = exists('a:000[0].priority') ? a:000[0].priority : 9999
  let id = matchadd(a:group, a:pattern, priority)
  if id != -1
    redraw
    exe "call timer_start(a:time, { -> execute('call s:delhl(''" . id . "'',''" . win_getid() . "'')', 'silent!')}, {'repeat': 1})"
  endif
endfunction




function! operator#swap#highlight#pattern(motion_wise, register, ...) abort

  let motion_wise = a:motion_wise

  " startpos (endpos) is a list that contains the cursor position [lnum, col] at the top (bottom right) left of the selection area.
  let startpos = exists('a:000[0].startpos') ? a:000[0].startpos : ''
  let endpos   = exists('a:000[0].endpos')   ? a:000[0].endpos   : ''

  if empty(startpos) || empty(endpos)

    if motion_wise =~# '\(char\|line\)'
      let hi_pattern = '\%V'

    elseif motion_wise ==# 'block'
      let saved_winview = winsaveview()
      let selected_text = eval('@' . a:register)

      normal! `[
      let split_reg   = split(selected_text, '\n')
      let area_height = len(split_reg)
      let area_width  = len(split_reg[0])
      let tmp_col     = col('.')-1
      let tmp_txt     = getline('.')[tmp_col : tmp_col+area_width-1]

      if tmp_txt ==# split_reg[0][0:len(tmp_txt)-1]
        let [lefttop_line, lefttop_col] = getpos('.')[1:2]
        let hi_leftcol    = lefttop_col - 1
        let hi_rightcol   = lefttop_col + area_width
        let hi_topline    = lefttop_line - 1
        let hi_bottomline = lefttop_line + area_height

      else
        normal! `]
        let [rightbottom_line, rightbottom_col] = getpos('.')[1:2]
        let hi_leftcol    = rightbottom_col - area_width
        let hi_rightcol   = rightbottom_col + 1
        let hi_topline    = rightbottom_line + area_height
        let hi_bottomline = rightbottom_line + 1

      endif
      call winrestview(saved_winview)

      if hi_leftcol < 0 | let hi_leftcol = 0 | endif
      let hi_pattern  = '\%>' . hi_leftcol . 'c.*\%<' . hi_rightcol   . 'c'
      let hi_pattern .= '\%>' . hi_topline . 'l\%<'   . hi_bottomline . 'l'

    endif

  else

    let start_line   = startpos[0]
    let start_col    = startpos[1]
    let end_line     = endpos[0]
    let end_col      = endpos[1]
    let hi_startline = startpos[0] - 1
    let hi_startcol  = max([startpos[1] - 1, 0])  " negative value when blank line is selected
    let hi_endline   = endpos[0] + 1
    let hi_endcol    = endpos[1] + 1

    if motion_wise ==# 'char'

      let height = endpos[0] - startpos[0] + 1
      if height == 1
        let hi_pattern =
              \   '\%>' . hi_startcol . 'c.*\%<' . hi_endcol . 'c'
              \ . '\%>' . hi_startline . 'l\%<' . hi_endline . 'l'

      elseif height == 2
        let hi_pattern =
              \   '\('
              \ . '\%>' . hi_startcol  . 'c.*'
              \ . '\%>' . hi_startline . 'l\%<' . (hi_startline+2) . 'l'
              \ . '\)\|'
              \ . '\('
              \ . '.*\%<' . hi_endcol  . 'c'
              \ . '\%>' . (hi_endline-2) . 'l\%<' . hi_endline . 'l'
              \ . '\)'

      else
        let hi_pattern =
              \   '\('
              \ . '\%>' . hi_startcol  . 'c.*'
              \ . '\%>' . hi_startline . 'l\%<' . (hi_startline+2) . 'l'
              \ . '\)\|'
              \ . '\('
              \ . '\%>' . (hi_startline+1) . 'l\%<' . (hi_endline-1) . 'l'
              \ . '\)\|'
              \ . '\('
              \ . '.*\%<' . hi_endcol . 'c'
              \ . '\%>' . (hi_endline-2) . 'l\%<' . hi_endline . 'l'
              \ . '\)'
      endif

    elseif motion_wise ==# 'line'
      let hi_pattern = '\%>' . hi_startline . 'l.*\%<' . hi_endline . 'l'

    elseif motion_wise ==# 'block'
      let hi_pattern =
              \   '\%>' . hi_startcol . 'c.*\%<' . hi_endcol . 'c'
              \ . '\%>' . hi_startline . 'l\%<' . hi_endline . 'l'

    endif

  endif

  return hi_pattern

endfunction
