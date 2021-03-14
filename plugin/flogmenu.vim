" Global constants

let g:flogmenu_commit_parse_error = 'flogmenu: unable to parse commit'

let g:flogmenu_logmenu = {'name': 'Log Menu',
 \'l': ['call flogmenu#open_git_log()', 'Show git log'],
 \'c': [':Flog', 'Current branch'],
 \'s': [':Flogsplit -all', 'Split'],
 \'v': [':vertical Flogsplit -all', 'Vertical split'],
 \'t': [':Flog -format=%ad\ [%h]\ {%an}%d\ (%S)\ %s -all -path=%', 'File history'],
 \'k': [':vertical Flogsplit -format=%ad\ [%h]\ {%an}%d\ (%S)\ %s -all -path=%', 'Vsplit file history'],
 \'1': [':Flog -format=%ad\ [%h]\ {%an}%d\ (%S)\ %s -all -path=%:h', 'File ./ history'],
 \'2': [':Flog -format=%ad\ [%h]\ {%an}%d\ (%S)\ %s -all -path=%:h:h', 'File ../ history'],
 \'3': [':Flog -format=%ad\ [%h]\ {%an}%d\ (%S)\ %s -all -path=%:h:h:h', 'File ../../ history'],
 \'4': [':Flog -format=%ad\ [%h]\ {%an}%d\ (%S)\ %s -all -path=%:h:h:h:h', 'File ../../../ history'],
 \'5': [':Flog -format=%ad\ [%h]\ {%an}%d\ (%S)\ %s -all -path=%:h:h:h:h:h', 'File ../../../../ history'],
 \'6': [':Flog -format=%ad\ [%h]\ {%an}%d\ (%S)\ %s -all -path=%:h:h:h:h:h:h', 'File ../../../../../ history'],
 \}

" TODO make these really work
let g:flogmenu_stashmenu = {'name': 'Git stash menu',
              \'h': [':Git -p stash show -p stash', 'Show'],
              \'l': [':Git -p stash list',          'List'],
              \'a': [':Git stash apply stash@{',    'Apply'],
              \'p': [':Git stash pop',              'Pop'],
              \'s': [':Git stash push<space>',      'Stash'],
              \}

function Open_Git_Ref(reference) abort
  let l:all = split(a:reference, ':')
  execute 'Gedit ' . l:all[0] . ':' .  l:all[1] . ':' . l:all[2]
endfunction

command! -bang -nargs=* GitGrep
  \ call fzf#run(
  \   fzf#wrap({'source': 'git grep --line-number -- '.shellescape(<q-args>).' $(git rev-list --all)', 'sink': function('Open_Git_Ref')}), <bang>0)

let g:flogmenu_gitmenu = {'name': 'Git Menu',
             \'a': ['call flogmenu#open_all_windows()', 'All windows'],
             \'s': [':Gstatus', 'Status'],
             \'h': [g:flogmenu_stashmenu, 'Stash'],
             \'r': [':Gedit', 'Toggle index / working file version'],
             \'R': [':Gread', 'Reset to index'],
             \'j': [':Git fetch --all', 'Fetch'],
             \'J': [':Git pull', 'Pull'],
             \'k': [':Git push', 'Push'],
             \'K': [':Git push --force-with-lease', 'Push force (lease)'],
             \'n': [':Gvdiffsplit!', 'Diff file'],
             \'z': [':Git blame', 'Blame file'],
             \'b': [':Twiggy', 'Branches'],
             \'B': [':GBranches', 'Branch search'],
             \'t': [':GTags', 'Tags'],
             \'c': [':Git commit', 'Commit'],
             \'.': [':Git add .', 'Add CWD'],
             \',': [':Git add %', 'Add file'],
             \'u': ['call flogmenu#open_unmerged()', 'Open unmerged files'],
             \'d': [':Git add %:h', 'Add file dir'],
             \'l': [g:flogmenu_logmenu, 'Log'],
             \}

" set cursor to the last position
let g:flogmenu_opts = {'index':g:quickui#context#cursor}

" Global variables

let g:flogmenu_selection_info = {}

" Commands

command! SignifyReset call flogmenu#set_signify_target('HEAD')

