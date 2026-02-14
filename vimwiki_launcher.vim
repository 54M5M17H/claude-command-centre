" Resolve paths at script load time
let s:wiki_path = expand(g:vimwiki_list[0].path)
let s:repo_dir = expand('<sfile>:p:h')

" Function for creating tasks
" <leader>t
" Takes text line and converts it to task with link
" Takes markdown todo and converts it to task with link
" Default folder is todo/ subdir
function! VimwikiTaskToLinkedTask() abort
  let l:line = getline('.')

  " If line already has a wiki link, do nothing
  if l:line =~ '\[\[.\{-}\]\]'
    return
  endif

  " Remove leading task marker (- [ ] / - [X])
  let l:text = substitute(l:line, '^\s*[-*+]\s\+\[[ xX]\]\s\+', '', '')
  " Remove plain list marker (- / * / +)
  let l:text = substitute(l:text, '^\s*[-*+]\s\+', '', '')
  let l:text = trim(l:text)

  if empty(l:text)
    return
  endif

  " Link goes to todo/... but displays without the prefix
  call setline('.', '- [ ] [[todo/' . l:text . '|' . l:text . ']]')
  call cursor(line('.'), strlen(getline('.')) + 1)
endfunction

augroup VimwikiTaskLink
  autocmd!
  autocmd FileType vimwiki nnoremap <buffer> <leader>t :call VimwikiTaskToLinkedTask()<CR>
augroup END


"" Tab for autocomplete, as Vimwiki conflicts with this
au filetype vimwiki silent! iunmap <buffer> <Tab>


" :AITask -- open a new tmux window and run claude with the current vimwiki file as the prompt
function! VimwikiAITask() abort
  let l:filepath = expand('%:p')

  if empty(l:filepath)
    echoerr 'AITask: buffer has no file path'
    return
  endif

  if empty($TMUX)
    echoerr 'AITask: not inside a tmux session'
    return
  endif

  update

  " Move from todo/ to wip/ if currently in todo/
  if l:filepath =~# s:wiki_path . '/todo/'
    VimwikiMv ../wip/
    let l:filepath = expand('%:p')
  endif

  let l:winname = tolower(substitute(expand('%:t:r'), ' ', '-', 'g'))[:20]
  let l:cmd = 'tmux new-window -n ' . shellescape(l:winname) . ' -e ' . shellescape('AITASK_FILE=' . l:filepath) . ' ''claude "Read the file $AITASK_FILE for your task instructions. Use $AITASK_FILE as your wip file to report progress updates to."; exec "$SHELL"'''
  call system(l:cmd)
  if v:shell_error
    echoerr 'AITask: failed to create tmux window'
  endif
endfunction

" :VimwikiMv <dest_dir> -- move current wiki file to a different directory
" e.g. :VimwikiMv ../todo/ or :VimwikiMv ../wip/
function! VimwikiMv(dest) abort
  let l:filepath = expand('%:p')
  if empty(l:filepath)
    echoerr 'VimwikiMv: buffer has no file path'
    return
  endif

  update

  let l:taskname = expand('%:t:r')
  let l:target = substitute(a:dest, '/\+$', '', '') . '/' . l:taskname
  execute 'VimwikiRenameFile ' . l:target
endfunction

augroup VimwikiAITask
  autocmd!
  autocmd FileType vimwiki command! -buffer AITask call VimwikiAITask()
  autocmd FileType vimwiki command! -buffer -nargs=1 VimwikiMv call VimwikiMv(<f-args>)
  autocmd FileType vimwiki nnoremap <buffer> <leader>ai :AITask<CR>
  autocmd FileType vimwiki nnoremap <buffer> <leader>mv :VimwikiMv ../
  execute 'autocmd BufNewFile ' . s:wiki_path . '/todo/*.wiki 0r ' . s:repo_dir . '/templates/task.wiki'
augroup END
