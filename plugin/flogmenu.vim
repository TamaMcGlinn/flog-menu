" Global constants

let g:flogmenu_commit_parse_error = 'flogmenu: unable to parse commit'

" don't ask me why shellescape('') - it works
command! -bang -nargs=* GitGrep
  \ call fzf#run(
  \   fzf#wrap({'source': 'git grep --line-number -- '.shellescape('').' $(git rev-list --all)', 'sink': function('flogmenu#open_git_ref_file')}), <bang>0)

" set cursor to the first item
let g:flogmenu_opts = {'index': 0}

" Global variables

let g:flogmenu_normalmode_cursorinfo = {}
let g:flogmenu_visual_selection_info = {}
let g:flogmenu_signify_target_commit = 'HEAD'

" Commands
command! SignifyReset call flogmenu#set_signify_target('HEAD')
command! SignifyCustom call flogmenu#set_signify_custom()

" Older / younger
command! SignifyOlder call flogmenu#set_signify_older()
command! SignifyNewer call flogmenu#set_signify_younger()

command! CompareOlder call flogmenu#compare_older()
command! CompareNewer call flogmenu#compare_younger()
