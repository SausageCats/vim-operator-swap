"
" configs
"
"hi default OperatorSwapArea0       cterm=bold ctermfg=81 ctermbg=3  guifg=#5fd7ff guibg=#808000
hi default OperatorSwapArea1       cterm=bold ctermfg=81 ctermbg=92 guifg=#5fd7ff guibg=#8700d7
hi default OperatorSwapArea2       cterm=bold ctermfg=81 ctermbg=2  guifg=#5fd7ff guibg=#008000
hi default OperatorSwapOverlapArea cterm=bold ctermfg=81 ctermbg=9  guifg=#5fd7ff guibg=#ff6060

" highlight time for selected area
if ! exists('g:operator_swap_area1_highlight_time') | let g:operator_swap_area1_highlight_time = 300 | endif
if ! exists('g:operator_swap_area2_highlight_time') | let g:operator_swap_area2_highlight_time = 600 | endif

" if true, join text in selected area with space
"if ! exists('g:operator_swap_join_text') | let g:operator_swap_join_text = v:false | endif

" if true, remove blank lines in selected area
"if ! exists('g:operator_swap_remove_blank_lines') | let g:operator_swap_remove_blank_lines = v:true | endif
let s:operator_swap_remove_blank_lines = v:true


"let g:operator_swap_countkey = {}
"let g:operator_swap_countkey.areacheck   = 96
"let g:operator_swap_countkey.areaswap    = 99
"let g:operator_swap_countkey.jointext    = 98
"let g:operator_swap_countkey.motionshift = 97


"
" local initial variables
"
let s:areanr           = 1       " 1, 2
let s:areacheck_mode   = v:false " v:t_bool
let s:mode             = ''      " 'normal', 'visual'
let s:undo_changedtick = -1      " v:t_number
let s:area1            = {}      " v:t_dict
let s:area2            = {}      " v:t_dict
let s:jointext_mode    = v:false " b:t_bool
function! s:SID() abort "  {{{
  let sidnr = matchstr(expand('<sfile>'), '^function <SNR>\zs\d\+\ze_')
  return printf("\<SNR>%s_", sidnr)
endfunction
let s:SID = s:SID() "  }}}
"let s:operator_swap_keep_position   = v:true  " QUESTION: this option is necessary?


"
" constant variable
"
"let s:MAX_LINE_LENGTH = 2147483647 " see E340



"
" public functions
"

function! s:common_mode_init(mode, sel_case) abort "  {{{
  call operator#swap#predot#set()
  let &l:opfunc=  s:SID . 'swap'
  let s:areacheck_mode = v:false
  let s:jointext_mode  = v:false
  let s:mode           = a:mode
  " QUESTION: 2019/11/21 should area2 be reset?
  if a:sel_case == 1 | let s:area2 = {} | endif
endfunction "  }}}

function! operator#swap#normal(sel_case) abort "  {{{

  " init
  let sel_case = a:sel_case
  let l:count  = v:count

  call s:common_mode_init('normal', sel_case)

  " countkey init
  let count_key       = exists('g:operator_swap_countkey') ? g:operator_swap_countkey : {}
  let areacheck_key   = get(count_key, 'areacheck'  , -1)
  let areaswap_key    = get(count_key, 'areaswap'   , -1)
  let jointext_key    = get(count_key, 'jointext'   , -1)
  let motionshift_key = get(count_key, 'motionshift', -1)
  let pressed_areacheck_key   = v:count =~# '^' . areacheck_key   ? v:true : v:false
  let pressed_areaswap_key    = v:count =~# '^' . areaswap_key    ? v:true : v:false
  let pressed_jointext_key    = v:count =~# '^' . jointext_key    ? v:true : v:false
  let pressed_motionshift_key = v:count =~# '^' . motionshift_key ? v:true : v:false

  " not swap, but highlight area
  if pressed_areacheck_key | let s:areacheck_mode = v:true | endif

  " exchange area1 and area2
  if pressed_areaswap_key || sel_case == 3
    call s:exchange_area1_and_area2()
  endif

  " join selected text and swap
  let s:jointext_mode = pressed_jointext_key ? v:true : v:false
  if exists('g:operator_swap_join_text') && g:operator_swap_join_text
    let s:jointext_mode = v:true
  endif

  " change l:count
  if     pressed_areacheck_key   | let l:count = l:count[len(areacheck_key):]
  elseif pressed_areaswap_key    | let l:count = l:count[len(areaswap_key):]
  elseif pressed_jointext_key    | let l:count = l:count[len(jointext_key):]
  elseif pressed_motionshift_key | let l:count = l:count[len(motionshift_key):]
  endif
  if l:count == 0 | let l:count = '' | endif

  " determine area number
  if sel_case == 0
    if ! pressed_areacheck_key && ! pressed_areaswap_key &&
    \  ! pressed_jointext_key  && ! pressed_motionshift_key
      let s:areanr = 1
    endif
  elseif sel_case == 1 | let s:areanr = 1
  elseif sel_case == 2 | let s:areanr = 2
  endif
  if s:areanr == 0 || empty(s:area1) | let s:areanr = 1 | endif

  call feedkeys(l:count . 'g@', 'n')

endfunction "  }}}

function! operator#swap#visual(sel_case) abort "  {{{
  let sel_case = a:sel_case
  call s:common_mode_init('visual', sel_case)
  if sel_case == 1 || sel_case == 2
    let s:areanr = sel_case
  elseif sel_case == 3
    call s:exchange_area1_and_area2()
  endif
  if s:areanr == 0 || empty(s:area1) | let s:areanr = 1 | endif
endfunction "  }}}



"
" QUESTION: 2019/11/21 should this function be moved in util directory?
" undo
"

function! operator#swap#undo() abort "  {{{
  if b:changedtick ==# s:undo_changedtick
    let saved_winview = winsaveview()
    undo
    call winrestview(saved_winview)
    if exists('s:prearea1') && exists('s:prearea2')
      let s:area1 = deepcopy(s:prearea1)
      let s:area2 = deepcopy(s:prearea2)
      unlet s:prearea1
      unlet s:prearea2
    else
      let s:area1 = {}
      let s:area2 = {}
    endif
    return
  endif
  exe 'normal! ' . v:count1 . 'u'
endfunction "  }}}

function! s:save_current_winview_for_undo() abort "  {{{
  let s:undo_changedtick = b:changedtick
endfunction "  }}}



"
" local functions
"

function! s:exchange_area1_and_area2() abort "{{{
  if ! empty(s:area1) && ! empty(s:area2)
    let tmp     = s:area1
    let s:area1 = s:area2
    let s:area2 = tmp
  endif
endfunction "}}}

function! s:check_areatext(register, area) abort "  {{{
  let area = a:area
  let saved_curpos = getcurpos()
  call cursor(area.startpos)
  if     area.wise ==# 'char'  | normal! v
  elseif area.wise ==# 'block' | silent exe 'normal! ' . "\<C-v>"
  elseif area.wise ==# 'line'  | normal! V
  endif
  call cursor(area.endpos)
  silent exe 'normal! "' . a:register . 'y'
  call setpos('.', saved_curpos)
  if area.number == 1
    let selected_text = eval('@' . a:register)
    if split(selected_text,"\n") !=# area.text
      throw '[OPERATORSWAP]Cannot swap due to buffer change'
    endif
  endif
endfunction "  }}}

function! s:motion_selection_area(wise, register, motion) abort "  {{{

  if s:mode ==# 'normal'
    if     a:wise ==# 'char'  | silent exe "normal! `[v`]\"" . a:register . a:motion
    elseif a:wise ==# 'line'  | silent exe "normal! '[V']\"" . a:register . a:motion
    elseif a:wise ==# 'block' | silent exe 'normal! gv"'     . a:register . a:motion
    endif

  elseif s:mode ==# 'visual'
    silent exe 'normal! gv"' . a:register . a:motion

  endif

"  call operator#swap#predot#restore()

endfunction "  }}}

function! s:parse_selection_area(wise, register) abort "  {{{

  let wise     = a:wise
  let register = a:register

  call s:motion_selection_area(wise, register, 'y')
  let selected_text = eval('@' . register)
  let lenlastline = 0 " this is a positive value when the last selected line includes nl in the case of char wise

  if wise ==# 'char'
    let startpos = getpos("'<")[1:2]
    let endpos   = [line("'>"), byteidx(getline("'>"), strchars(getline("'>")[:col("'>")-1]))]
    "let endpos   = getpos("'>")[1:2]
    if len(getline("'>"))+1 == endpos[1]
      let lenlastline = endpos[1] " includes NL
    endif

  elseif wise ==# 'line'
    let startpos = getpos("'<")[1:2]
    let endpos   = getpos("'>")[1:2]
    let endpos[1] = len(getline('.')) + 1 " +1 expresses NL

  elseif wise ==# 'block'
    normal! `[
    let split_reg   = split(selected_text, '\n')
    let area_height = len(split_reg)
    let area_width  = len(split_reg[0])
    let tmp_col     = col('.')-1
    let tmp_txt     = getline('.')[tmp_col : tmp_col+area_width-1]
    if tmp_txt ==# split_reg[0][0:len(tmp_txt)-1]
      let startpos = getpos('.')[1:2]
      let endpos   = [startpos[0]+area_height-1, startpos[1]+area_width-1]
    else
      normal! `]
      let endpos = getpos('.')[1:2]
      let startpos = [endpos[0]-area_height+1, endpos[1]-area_width+1]
    endif

  endif


  let text      = split(selected_text, "\n")
  let startline = startpos[0]
  let startcol  = startpos[1]
  let endline   = endpos[0]
  let endcol    = endpos[1] " endcol includes NL
  let height    = endpos[0] - startpos[0] + 1
  let width     = endpos[1] - startpos[1] + 1

  let textposlist = []
  if wise ==# 'char'
    if height == 1
      call add(textposlist, [startline, startcol, endcol])
    else
      call add(textposlist, [startline, startcol, startcol+len(text[0])])
      for i in range(1, height-2)
        call add(textposlist, [startline+i, 1, 1+len(text[i])])
      endfor
      call add(textposlist, [endline, 1, endcol])
    endif
  elseif wise ==# 'line'
    for i in range(0, height-1)
      call add(textposlist, [startline+i, 1, len(text[i])+1]) " +1 expresses NL
"      call add(textposlist, [startline+i, 1, s:MAX_LINE_LENGTH])
    endfor
  elseif wise ==# 'block'
    for i in range(0, height-1)
      call add(textposlist, [startline+i, startcol, endcol])
    endfor
  endif

  let textposdic = {}
  for [line, s_col, e_col] in textposlist
    let textposdic[line] = [s_col, e_col]
  endfor

  let area = {}
  let area['changedtick'] = b:changedtick
  let area['endcol']      = endcol
  let area['endline']     = endline
  let area['endpos']      = endpos  " = [area.endline, area.endcol]
  let area['height']      = height
  let area['lenlastline'] = lenlastline
  let area['mode']        = s:mode
  let area['number']      = s:areanr
  let area['startcol']    = startcol
  let area['startline']   = startline
  let area['startpos']    = startpos  " = [area.startline, area.startcol]
  let area['text']        = text
"  let area['textposlist'] = textposlist " = [[line, startcol, endcol], ...]
  let area['textposdic']  = textposdic  " = {line: [startcol, endcol]}
  let area['width']       = width
  let area['wise']        = wise

  return area

endfunction "  }}}

function! s:possible_swap(register) abort "  {{{

  let [area1     , area2     ] = [s:area1        , s:area2        ]
  let [startline1, startline2] = [area1.startline, area2.startline]
  let [endline1  , endline2  ] = [area1.endline  , area2.endline  ]
  let [startcol1 , startcol2 ] = [area1.startcol , area2.startcol ]
  let [endcol1   , endcol2   ] = [area1.endcol   , area2.endcol   ]
  let [height1   , height2   ] = [area1.height   , area2.height   ]
  let [width1    , width2    ] = [area1.width    , area2.width    ]
  let [wise1     , wise2     ] = [area1.wise     , area2.wise     ]

  let err_msg = '[OPERATORSWAP]Cannot swap area due to overlap area'

  " check if the current buffer is the same as the buffer when area1 is saved.
  if area1.changedtick != area2.changedtick
    call s:check_areatext(a:register, area1)
    if area2.mode ==# 'visual'
      " select area2 to enable dot repeat on visual mode
      call s:check_areatext(a:register, area2)
    endif
  endif

  if wise1 ==# 'block' && wise2 ==# 'block'
    let [center_x1, center_y1] = [startcol1+0.5*width1, startline1+0.5*height1]
    let [center_x2, center_y2] = [startcol2+0.5*width2, startline2+0.5*height2]
    let distance_cw = abs(center_x1-center_x2) + 0.1
    let distance_ch = abs(center_y1-center_y2) + 0.1
    if 0.5*(width1+width2) < distance_cw || 0.5*(height1+height2) < distance_ch | return v:true | endif

  " this elseif statement is unnecessary
  elseif (wise1 ==# 'line' && wise2 =~# '\(line\|char\|block\)')
    \ || (wise1 =~# '\(char\|block\)' && wise2 ==# 'line')
    if endline2 < startline1 || startline2 > endline1 | return v:true | endif

  else
    if endline2 < startline1 || (endline2 == startline1 && endcol2 < startcol1) | return v:true | endif
    if startline2 > endline1 || (startline2 == endline1 && startcol2 > endcol1) | return v:true | endif

  endif

  " common area exists

  let [textposdic1, textposdic2] = [area1.textposdic, area2.textposdic]

  " {line, [startcol, endcol]} => [line, startcol, endcol]
  let [lines1, lines2, pos1, pos2] = [[], [], [], []]
  for line in keys(textposdic1) | call add(lines1, line) | endfor | call sort(lines1, 'n')
  for line in keys(textposdic2) | call add(lines2, line) | endfor | call sort(lines2, 'n')
  for line in lines1 | call add(pos1, extend([line], textposdic1[line])) | endfor
  for line in lines2 | call add(pos2, extend([line], textposdic2[line])) | endfor

  " find common area
  let compos = []
  for [line, cols] in items(textposdic1)
    if has_key(textposdic2, line)
      let [scol1, ecol1] = cols
      let [scol2, ecol2] = textposdic2[line]
      let max_startcol = max([scol1, scol2])
      let min_endcol   = min([ecol1, ecol2])
      call add(compos, [line, max_startcol, min_endcol])
    endif
  endfor

  " highlight
  call s:highlight_areas_on_failure(pos1, pos2, compos)

  throw err_msg

endfunction "  }}}

function! s:swap(wise) abort "  {{{

  " this value must first be set to v:false
  let areacheck_mode = s:areacheck_mode | let s:areacheck_mode = v:false

  " init
  let areanr = areacheck_mode ? 0 : s:areanr " define area zero here
  let wise   = a:wise
  let is_successful = v:false
  let should_highlight_area = areanr <= 1 ? v:true : v:false
  let saved_selection = &selection | let &selection = 'inclusive'
  let register = 'a' | let [saved_reg, saved_regtype] = [getreg(register, 1, 1), getregtype(register)]

  try

    let area = s:parse_selection_area(wise, register)

    if areanr == 1
      let s:area1 = area
      let is_successful = v:true

    elseif areanr == 2
      let s:area2 = area
      if s:possible_swap(register)
        let replines_item = s:make_replacement_items()
        if ! empty(replines_item)
          call s:do_swap(replines_item)
          let is_successful = v:true
        endif
      endif
      call s:save_current_winview_for_undo()

    endif

    call operator#swap#predot#restore()

    if should_highlight_area
      let opt = {'startpos': area.startpos, 'endpos': area.endpos }
      let hi_pattern = operator#swap#highlight#pattern(wise, register, opt)
      if     areanr == 0 | let hi_group = 'OperatorSwapArea0'
      elseif areanr == 1 | let hi_group = 'OperatorSwapArea1'
      elseif areanr == 2 | let hi_group = 'OperatorSwapArea2'
      endif
      let hi_time = g:operator_swap_area1_highlight_time
      call operator#swap#highlight#timer(hi_group, hi_pattern, hi_time)
    endif

    if is_successful
      if     areanr == 1 | let s:areanr = 2
      elseif areanr == 2 | call s:update_areas(replines_item)
      endif
    endif

  catch
    redraw | echohl Error
    if v:exception =~# '^\[OPERATORSWAP\]' | echo substitute(v:exception, '\[OPERATORSWAP\]', '', '')
    else                                   | echo v:throwpoint . "\n" . v:exception
    endif
    echohl None
    call operator#swap#predot#restore()

  endtry

  call setreg(register, saved_reg, saved_regtype)
  let &selection = saved_selection

endfunction "  }}}

function! s:update_areas(replines_item) abort "  {{{
  let area1 = s:area1
  let area2 = s:area2

  if area1.height != area2.height | return | endif
  if area1.wise   != area2.wise   | return | endif

  let replines_item = a:replines_item

  let [rep_areanr1, rep_areanr2] = replines_item['rep_areanr']
  let textpos1 = replines_item['textpos'.rep_areanr1]
  let textpos2 = replines_item['textpos'.rep_areanr2]
  let lines    = replines_item['lines']

  let s:prearea1 = deepcopy(s:area1)
  let s:prearea2 = deepcopy(s:area2)
  let s:area1 = s:update_area(area1, textpos1, lines)
  let s:area2 = s:update_area(area2, textpos2, lines)
endfunction "  }}}

function! s:update_area(area, textpos, lines) abort "  {{{

  let area    = a:area
  let textpos = a:textpos  " = [[line, startcol, endcol]]
  let lines   = a:lines

  let lenlastline = area.lenlastline
  let mode        = area.mode
  let number      = area.number
  let wise        = area.wise

  " extract selected area
  let selarea = []
  for idx in range(len(lines))
    let [line, scol, ecol] = textpos[idx]
    if scol is# '' | continue | endif
    call add(selarea, [idx, line, scol, ecol])
  endfor

  " check if a new line is present
  if wise ==# 'line' || (wise ==# 'char' && len(selarea) >= 2)
    " adjust endcol
    for i in range(len(selarea))
      let selarea[i][3] += 1
    endfor
    if lenlastline > 0 " this value is always zero in the case of line wise
      let lastidx = selarea[-1][0]
      if lenlastline != len(lines[lastidx])+1 " +1 expresses NL
        let selarea[-1][3] -= 1
        let lenlastline = 0
      endif
    endif
  endif

  let text       = []
  let textposdic = {}
  for [idx, line, scol, ecol] in selarea
    call add(text, lines[idx][scol-1 : ecol-1])
    let textposdic[line] = [scol, ecol]
  endfor

  let startline = selarea[0][1]
  let endline   = selarea[len(selarea)-1][1]
  let startcol  = textposdic[startline][0]
  let endcol    = textposdic[endline][1]


  let new_area = {}
  let new_area['changedtick'] = b:changedtick
  let new_area['endcol']      = endcol
  let new_area['endline']     = endline
  let new_area['endpos']      = [endline, endcol]
  let new_area['height']      = endline - startline + 1
  let new_area['lenlastline'] = lenlastline
  let new_area['mode']        = mode
  let new_area['number']      = number
  let new_area['startcol']    = startcol
  let new_area['startline']   = startline
  let new_area['startpos']    = [startline, startcol]
  let new_area['text']        = text
"  let new_area['textposlist'] = textposlist " = [[line, startcol, endcol], ...]
  let new_area['textposdic']  = textposdic  " = {line: [startcol, endcol]}
  let new_area['width']       = endcol - startcol + 1
  let new_area['wise']        = wise

  return new_area

endfunction "  }}}



"
" swap
"

function! s:do_swap(replines_item) abort "  {{{

  let [nr1, nr2] = a:replines_item['head_area'] == 1
                 \ ? ( a:replines_item['reverse'] ? [2, 1] : [1, 2] )
                 \ : ( a:replines_item['reverse'] ? [1, 2] : [2, 1] )

  let target_linenr = a:replines_item['target_linenr']
  let rep_lines     = a:replines_item['lines']
  let rep_textpos1  = a:replines_item['textpos'.nr1]
  let rep_textpos2  = a:replines_item['textpos'.nr2]

  let replines_str = ''
  for i in range(len(rep_lines))
    let replines_str .= rep_lines[i] . "\n"
  endfor
  let target_startline = target_linenr[0]
  let target_endline   = target_linenr[1]

  silent exe target_startline . ',' . target_endline . 'delete _'
  if target_startline == line('$') | silent exe target_startline     . 'put! =replines_str'
  else                             | silent exe (target_startline-1) . 'put  =replines_str'
  endif

  " QUESTION: simple check for folding level ... should be improved?
  let start_foldlevel = foldlevel(target_startline)
  let end_foldlevel   = foldlevel(target_endline+len(rep_lines)-1)
  let max_foldlevel   = max([start_foldlevel, end_foldlevel])
  if max_foldlevel > 0
    silent! exe 'normal! ' . max_foldlevel . 'zo'
  endif

  call s:highlight_areas(rep_textpos1, rep_textpos2)

  let a:replines_item['rep_areanr'] = [nr1, nr2]

endfunction "  }}}


" heighlight
function! s:highlight_areas_on_failure(pos1, pos2, compos) abort "  {{{
  let hi_compat = s:create_hilight_pattern(a:compos)
  let hi_time   = g:operator_swap_area2_highlight_time
  call s:highlight_areas(a:pos1, a:pos2)
  call operator#swap#highlight#timer('OperatorSwapOverlapArea', hi_compat, hi_time)
endfunction "  }}}

function! s:highlight_areas(pos1, pos2) abort "  {{{
  let hi_pat1 = s:create_hilight_pattern(a:pos1)
  let hi_pat2 = s:create_hilight_pattern(a:pos2)
  let hi_time = g:operator_swap_area2_highlight_time
"  let hi_pat1 = hi_pat1 . '\|' .hi_pat2
"  call operator#swap#highlight#timer('OperatorSwapArea1', hi_pat1, hi_time)
  call operator#swap#highlight#timer('OperatorSwapArea1', hi_pat1, hi_time)
  call operator#swap#highlight#timer('OperatorSwapArea2', hi_pat2, hi_time)
endfunction "  }}}

function! s:create_hilight_pattern(pos) abort "  {{{
  let hi_pattern = ''
  for [line, s_col, e_col] in a:pos
    if s_col is# '' | continue | endif
    let hi_pattern .=
          \   '\%('
          \ . '\%>' . (s_col-1) . 'c.*\%<' . (e_col+1) . 'c'
          \ . '\%>' . (line-1)  .   'l\%<' . (line+1)  . 'l'
          \ . '\)\|'
  endfor
  let hi_pattern = hi_pattern[:-3]
  return hi_pattern
endfunction "  }}}



"
" make replacement lines
"

" blockwise
function! s:make_spaces_for_addedlines(areanr, replines_item) abort "  {{{

  let nr = a:areanr == 1 ? 1 : 2
  let startcol = -1

  for idx in range(len(a:replines_item['lines'])-1, 0, -1)
    if a:replines_item['textpos'.nr][idx][1] isnot# ''
      let startcol = a:replines_item['textpos'.nr][idx][1] - 1
      break
    endif
  endfor

  if startcol == -1 | return '' | endif

  let spaces = ''
  for _ in range(startcol)
    let spaces .= ' '
  endfor

  return spaces

endfunction "  }}}

" delete linenrs
function! s:add_linenr_to_dellinenrs(line, linenr, del_linenrs) abort "  {{{
  if a:line is# ''
    call add(a:del_linenrs, a:linenr)
  endif
endfunction "  }}}

function! s:update_dellinenrs(start_linenr, addednr, del_linenrs) abort "  {{{
  let start_linenr = a:start_linenr
  let addednr      = a:addednr
  let del_linenrs  = a:del_linenrs
  for idx in range(len(del_linenrs))
    let linenr = del_linenrs[idx]
    if start_linenr <= linenr
      let del_linenrs[idx] += addednr
    endif
  endfor
endfunction "  }}}


" new line
function! s:make_newlinedic(wise, len, lenlastline) abort "  {{{
  let wise = a:wise
  let nl = []
  if     wise ==# 'char'  | for _ in range(a:len) | call add(nl, 1) | endfor
  elseif wise ==# 'line'  | for _ in range(a:len) | call add(nl, 1) | endfor
  elseif wise ==# 'block' | for _ in range(a:len) | call add(nl, 0) | endfor
  endif
  if wise ==# 'char' && a:lenlastline == 0
    let nl[-1] = 0
  endif
  return nl
endfunction "  }}}


" replace lines
function! s:delete_empty_lines(replines_item, del_linenrs) abort "  {{{

  let replines_item = a:replines_item
  let del_linenrs   = a:del_linenrs

  let linenrs = []
  for [linenr, _, _] in replines_item['textpos1']
    call add(linenrs, linenr)
  endfor

  for idx in range(len(del_linenrs))
    let del_linenr = del_linenrs[idx]
    let matched_idx = index(linenrs, del_linenr)
    if matched_idx != -1
      for idx in range(matched_idx+1, len(replines_item['lines'])-1)
        let replines_item['textpos1'][idx][0] -= 1
        let replines_item['textpos2'][idx][0] -= 1
      endfor
      call remove(replines_item['lines']   , matched_idx)
      call remove(replines_item['textpos1'], matched_idx)
      call remove(replines_item['textpos2'], matched_idx)
      call remove(linenrs                  , matched_idx)
    endif
  endfor

endfunction "  }}}

function! s:make_repline_onearea(areanr1, line, col1, text2, nl2) abort "  {{{

  " a:areanr1 is an area number
  " a:line is a line that includes part of an area specified by a:areanr1
  " the region is indicated by a:col1, which is a list that contains column number of start and end positions
  " the region will be replaced with text2, that is, let a:line[a:col1[0]-1:a:col1[1]-1] = text2
  " a:nl2 is 0 or 1; if text2 has a new line, a:nl2 is 1

  let [startcol1, endcol1] = a:col1

  let str1 = startcol1 == 1           ? '' : a:line[0       : startcol1-2]
  let str2 = endcol1   >= len(a:line) ? '' : a:line[endcol1 :            ]  " > expresses nl

  let nl2 = a:nl2 == 1 && len(str2) == 0 ? 1 : 0

  let s_col2 = len(str1) + 1
  let e_col2 = s_col2 + len(a:text2) - 1 + nl2

  let repline = str1 . a:text2 . str2
  if a:areanr1 == 1 | let repline_item = s:repline_format(repline, ['', ''], [s_col2, e_col2])
  else              | let repline_item = s:repline_format(repline, [s_col2, e_col2], ['', ''])
  endif

  return repline_item

endfunction "  }}}

function! s:make_repline_twoarea(areanr1, line, col1, text1, nl1, col2, text2, nl2) abort "  {{{

  let [startcol1, endcol1] = a:col1
  let [startcol2, endcol2] = a:col2

  let str1 = startcol1 == 1           ? '' : a:line[0       : startcol1-2]
  let str2 = endcol1+1 == startcol2   ? '' : a:line[endcol1 : startcol2-2]
  let str3 = endcol2   >= len(a:line) ? '' : a:line[endcol2 :            ]  " > expresses nl

  let nl1 = a:nl1 == 1 && len(str3) == 0 ? 1 : 0
  let nl2 = a:nl2 == 1 && len(str2) == 0 && len(a:text1) == 0 && len(str3) == 0 ? 1 : 0

  let s_col2 = len(str1) + 1
  let e_col2 = s_col2 + len(a:text2) - 1 + nl2
  let s_col1 = e_col2 + len(str2) + 1
  let e_col1 = s_col1 + len(a:text1) - 1 + nl1

  let repline = str1 . a:text2 . str2 . a:text1 . str3
  if a:areanr1 == 1 | let repline_item = s:repline_format(repline, [s_col1, e_col1], [s_col2, e_col2])
  else              | let repline_item = s:repline_format(repline, [s_col2, e_col2], [s_col1, e_col1])
  endif

  return repline_item

endfunction "  }}}

function! s:replines_init(head_area, target_linenr) abort "  {{{
  let replines_item = {}
  let replines_item['head_area']     = a:head_area
  let replines_item['reverse']       = v:false
  let replines_item['target_linenr'] = a:target_linenr
  let replines_item['lines']         = []
  let replines_item['textpos1']      = []
  let replines_item['textpos2']      = []
  return replines_item
endfunction "  }}}

function! s:repline_format(line, col1, col2) abort "  {{{
  return {
        \ 'line' : a:line,
        \ 'col1' : a:col1,
        \ 'col2' : a:col2,
        \ }
endfunction "  }}}

function! s:update_replines(replines_item, linenr, repline_item, ...) abort "  {{{

  let repline_item = a:repline_item
  let rep_line     = repline_item['line']
  let rep_col1     = repline_item['col1']
  let rep_col2     = repline_item['col2']

  let replines_item = a:replines_item
  let linenr        = a:linenr

  if a:0 == 0
    call add(replines_item['lines'], rep_line)
    call add(replines_item['textpos1'], [linenr, rep_col1[0], rep_col1[1]])
    call add(replines_item['textpos2'], [linenr, rep_col2[0], rep_col2[1]])

  else
    let insertidx = a:1
    call insert(replines_item['lines'], rep_line, insertidx)
    call insert(replines_item['textpos1'], [linenr, rep_col1[0], rep_col1[1]], insertidx)
    call insert(replines_item['textpos2'], [linenr, rep_col2[0], rep_col2[1]], insertidx)
    let loopnr = (len(replines_item['lines'])-1) - (insertidx+1) + 1
    for i in range(loopnr)
      let idx = insertidx + 1 + i
      let replines_item['textpos1'][idx][0] += 1
      let replines_item['textpos2'][idx][0] += 1
    endfor

  endif

endfunction "  }}}


" main
function! s:make_replacement_items() abort "  {{{

  let [area1     , area2      ] = [s:area1        , s:area2        ]
  let [startline1, startline2 ] = [area1.startline, area2.startline]
  let [endline1  , endline2   ] = [area1.endline  , area2.endline  ]
  let [startcol1 , startcol2  ] = [area1.startcol , area2.startcol ]
  let [wise1     , wise2      ] = [area1.wise     , area2.wise     ]

  if startline1 == startline2 | let head_area = startcol1  < startcol2  ? 1 : 2
  else                        | let head_area = startline1 < startline2 ? 1 : 2
  endif

  let min_startline = min([startline1, startline2])
  let max_endline   = max([endline1  , endline2])
  let replines_item = s:replines_init(head_area, [min_startline, max_endline])

  if s:jointext_mode
    if head_area == 1 | return s:make_replines_onerow(area1, area2, replines_item)
    else              | return s:make_replines_onerow(area2, area1, replines_item)
    endif
  endif

"  if s:operator_swap_keep_position

    if wise1 ==# 'block' && wise2 ==# 'block'
      if head_area == 1
        if startline1 < startline2 && startcol1 > startcol2
          "   [1]
          "[2][1]
          let replines_item.reverse = v:true
          return s:make_replines(area2, area1, replines_item)
        endif
      else
        if startline1 > startline2 && startcol1 < startcol2
          "   [2]
          "[1][2]
          let replines_item.reverse = v:true
          return s:make_replines(area1, area2, replines_item)
        endif
      endif
    endif

    if head_area == 1 | return s:make_replines(area1, area2, replines_item)
    else              | return s:make_replines(area2, area1, replines_item)
    endif

"  endif

  return ''

endfunction "  }}}

function! s:make_replines(area1, area2, replines_item) abort "  {{{

  let replines_item = a:replines_item

  let [area1      , area2      ] = [a:area1         , a:area2         ]
  let [startline1 , startline2 ] = [area1.startline , area2.startline ]
  let [endline1   , endline2   ] = [area1.endline   , area2.endline   ]
  let [textposdic1, textposdic2] = [area1.textposdic, area2.textposdic]
  let [text1      , text2      ] = [area1.text      , area2.text      ]
  let [wise1      , wise2      ] = [area1.wise      , area2.wise      ]

  let [i_area1  , i_area2  ] = [0         , 0         ]
  let [max_area1, max_area2] = [len(text1), len(text2)]

  let min_startline = min([startline1, startline2])
  let max_endline   = max([endline1  , endline2])

  let i_linenr     = min_startline
  let i_replinesnr = min_startline

  let del_linenrs = []

  let wise_block1 = wise1 ==# 'block' ? v:true : v:false
  let wise_block2 = wise2 ==# 'block' ? v:true : v:false

  let nl1 = s:make_newlinedic(wise1, max_area1, area1.lenlastline)
  let nl2 = s:make_newlinedic(wise2, max_area2, area2.lenlastline)

  "
  " strategy
  "
  "       swap      insert    delete
  "
  "   1         A         A         A
  " A 2   =>  1 B   =>  1 B   =>  1 B
  " B 3       2 *       2 *       2 *
  "   4         *       3         3
  "                     4         4
  "                       *
  "

  " swap text1 for text2, and vice versa
  " min_startline <= line <= max_endline

  let loopnr = max_endline - min_startline + 1
  for _ in range(loopnr)
    let linenr = i_linenr
    let line   = getline(linenr) | let i_linenr += 1
    let text1_exists = has_key(textposdic1, linenr) ? v:true : v:false
    let text2_exists = has_key(textposdic2, linenr) ? v:true : v:false
    if text1_exists && text2_exists
      if     i_area1 < max_area1 && i_area2 < max_area2 | let [t1, t2, i1, i2, n1, n2] = [text1[i_area1], text2[i_area2], 1, 1, nl1[i_area1], nl2[i_area2]]
      elseif i_area1 < max_area1                        | let [t1, t2, i1, i2, n1, n2] = [text1[i_area1], ''            , 1, 0, nl1[i_area1], 0           ]
      elseif                        i_area2 < max_area2 | let [t1, t2, i1, i2, n1, n2] = [''            , text2[i_area2], 0, 1, 0           , nl2[i_area2]]
      else                                              | let [t1, t2, i1, i2, n1, n2] = [''            , ''            , 0, 0, 0           , 0           ]
      endif
      let repline_item = s:make_repline_twoarea(1, line, textposdic1[linenr], t1, n1, textposdic2[linenr], t2, n2)
      let i_area1 += i1 | let i_area2 += i2
    elseif text1_exists
      if   i_area2 < max_area2 | let [t2, i2, n2] = [text2[i_area2], 1, nl2[i_area2]]
      else                     | let [t2, i2, n2] = [''            , 0, 0           ]
      endif
      let repline_item = s:make_repline_onearea(1, line, textposdic1[linenr], t2, n2)
      let i_area2 += i2
      call s:add_linenr_to_dellinenrs(repline_item.line, linenr, del_linenrs)
    elseif text2_exists
      if   i_area1 < max_area1 | let [t1, i1, n1] = [text1[i_area1], 1, nl1[i_area1]]
      else                     | let [t1, i1, n1] = [''            , 0, 0           ]
      endif
      let repline_item = s:make_repline_onearea(2, line, textposdic2[linenr], t1, n1)
      let i_area1 += i1
      call s:add_linenr_to_dellinenrs(repline_item.line, linenr, del_linenrs)
    else
      let repline_item = s:repline_format(line, ['', ''], ['', ''])
    endif
    call s:update_replines(replines_item, i_replinesnr, repline_item) | let i_replinesnr += 1
  endfor

  " insert text
  " min_endline <= line <= min_endline+1

  if i_area1 < max_area1
    " the heigh of area1 is larger than that of area2.
    " insert the remaining text1 between endline2 and endline2+1.
    " update line number of replines_item and del_linenrs
    let spaces = wise_block1 ? s:make_spaces_for_addedlines(1, replines_item) : ''
    let loopnr = (max_area1-1) - i_area1 + 1
    for i in range(loopnr)
      " FIXME: how text1 is added
      let text         = spaces . text1[i_area1]
      let repline_item = s:repline_format(text, [len(spaces)+1, len(text)+nl1[i_area1]], ['', '']) | let i_area1 += 1
      let linenr       = endline2 + 1 + i
      let insertidx    = linenr - min_startline
      call s:update_replines(replines_item, linenr, repline_item, insertidx) | let i_replinesnr += 1
    endfor
    call s:update_dellinenrs(endline2+1, loopnr, del_linenrs)

  elseif i_area2 < max_area2
    " area2 is larger
    " same codes as area1
    let spaces = wise_block2 ? s:make_spaces_for_addedlines(2, replines_item) : ''
    let loopnr = (max_area2-1) - i_area2 + 1
    for i in range(loopnr)
      " FIXME: how text2 is added
      let text         = spaces . text2[i_area2]
      let repline_item = s:repline_format(text, ['', ''], [len(spaces)+1, len(text)+nl2[i_area2]]) | let i_area2 += 1
      let linenr       = endline1 + 1 + i
      let insertidx    = linenr - min_startline
      call s:update_replines(replines_item, linenr, repline_item, insertidx) | let i_replinesnr += 1
    endfor
    call s:update_dellinenrs(endline1+1, loopnr, del_linenrs)

  endif

  " delete empty lines

  if s:operator_swap_remove_blank_lines
    call s:delete_empty_lines(replines_item, del_linenrs)
  endif

  return replines_item

endfunction "  }}}

function! s:make_replines_onerow(area1, area2, replines_item) abort "  {{{

  let replines_item = a:replines_item

  let [area1      , area2      ] = [a:area1         , a:area2         ]
  let [startline1 , startline2 ] = [area1.startline , area2.startline ]
  let [endline1   , endline2   ] = [area1.endline   , area2.endline   ]
  let [textposdic1, textposdic2] = [area1.textposdic, area2.textposdic]
  let [text1      , text2      ] = [area1.text      , area2.text      ]

  let nl1 = s:make_newlinedic(area1.wise, 1, area1.lenlastline)[0]
  let nl2 = s:make_newlinedic(area2.wise, 1, area2.lenlastline)[0]

  let i_linenr     = startline1
  let i_replinesnr = startline1

  let join_text1 = join(text1, ' ')
  let join_text2 = join(text2, ' ')

  let loopnr = endline2-startline1+1
  for _ in range(loopnr)
    let linenr = i_linenr
    let line   = getline(linenr) | let i_linenr += 1
    if linenr == startline1
      if startline1 == startline2
        let repline_item = s:make_repline_twoarea(1, line, textposdic1[linenr], join_text1, nl1, textposdic2[linenr], join_text2, nl2)
      else
        let repline_item = s:make_repline_onearea(1, line, textposdic1[linenr], join_text2, nl2)
      endif
    elseif linenr == startline2
      if has_key(textposdic1, linenr)
        let repline_item = s:make_repline_twoarea(1, line, textposdic1[linenr], join_text1, nl1, textposdic2[linenr], '', nl2)
      else
        let repline_item = s:make_repline_onearea(2, line, textposdic2[linenr], join_text1, nl1)
      endif
    else
      let has_key1 = has_key(textposdic1, linenr) ? v:true : v:false
      let has_key2 = has_key(textposdic2, linenr) ? v:true : v:false
      if has_key1 || has_key2
        " The first argument of make_repline_... is 1 or 2, but either is good because empty string ('') is passed
        if has_key1 && has_key2
          let repline_item = s:make_repline_twoarea(1, line, textposdic1[linenr], '', 0, textposdic2[linenr], '', 0)
        elseif has_key1
          let repline_item = s:make_repline_onearea(1, line, textposdic1[linenr], '', 0)
        else
          let repline_item = s:make_repline_onearea(2, line, textposdic2[linenr], '', 0)
        endif
        if s:operator_swap_remove_blank_lines
          if repline_item.line is# '' | continue | endif
        endif
      else
        let repline_item = s:repline_format(line, ['', ''], ['', ''])
      endif
    endif
    call s:update_replines(replines_item, i_replinesnr, repline_item) | let i_replinesnr += 1
  endfor

  return replines_item

endfunction "  }}}
