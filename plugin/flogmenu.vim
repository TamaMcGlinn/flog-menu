" Global constants

let g:flogmenu_commit_parse_error = 'flogmenu: unable to parse commit'

let g:flogmenu_logmenu = {'name': 'Log Menu',
 \'l': [':Flog -all', 'Normal'],
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

let g:flogmenu_gitmenu = {'name': 'Git Menu',
             \'s': [':Gstatus', 'Status'],
             \'r': [':Gedit', 'Toggle index / working file version'],
             \'R': [':Gread', 'Reset to index'],
             \'j': [':Git fetch --all', 'Fetch'],
             \'J': [':Git pull', 'Pull'],
             \'k': [':Git push', 'Push'],
             \'K': [':Git push --force-with-lease', 'Push force (lease)'],
             \'z': [':Git blame', 'Blame file'],
             \'b': [':Twiggy', 'Branches'],
             \'B': [':GBranches', 'Branch search'],
             \'t': [':GTags', 'Tags'],
             \'c': [':Git commit', 'Commit'],
             \'.': [':Git add .', 'Add CWD'],
             \',': [':Git add %', 'Add file'],
             \'d': [':Git add %:h', 'Add file dir'],
             \'l': [g:flogmenu_logmenu, 'Log'],
             \}

" set cursor to the last position
let g:flogmenu_opts = {'index':g:quickui#context#cursor}

" Global variables

let g:flogmenu_selection_info = {}

let g:flogmenu_takeover_context_menu = v:null
