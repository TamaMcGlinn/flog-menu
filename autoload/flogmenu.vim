
function flogmenu#open_git_ref(reference) abort
  let l:all = split(a:reference, ':')
  let l:fugitive_command = 'Gedit ' . l:all[0] . ':' .  l:all[1]
  let l:line = l:all[2]
  execute l:fugitive_command
  silent execute 'normal! ' . l:line . 'G'
endfunction

fu! flogmenu#open_menu(menu) abort
  if len(a:menu) == 0
    throw 'Refusing to open empty menu'
  endif
  if len(a:menu) == 1
    execute a:menu[0][1]
  else
    call quickui#context#open(a:menu, g:flogmenu_opts)
  endif
endfunction

fu! flogmenu#git_ignore_errors(command) abort
  let l:cmd = 'git ' . a:command
  let l:out = system(l:cmd)
  return substitute(out, '\c\C\n$', '', '')
endfunction

fu! flogmenu#git(command) abort
  let l:output = flogmenu#git_ignore_errors(a:command)
  if v:shell_error
    throw 'git ' . a:command . ' failed with: ' . l:output
  endif
  return l:output
endfunction

fu! flogmenu#git_then_update(command) abort
  let git_output = flogmenu#git(a:command)
  call flog#populate_graph_buffer()
  return l:git_output
endfunction

" Gets the references attached to the commit on the selected line
fu! flogmenu#get_refs(commit) abort
  if type(a:commit) != v:t_dict
    throw g:flogmenu_commit_parse_error
  endif

  " TODO replace until next marker with this after flog PR#48 is approved
  " TODO fix the bug in this flog code; local branches named remote/anything
  " are considered as remote branches on the remote
  " let [l:local_branches, l:remote_branches, l:tags, l:special] = flog#parse_ref_name_list(a:commit)
  let l:local_branches = []
  let l:remote_branches = []
  let l:special = []
  let l:tags = []
  if !empty(a:commit.ref_name_list)
    let l:refs = a:commit.ref_name_list
    let l:original_refs = split(a:commit.ref_names_unwrapped, ' \ze-> \|, \|\zetag: ')
    let l:i = 0
    while l:i < len(l:refs)
      let l:ref = l:refs[l:i]
      if l:ref =~# 'HEAD$\|^refs/'
        call add(l:special, l:ref)
      elseif l:original_refs[l:i] =~# '^tag: '
        call add(l:tags, l:ref)
      elseif flog#is_remote_ref(l:ref)
        call add(l:remote_branches, l:ref)
      else
        call add(l:local_branches, l:ref)
      endif
      let l:i += 1
    endwhile
  endif
  " end TODO replacement

  let l:unmatched_remote_branches = filter(copy(l:remote_branches), "index(l:local_branches, substitute(v:val, '^[^/]*/', '', '')) < 0")
  let l:current_branch = flogmenu#git('rev-parse --abbrev-ref HEAD')
  let l:other_local_branches = filter(copy(l:local_branches), 'l:current_branch != v:val')
  return {
     \ 'current_branch': l:current_branch,
     \ 'local_branches': l:local_branches,
     \ 'other_local_branches': l:other_local_branches,
     \ 'remote_branches': l:remote_branches,
     \ 'unmatched_remote_branches': l:unmatched_remote_branches,
     \ 'tags': l:tags,
     \ 'special': l:special
     \ }
endfunction

" this should be done once per interaction,
" so the result needs to be stored for submenus to
" access. The _fromcache functions are thus meant
" for in menu options, while the version without
" will call this first to set the global g:flogmenu_selection_info
fu! flogmenu#set_selection_info() abort
  let l:commit = flog#get_commit_at_line()
  let g:flogmenu_normalmode_cursorinfo = flogmenu#get_refs(l:commit)
  let g:flogmenu_normalmode_cursorinfo['selected_commit'] = l:commit
  let l:current_commit = flogmenu#git('rev-parse HEAD')
  let l:full_commit_hash = fugitive#RevParse(l:commit.short_commit_hash)
  let g:flogmenu_normalmode_cursorinfo['selected_commit_hash'] = l:full_commit_hash
  let g:flogmenu_normalmode_cursorinfo['different_commit'] = l:current_commit != l:full_commit_hash
endfunction

fu! flogmenu#set_visual_selection_info() abort
  let [l:first, l:second] = flog#get_commit_selection()
  let g:flogmenu_visual_selection_info['first'] = fugitive#RevParse(l:first.short_commit_hash)
  let g:flogmenu_visual_selection_info['second'] = fugitive#RevParse(l:second.short_commit_hash)
endfunction

fu! flogmenu#create_branch_menu() abort
  call flogmenu#set_selection_info()
  call flogmenu#create_branch_menu_fromcache()
endfunction

fu! flogmenu#create_given_branch_fromcache(branchname) abort
  call inputsave()
  let l:wants_to_switch = input('Switch to the branch? (y)es / (n)o ')
  call inputrestore()
  call flogmenu#create_given_branch_and_switch_fromcache(a:branchname, l:wants_to_switch ==# 'y')
endfunction

fu! flogmenu#is_remote(remotename) abort
  " TODO replace grep with vimscript direct search of remote -v output
  call flogmenu#git_ignore_errors('remote -v | (while read line; do echo $line | { read first rest; echo $first; }; done) | grep "^' . a:remotename . '$"')
  return v:shell_error == 0
endfunction

fu! flogmenu#create_given_branch_and_switch_fromcache(branchname, switch_to_branch) abort
  let l:branch = a:branchname
  let l:track_remote = v:false
  if a:branchname =~# '.*/.*'
    let l:remote = substitute(a:branchname, '/.*', '', '')
    if flogmenu#is_remote(l:remote)
      let l:track_remote = v:true
      let l:branch = substitute(a:branchname, '^[^/]*/', '', '')
    endif
  endif
  if a:switch_to_branch
    call flogmenu#git('checkout -B ' . l:branch . ' ' . g:flogmenu_normalmode_cursorinfo.selected_commit_hash)
    " TODO check if local branch of same name has commits not in this commit
  else
    call flogmenu#git('branch ' . l:branch . ' ' . g:flogmenu_normalmode_cursorinfo.selected_commit_hash)
  endif
  if l:track_remote
    let l:command = 'branch --set-upstream-to ' . l:remote . ' ' . l:branch
    call flogmenu#git(l:command)
  endif
  call flog#populate_graph_buffer()
endfunction

fu! flogmenu#create_input_branch_fromcache() abort
  call inputsave()
  let l:branchname = input('Branch: ')
  call inputrestore()
  call flogmenu#create_given_branch_fromcache(l:branchname)
endfunction

fu! flogmenu#create_branch_menu_fromcache() abort
  let l:branch_menu = []
  for l:unmatched_branch in g:flogmenu_normalmode_cursorinfo.unmatched_remote_branches
    call add(l:branch_menu, [l:unmatched_branch,
          \ 'call flogmenu#create_given_branch_fromcache("' . l:unmatched_branch . '")'])
  endfor
  call add(l:branch_menu, ['-custom', 'call flogmenu#create_input_branch_fromcache()'])
  call flogmenu#open_menu(l:branch_menu)
endfunction

fu! flogmenu#create_branch_menu() abort
  call flogmenu#set_selection_info()
  call flogmenu#create_branch_menu_fromcache()
endfunction

" Returns 1 if the user chose to abort, otherwise 0
fu! flogmenu#handle_unstaged_changes() abort
  call flogmenu#git_ignore_errors('update-index --refresh')
  call flogmenu#git_ignore_errors('diff-index --quiet HEAD --')
  let l:has_unstaged_changes = v:shell_error != 0
  if l:has_unstaged_changes
    call inputsave()
    let l:unstaged_info = flogmenu#git('diff --stat')
    let l:choice = input("Unstaged changes: \n" . l:unstaged_info . "\n> (a)bort / (d)iscard / (s)tash ")
    call inputrestore()
    if l:choice ==# 'd'
      call system('git checkout -- .') " TODO this doesn't work - need to throw away unstaged changes
    elseif l:choice ==# 's'
      call flogmenu#git('stash')
    else " All invalid input also means abort
      return 1
    endif
  endif
  return 0
endfunction

fu! flogmenu#checkout() abort
  call flogmenu#set_selection_info()
  call flogmenu#checkout_fromcache()
endfunction

fu! flogmenu#checkout_fromcache() abort
  " Are we moving to a different commit? If so, check the git status is clean
  if g:flogmenu_normalmode_cursorinfo.different_commit
    if flogmenu#handle_unstaged_changes() == 1
      return
    endif
  endif
  let l:branch_menu = []
  " If there are other local branches, these are the most likely choices
  " so they come first
  for l:local_branch in g:flogmenu_normalmode_cursorinfo.other_local_branches
    call add(l:branch_menu, [l:local_branch, 'call flogmenu#git_then_update("checkout ' . l:local_branch . '")'])
  endfor
  " Next, offer the choices to create branches for unmatched remote branches
  for l:unmatched_branch in g:flogmenu_normalmode_cursorinfo.unmatched_remote_branches
    call add(l:branch_menu, [l:unmatched_branch,
          \ 'call flogmenu#create_given_branch_and_switch_fromcache("' . l:unmatched_branch . '", v:true)'])
  endfor
  " Finally, choices to make new branch or none at all
  call add(l:branch_menu, ['-create branch', 'call flogmenu#create_branch_menu_fromcache()'])
  call add(l:branch_menu, ['-detached HEAD', 'call flogmenu#git_then_update("checkout " . g:flogmenu_selection_info.selected_commit_hash)'])
  call flogmenu#open_menu(l:branch_menu)
endfunction

fu! flogmenu#rebase_fromcache() abort
  let l:target = g:flogmenu_normalmode_cursorinfo.selected_commit_hash
  execute 'Git rebase ' . l:target . ' --interactive --autosquash'
endfunction

fu! flogmenu#rebase() abort
  call flogmenu#set_selection_info()
  call flogmenu#rebase_fromcache()
endfunction

fu! flogmenu#reset_hard() abort
  call flog#run_command('Git reset --hard %h', 0, 1)
endfunction

fu! flogmenu#reset_mixed() abort
  call flog#run_command('Git reset --mixed %h', 0, 1)
endfunction

fu! flogmenu#cherrypick() abort
  call flog#run_command('Git cherry-pick %h', 0, 1)
endfunction

fu! flogmenu#revert() abort
  call flog#run_command('Git revert %h', 0, 1)
endfunction

fu! flogmenu#merge_fromcache() abort
  " check the git status is clean
  if flogmenu#handle_unstaged_changes() == 1
    return
  endif
  let l:merge_choices = []
  for l:local_branch in g:flogmenu_normalmode_cursorinfo.other_local_branches + g:flogmenu_normalmode_cursorinfo.unmatched_remote_branches
    call add(l:merge_choices, [l:local_branch, 'call flog#run_command("Git merge ' . l:local_branch . '", 0, 1)'])
  endfor
  if len(l:merge_choices) == 1
    execute l:merge_choices[0][1]
  else
    call flogmenu#open_menu(l:merge_choices)
  endif
endfunction

fu! flogmenu#delete_current_branch_fromcache() abort
  call flogmenu#git('checkout --detach')
  call flogmenu#delete_other_branch_fromcache(g:flogmenu_normalmode_cursorinfo.current_branch)
endfunction

fu! flogmenu#delete_current_branch() abort
  call flogmenu#set_selection_info()
  call flogmenu#delete_branch_fromcache()
endfunction

fu! flogmenu#delete_other_branch_fromcache(branch) abort
  let remote_tracking_branch = flogmenu#git_ignore_errors('rev-parse --abbrev-ref ' . a:branch . '@{upstream}')
  if v:shell_error
    let l:remote_tracking_branch = v:null
  endif
  call flogmenu#git('branch -D "' . a:branch . '"')
  if l:remote_tracking_branch != v:null
    call inputsave()
    let l:delete_remote = input('Delete remote branch ' . l:remote_tracking_branch . ' as well? (y)es / (n)o ')
    call inputrestore()
    if l:delete_remote ==# 'y'
      call flogmenu#delete_remote_branch(l:remote_tracking_branch)
    endif
  endif
  call flog#populate_graph_buffer()
endfunction

fu! flogmenu#delete_remote_branch(remote_branch) abort
  call flogmenu#git_then_update('push ' . substitute(a:remote_branch, '/', ' --delete ', ''))
endfunction

fu! flogmenu#delete_branch_fromcache() abort
  let l:branch_menu = []
  if index(g:flogmenu_normalmode_cursorinfo.local_branches, g:flogmenu_normalmode_cursorinfo.current_branch) != -1
    call add(l:branch_menu, [g:flogmenu_normalmode_cursorinfo.current_branch, 'call flogmenu#delete_current_branch_fromcache()'])
  endif
  for l:local_branch in g:flogmenu_normalmode_cursorinfo.other_local_branches
    call add(l:branch_menu, [l:local_branch, 'call flogmenu#delete_other_branch_fromcache("' . l:local_branch . '")'])
  endfor
  for l:remote_branch in g:flogmenu_normalmode_cursorinfo.remote_branches
    call add(l:branch_menu, [l:remote_branch, 'call flogmenu#delete_remote_branch("' . l:remote_branch . '")'])
  endfor
  " TODO remote branches
  call flogmenu#open_menu(l:branch_menu)
endfunction

fu! flogmenu#fixup_fromcache() abort
  " TODO if no staged changes, ask whether to stage all
  execute 'Git commit --fixup=' . g:flogmenu_normalmode_cursorinfo.selected_commit_hash
endfunction

fu! flogmenu#fixup() abort
  call flogmenu#set_selection_info()
  call flogmenu#fixup_fromcache()
endfunction

fu! flogmenu#amend_commit_fromcache() abort
  call flogmenu#fixup_fromcache()
  execute 'Git rebase --autosquash ' . g:flogmenu_normalmode_cursorinfo.selected_commit_hash . '~1'
endfunction

fu! flogmenu#amend_commit() abort
  call flogmenu#set_selection_info()
  call flogmenu#amend_commit_fromcache()
endfunction

fu! flogmenu#open_main_contextmenu() abort
  call flogmenu#set_selection_info()
  " Note; all menu items should refer to _fromcache variants,
  " whereas all direct bindings refer to the regular variant
  " this ensures that set_selection_info is called once, even if
  " the user traverses several menu's
  let l:flogmenu_main_menu = [
                           \ ['&Checkout', 'call flogmenu#checkout_fromcache()'],
                           \ ['&Merge', 'call flogmenu#merge_fromcache()'],
                           \ ['Reset &index', 'call flogmenu#reset_mixed()'],
                           \ ['Reset --&hard', 'call flogmenu#reset_hard()'],
                           \ ['Cherry&pick', 'call flogmenu#cherrypick()'],
                           \ ['Re&vert', 'call flogmenu#revert()'],
                           \ ['Create &branch', 'call flogmenu#create_branch_menu_fromcache()'],
                           \ ['&Rebase', 'call flogmenu#rebase_fromcache()'],
                           \ ['&Fixup', 'call flogmenu#fixup_fromcache()'],
                           \ ['&Amend', 'call flogmenu#amend_commit_fromcache()'],
                           \ ['Si&gnifyThis', 'call flogmenu#signify_this()'],
                           \ ]
  let l:branches = len(g:flogmenu_normalmode_cursorinfo.local_branches) + len(g:flogmenu_normalmode_cursorinfo.remote_branches)
  if l:branches > 0
    call add(l:flogmenu_main_menu, ['&Delete branch', 'call flogmenu#delete_branch_fromcache()'])
  endif
  call flogmenu#open_menu(l:flogmenu_main_menu)
endfunction

fu! flogmenu#open_visual_contextmenu() abort
  call flogmenu#set_visual_selection_info()
  let l:flogmenu_visual_menu = [
                           \ ['&Search', 'call flogmenu#search_visual_selection_fromcache()'],
                           \ ]
  call flogmenu#open_menu(l:flogmenu_visual_menu)
endfunction

fu! flogmenu#search_visual_selection_fromcache() abort
  let l:youngest_commit = g:flogmenu_visual_selection_info['first']
  let l:oldest_commit = g:flogmenu_visual_selection_info['second']
  call fzf#run(fzf#wrap({'source': 'git grep --line-number -- '.shellescape('').' $(git rev-list '.l:oldest_commit.'^..'.l:youngest_commit.')', 'sink': function('flogmenu#open_git_ref')}), 0)
endfunction

fu! flogmenu#open_git_log() abort
  execute ':Flog -all'
  execute ':Flogjump HEAD'
  execute 'normal! zz'
endfunction

fu! flogmenu#open_all_windows() abort
  call flogmenu#open_git_log()
  execute ':Twiggy'
  execute ':Gstatus'
endfunction

" Signify other commits:
fu! flogmenu#set_signify_target(target_commit) abort
  let g:signify_vcs_cmds['git'] = 'git diff --no-color --no-ext-diff -U0 ' . a:target_commit . ' -- %f'
  echom 'Now diffing against ' . a:target_commit
endfunction

fu! flogmenu#signify_this() abort
  call flogmenu#set_signify_target(g:flogmenu_normalmode_cursorinfo['selected_commit_hash'])
endfunction

" The following functions have nothing to do with flog
" they are just general git operations which I want in the git menu

fu! flogmenu#open_unmerged()
  execute 'args ' . system("git ls-files --unmerged | cut -f2 | sort -u | sed -r 's/ /\\\\ /g' | paste -sd ' ' -")
endfunction

