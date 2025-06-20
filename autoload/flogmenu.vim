
function flogmenu#open_git_ref_file(reference) abort
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
  let l:cmd = flog#fugitive#GetGitCommand() . ' ' . a:command
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

fu! flogmenu#git_then_update_if_clean(command) abort
  if flogmenu#ensure_git_status_is_clean()
    call flogmenu#git_then_update(a:command)
  endif
endfunction

fu! flogmenu#git_then_update(command) abort
  let git_output = flogmenu#git(a:command)
  call flog#floggraph#buf#Update()
  return l:git_output
endfunction

" When your pwd is outside of the repo, you need this
" to run commands like diff, which look at the worktree
fu! flogmenu#git_worktree_command(command) abort
  " still works if you have a bare repo with several worktrees checked out
  let l:worktree_dir = systemlist('cd ' . expand('%:p:h') . ' && git rev-parse --show-toplevel')[0]
  " Get the modified files in a list
  let l:full_command = FugitiveShellCommand() . ' --work-tree ' . l:worktree_dir . ' ' . a:command
  let l:output = systemlist(l:full_command)
  if v:shell_error
    throw 'git ' . a:command . ' failed with: ' . l:output
  endif
  return l:output
endfunction

" Gets the references attached to the commit on the selected line
" example input:
" {'len': 1, 'hash': '5aa0068', 'col': 1, 'suffix_len': 0, 'subject': '• 2023-06-09 [5aa0068] {Tama McGlinn} (HEAD -> master, origin/master) fix git commands when outside cwd',
"  'line': 1, 'refs': 'HEAD -> master, origin/master', 'format_col': 3, 'suffix': [], 'body': [], 'parents': ['2718301']}
fu! flogmenu#get_flog_refs(commit) abort
  if type(a:commit) != v:t_dict
    throw g:flogmenu_commit_parse_error
  endif

  let refs = flog#state#GetCommitRefs(a:commit)
  " example of refs:
  " [{'tag': 0, 'full': 'master', 'path': 'master', 'tail': 'master', 'remote': '', 'orig': 'HEAD', 'prefix': ''},
  " {'tag': 0, 'full': 'origin/master', 'path': 'origin/master', 'tail': 'master', 'remote': 'origin', 'orig': '', 'prefix': ''}]
  let l:local_branches = map(filter(copy(l:refs), 'v:val["remote"] == ""'), 'v:val.full')
  let l:remote_branches = map(filter(copy(l:refs), 'v:val["remote"] != ""'), 'v:val.full')
  let l:special = map(filter(copy(l:refs), 'v:val["orig"] != ""'), 'v:val.orig')
  let l:tags = map(filter(copy(l:refs), 'v:val["tag"] == 1'), 'v:val.full')

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
" will call this first to set the global g:flogmenu_normalmode_cursorinfo
fu! flogmenu#set_selection_info() abort
  if &filetype is# 'instaflog'
    let l:commit = instaflog#get_commit_at_line()
    let l:refs = flogmenu#get_instaflog_refs()
  elseif &filetype is# 'floggraph'
    let l:commit = flog#floggraph#commit#GetAtLine()
    let l:refs = flogmenu#get_flog_refs(l:commit)
  else
    throw 'Unsupported filetype ' . &filetype
  endif
  let g:flogmenu_normalmode_cursorinfo = l:refs
  let g:flogmenu_normalmode_cursorinfo['selected_commit'] = l:commit
  let l:current_commit = flogmenu#git('rev-parse HEAD')
  let l:full_commit_hash = flogmenu#git('rev-parse ' . l:commit.hash)
  let g:flogmenu_normalmode_cursorinfo['selected_commit_hash'] = l:full_commit_hash
  let g:flogmenu_normalmode_cursorinfo['different_commit'] = l:current_commit != l:full_commit_hash
endfunction

fu! flogmenu#get_instaflog_refs() abort
  return {
     \ 'current_branch': '',
     \ 'local_branches': [],
     \ 'other_local_branches': [],
     \ 'remote_branches': [],
     \ 'unmatched_remote_branches': [],
     \ 'tags': [],
     \ 'special': []
     \ }
endfunction

fu! flogmenu#set_visual_selection_info() abort
  let l:first = flog#floggraph#commit#GetAtLine(line("'<"))
  let l:second = flog#floggraph#commit#GetAtLine(line("'>"))
  let g:flogmenu_visual_selection_info['first'] = fugitive#RevParse(l:first.hash)
  let g:flogmenu_visual_selection_info['second'] = fugitive#RevParse(l:second.hash)
endfunction

fu! flogmenu#create_branch_menu() abort
  call flogmenu#set_selection_info()
  call flogmenu#create_branch_menu_fromcache()
endfunction

fu! flogmenu#input(message) abort
  call inputsave()
  let l:result = input(a:message)
  call inputrestore()
  return l:result
endfunction

fu! flogmenu#create_given_branch_fromcache(branchname) abort
  let l:wants_to_switch = flogmenu#input('Switch to the branch? (y)es / (n)o ')
  echom " "
  call flogmenu#create_given_branch_and_switch_fromcache(a:branchname, l:wants_to_switch ==# 'y')
endfunction

fu! flogmenu#is_remote(remotename) abort
  let l:remote_v_output = split(flogmenu#git('remote -v'), '\n')
  for l:line in l:remote_v_output
    let l:remote_name = split(l:line)[0]
    if l:remote_name == a:remotename
      return v:true
    endif
  endfor
  return v:false
endfunction

fu! flogmenu#force_checkout(branch, commit) abort
  call flogmenu#git('checkout -B ' . a:branch . ' ' . a:commit)
endfunction

" Check if we can safely move branch to point at commit; returns an empty list
" if and only if, either:
"  - commit contains branch (fast-forwarding), or
"  - remote/branch contains branch (server still has a copy)
" otherwise, returns a list of one-line commit summaries
" for each commit
"   which is in branch but is neither in commit, nor in origin/branch
fu! flogmenu#get_changes_discarded_by_moving_branch(branch, remote, commit) abort
  " echo "Checking " . a:branch . " at remote " . a:remote . " compared to commit " . a:commit
  " Check if branch currently points at some ancestor of the target, which
  " means we're just updating the branch which is always fine
  call flogmenu#git_ignore_errors('merge-base --is-ancestor ' . a:branch . ' ' . a:commit)
  if !v:shell_error
    return []
  endif

  let l:common_base = flogmenu#git_ignore_errors('merge-base ' . a:commit . ' ' . a:branch) . ".."
  if v:shell_error
    " there is no common commit, so all changes on that branch are at risk
    let l:common_base = ""
  endif
  " Check if the remote contains the changes, in which case
  " we are also not throwing away any changes
  if a:remote !=# ''
    call flogmenu#git_ignore_errors('merge-base --is-ancestor ' . a:branch . ' ' . a:remote . '/' . a:branch)
    if !v:shell_error
      return []
    endif
    let l:remote_branch_base = flogmenu#git('merge-base ' . a:remote . '/' . a:branch . ' ' . a:branch)
    if l:common_base !=# ''
      " Check if the remote-branch base contains all that is in
      " the base between the commit and the branch, in which case we replace it
      call flogmenu#git_ignore_errors('merge-base --is-ancestor ' . l:common_base . ' ' . l:remote_branch_base)
      if !v:shell_error
        " to correctly ignore the changes after the common base
        " but before remote/branch branced off from branch, we
        " set the common base to the common parent (base)
        " of remote/branch and branch
        let l:common_base = l:remote_branch_base
      endif
    endif
  endif
  return systemlist("git log --pretty=format:'%h %s' " . l:common_base . a:branch)
endfunction

fu! flogmenu#create_given_branch_and_switch_fromcache(branchname, switch_to_branch) abort
  if a:switch_to_branch
    if !flogmenu#ensure_git_status_is_clean()
      return
    endif
  endif

  let l:branch = a:branchname
  let l:track_remote = v:false
  let l:remote = ''
  if a:branchname =~# '.*/.*'
    let l:remote = substitute(a:branchname, '/.*', '', '')
    if flogmenu#is_remote(l:remote)
      let l:track_remote = v:true
      let l:branch = substitute(a:branchname, '^[^/]*/', '', '')
    else
      let l:remote = ''
    endif
  endif

  let l:commit = g:flogmenu_normalmode_cursorinfo.selected_commit_hash

  " define how to create_branch
  if a:switch_to_branch
    let l:Create_branch = {-> flogmenu#force_checkout(l:branch, l:commit)}
  else
    let l:Create_branch = {-> flogmenu#git_then_update('branch ' . l:branch . ' ' . g:flogmenu_normalmode_cursorinfo.selected_commit_hash)}
  endif

  " define how to discard
  if a:switch_to_branch
    let l:Discard = {-> ';'} " no-op
  else
    let l:Discard = {-> flogmenu#git('branch -D ' . l:branch)}
  endif

  call flogmenu#git_ignore_errors('rev-parse --quiet --verify ' . l:branch)
  if v:shell_error
    " if the branch doesn't exist yet we can proceed
    call l:Create_branch()
  else
    " check what is discarded if we move branch
    let l:discarding_commits = flogmenu#get_changes_discarded_by_moving_branch(l:branch, l:remote, l:commit)
    if len(l:discarding_commits) > 0
      echom l:branch . " contains changes that will be discarded by switching:"
      for l:discarded_commit in l:discarding_commits
        echom l:discarded_commit
      endfor
      let l:choice = flogmenu#input("> (a)bort / (d)iscard\n")
      if l:choice ==# 'd'
        " if users chooses to discard, go ahead
        call l:Discard()
        call l:Create_branch()
      else " All invalid input also means abort
        return 1
      endif
    else
      " if nothing would be discarded by moving, go ahead without prompt
      call l:Discard()
      call l:Create_branch()
    endif
  endif

  if l:track_remote
    let l:command = 'branch --set-upstream-to ' . l:remote . '/' . l:branch . ' ' . l:branch
    call flogmenu#git(l:command)
  endif
  call flog#floggraph#buf#Update()
endfunction

fu! flogmenu#create_input_branch_fromcache() abort
  let l:branchname = flogmenu#input('Branch: ')
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

fu! flogmenu#rename_branch_fromcache() abort
  let l:new_branch_name = flogmenu#input('New branch name: ')
  call flogmenu#git_then_update('branch -m ' . l:new_branch_name)
endfunction

fu! flogmenu#rename_branch() abort
  call flogmenu#set_selection_info()
  call flogmenu#rename_branch_fromcache()
endfunction

" Returns 1 if the user chose to abort, otherwise 0
fu! flogmenu#handle_unstaged_changes() abort
  call flogmenu#git_ignore_errors('update-index --refresh')
  call flogmenu#git_ignore_errors('diff-index --quiet HEAD --')
  let l:has_unstaged_changes = v:shell_error != 0
  if l:has_unstaged_changes
    let l:unstaged_info = flogmenu#git('diff --stat')
    let l:choice = flogmenu#input("Unstaged changes: \n" . l:unstaged_info . "\n> (a)bort / (d)iscard / (s)tash ")
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

" Check if git status is clean; if so, return true
" if not, ask the user if they want to discard or stash those changes,
" if so, do it and return true.
" If not, the user chose to abort and this returns false
fu! flogmenu#ensure_git_status_is_clean() abort
  " Are we moving to a different commit? If so, check the git status is clean
  if g:flogmenu_normalmode_cursorinfo.different_commit
    if flogmenu#handle_unstaged_changes() == 1
      return v:false
    endif
  endif
  return v:true
endfunction

fu! flogmenu#checkout_fromcache() abort
  let l:branch_menu = []
  " If there are other local branches, these are the most likely choices
  " so they come first
  for l:local_branch in g:flogmenu_normalmode_cursorinfo.other_local_branches
    call add(l:branch_menu, [l:local_branch, 'call flogmenu#git_then_update_if_clean("checkout ' . l:local_branch . '")'])
  endfor
  " Next, offer the choices to create branches for unmatched remote branches
  for l:unmatched_branch in g:flogmenu_normalmode_cursorinfo.unmatched_remote_branches
    call add(l:branch_menu, [l:unmatched_branch,
          \ 'call flogmenu#create_given_branch_and_switch_fromcache("' . l:unmatched_branch . '", v:true)'])
  endfor
  " Finally, choices to make new branch or none at all
  call add(l:branch_menu, ['-create branch', 'call flogmenu#create_branch_menu_fromcache()'])
  call add(l:branch_menu, ['-detached HEAD', 'call flogmenu#git_then_update_if_clean("checkout " . g:flogmenu_normalmode_cursorinfo.selected_commit_hash)'])
  call flogmenu#open_menu(l:branch_menu)
endfunction

fu! flogmenu#rebase_fromcache() abort
  let l:target = g:flogmenu_normalmode_cursorinfo.selected_commit_hash
  if flogmenu#ensure_git_status_is_clean()
    execute 'Git rebase ' . l:target . ' --interactive --autosquash'
  endif
endfunction

fu! flogmenu#rebase() abort
  call flogmenu#set_selection_info()
  call flogmenu#rebase_fromcache()
endfunction

fu! flogmenu#reset_hard() abort
  call flog#ExecTmp('Git reset --hard ' . flog#Format('%h'))
endfunction

fu! flogmenu#reset_mixed() abort
  call flog#ExecTmp('Git reset --mixed ' . flog#Format('%h'))
endfunction

fu! flogmenu#cherrypick() abort
  call flog#ExecTmp('Git cherry-pick ' . flog#Format('%h'))
endfunction

fu! flogmenu#revert() abort
  call flog#ExecTmp('Git revert ' . flog#Format('%h'))
endfunction

fu! flogmenu#merge_fromcache() abort
  " check the git status is clean
  if flogmenu#handle_unstaged_changes() == 1
    return
  endif
  let l:merge_choices = []
  for l:local_branch in g:flogmenu_normalmode_cursorinfo.other_local_branches + g:flogmenu_normalmode_cursorinfo.unmatched_remote_branches
    call add(l:merge_choices, [l:local_branch, 'call flog#Exec("Git merge --no-ff ' . l:local_branch . '")'])
  endfor
  if len(l:merge_choices) == 1
    execute l:merge_choices[0][1]
  else
    call flogmenu#open_menu(l:merge_choices)
  endif
endfunction

fu! flogmenu#delete_current_branch_fromcache() abort
  call flogmenu#git('checkout --detach')
  call flogmenu#git_then_update('branch -D ' . g:flogmenu_normalmode_cursorinfo.current_branch)
endfunction

fu! flogmenu#delete_current_branch() abort
  call flogmenu#set_selection_info()
  call flogmenu#delete_current_branch_fromcache()
endfunction

fu! flogmenu#delete_other_branch_fromcache(branch) abort
  let remote_tracking_branch = flogmenu#git_ignore_errors('rev-parse --abbrev-ref ' . a:branch . '@{upstream}')
  if v:shell_error
    let l:remote_tracking_branch = v:null
  endif
  call flogmenu#git('branch -D "' . a:branch . '"')
  if l:remote_tracking_branch != v:null
    let l:delete_remote = flogmenu#input('Delete remote branch ' . l:remote_tracking_branch . ' as well? (y)es / (n)o ')
    if l:delete_remote ==# 'y'
      call flogmenu#delete_remote_branch(l:remote_tracking_branch)
    endif
  endif
  call flog#floggraph#buf#Update()
endfunction

fu! flogmenu#delete_remote_branch(remote_branch) abort
  call flogmenu#git_then_update('push ' . substitute(a:remote_branch, '/', ' --delete ', ''))
endfunction

fu! flogmenu#delete_branch_fromcache() abort
  let l:branch_menu = []
  for l:local_branch in g:flogmenu_normalmode_cursorinfo.other_local_branches
    call add(l:branch_menu, [l:local_branch, 'call flogmenu#delete_other_branch_fromcache("' . l:local_branch . '")'])
  endfor
  for l:remote_branch in g:flogmenu_normalmode_cursorinfo.remote_branches
    call add(l:branch_menu, [l:remote_branch, 'call flogmenu#delete_remote_branch("' . l:remote_branch . '")'])
  endfor
  if index(g:flogmenu_normalmode_cursorinfo.local_branches, g:flogmenu_normalmode_cursorinfo.current_branch) != -1
    call add(l:branch_menu, [g:flogmenu_normalmode_cursorinfo.current_branch, 'call flogmenu#delete_current_branch_fromcache()'])
  endif
  call flogmenu#open_menu(l:branch_menu)
endfunction

fu! flogmenu#delete_branch() abort
  call flogmenu#set_selection_info()
  call flogmenu#delete_branch_fromcache()
endfunction

fu! flogmenu#check_staged(staging_is_essential) abort
  let l:staged_files = split(flogmenu#git('diff --staged --name-only'), '\n')
  if len(l:staged_files) == 0
    let l:unstaged_info = flogmenu#git('diff --stat')
    let l:choice = flogmenu#input("Nothing staged!\nUnstaged changes: \n" . l:unstaged_info . "\nStage everything above? (y)es / (n)o ")
    if l:choice ==# 'y'
      call flogmenu#git('add .')
    elseif a:staging_is_essential
      throw "Nothing staged!"
    endif
  endif
endfunction

fu! flogmenu#fixup_fromcache() abort
  call flogmenu#check_staged(v:true)
  execute 'Git commit --fixup=' . g:flogmenu_normalmode_cursorinfo.selected_commit_hash
  let l:choice = flogmenu#input("Rebase now? (y)es / (n)o ")
  if l:choice ==# 'y'
    execute 'Floggit rebase --interactive --autosquash ' . g:flogmenu_normalmode_cursorinfo.selected_commit_hash . '^'
  endif
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

fu! flogmenu#stat() abort
  call flogmenu#set_selection_info()
  call flogmenu#stat_fromcache()
endfunction

fu! flogmenu#stat_fromcache() abort
  let l:full_stat = split(flogmenu#git('show --stat --oneline'), '\n')
  let l:contents = l:full_stat[1:len(l:full_stat)-2]
  for l:line in l:contents
    echom l:line
  endfor
endfunction

" I keep all the menu options in here to ensure that I don't double bind
" something; the dictionary will fail immediately then
let g:flogmenu_unused_dict = {'j': 'down',
                    \'k': 'up',
                    \'m': 'merge',
                    \'i': 'index',
                    \'h': 'hard',
                    \'n': 'rename',
                    \'p': 'cherrypick',
                    \'v': 'revert',
                    \'b': 'branch',
                    \'r': 'rebase',
                    \'f': 'fixup',
                    \'a': 'amend',
                    \'s': 'stat',
                    \'c': 'compare',
                    \'w': 'browse',
                    \'d': 'delete'}

fu! flogmenu#open_main_contextmenu() abort
  call flogmenu#set_selection_info()
  " Note; all menu items should refer to _fromcache variants,
  " whereas all direct bindings refer to the regular variant
  " this ensures that set_selection_info is called once, even if
  " the user traverses several menu's
  let l:flogmenu_main_menu = [
                           \ ['↯  Checkout', 'call flogmenu#checkout_fromcache()'],
                           \ ['-'],
                           \ ['ᛘ  &Branch', 'call flogmenu#create_branch_menu_fromcache()'],
                           \ ['𝀝  Re&name branch', 'call flogmenu#rename_branch_fromcache()'],
                           \ ['ᛦ  &Merge', 'call flogmenu#merge_fromcache()'],
                           \ ['-'],
                           \ ['⇠  Reset &index', 'call flogmenu#reset_mixed()'],
                           \ ['←  Reset --&hard', 'call flogmenu#reset_hard()'],
                           \ ['-'],
                           \ ['✓  Cherry&pick', 'call flogmenu#cherrypick()'],
                           \ ['✗  Re&vert', 'call flogmenu#revert()'],
                           \ ['-'],
                           \ ['↷  &Rebase', 'call flogmenu#rebase_fromcache()'],
                           \ ['↺  &Fixup', 'call flogmenu#fixup_fromcache()'],
                           \ ['✒  &Amend', 'call flogmenu#amend_commit_fromcache()'],
                           \ ['-'],
                           \ ['ⅈ  &Stat', 'call flogmenu#stat_fromcache()'],
                           \ ['⇄  &Compare', 'call flogmenu#compare()'],
                           \ ['☸  &Web browser', 'call flog#Exec(flog#Format("GBrowse %h"))'],
                           \ ]
  let l:branches = len(g:flogmenu_normalmode_cursorinfo.local_branches) + len(g:flogmenu_normalmode_cursorinfo.remote_branches)
  if l:branches > 0
    call add(l:flogmenu_main_menu, ['-'])
    call add(l:flogmenu_main_menu, ['☠ &Delete branch', 'call flogmenu#delete_branch_fromcache()'])
  endif
  call flogmenu#open_menu(l:flogmenu_main_menu)
endfunction

fu! flogmenu#open_visual_contextmenu() abort
  call flogmenu#set_visual_selection_info()
  let l:flogmenu_visual_menu = [
                           \ ['🔍 &Search diffs', 'call flogmenu#search_visual_selection_diffs_fromcache()'],
                           \ ['🗂  Search &file contents', 'call flogmenu#search_visual_selection_fromcache()'],
                           \ ['⇊  Jump to common &parent', 'call flogmenu#jump_to_mergebase()'],
                           \ ]
  call flogmenu#open_menu(l:flogmenu_visual_menu)
endfunction

fu! flogmenu#jump_to_mergebase() abort
  let l:one = g:flogmenu_visual_selection_info['first']
  let l:two = g:flogmenu_visual_selection_info['second']
  let l:mergebase = flogmenu#git('merge-base '.l:one.' '.l:two)
  echo l:mergebase
  call flog#floggraph#nav#JumpToCommit(l:mergebase)
endfunction

fu! flogmenu#search_visual_selection_diffs_fromcache() abort
  let l:youngest_commit = g:flogmenu_visual_selection_info['first']
  let l:oldest_commit = g:flogmenu_visual_selection_info['second']
  call fzf#run(fzf#wrap({'source': 'git log --oneline -S -- '.shellescape('').' '.l:oldest_commit.'^..'.l:youngest_commit, 'sink': function('flogmenu#open_git_ref_file')}), 0)
endfunction

fu! flogmenu#search_visual_selection_fromcache() abort
  let l:youngest_commit = g:flogmenu_visual_selection_info['first']
  let l:oldest_commit = g:flogmenu_visual_selection_info['second']
  call fzf#run(fzf#wrap({'source': 'git grep --line-number -- '.shellescape('').' $(git rev-list '.l:oldest_commit.'^..'.l:youngest_commit.')', 'sink': function('flogmenu#open_git_ref_file')}), 0)
endfunction

fu! flogmenu#open_git_log(extra_params='') abort
  execute ':Flog -all ' . a:extra_params
  call flog#floggraph#nav#JumpToCommit(systemlist(flog#fugitive#GetGitCommand() . " rev-parse HEAD")[0][0:6])
  execute 'normal! zz'
endfunction

fu! flogmenu#open_twiggy() abort
  if exists('g:loaded_twiggy')
    execute ':Twiggy'
  endif
endfunction

fu! flogmenu#open_all_windows() abort
  call flogmenu#open_git_log()
  call flogmenu#open_twiggy()
  execute ':Git'
endfunction

" Signify other commits:
fu! flogmenu#set_signify_target(target_commit) abort
  let g:flogmenu_signify_target_commit = a:target_commit
  let g:signify_vcs_cmds['git'] = 'git diff --no-color --no-ext-diff -U0 ' . a:target_commit . ' -- %f'
  let l:commit_summary = flogmenu#git_worktree_command('show --pretty="(%h) %s" --no-patch ' . a:target_commit)[0]
  call sy#util#refresh_windows()
  echom 'Signify diffing against ' . a:target_commit . " " . l:commit_summary
endfunction

fu! flogmenu#set_signify_custom() abort
  let l:input = flogmenu#input('> ')
  execute 'redraw'
  call flogmenu#set_signify_target(l:input)
endfunction

fu! flogmenu#get_older_signify_commit() abort
  return g:flogmenu_signify_target_commit . '^'
endfunction

fu! flogmenu#get_younger_signify_commit() abort
  return substitute(g:flogmenu_signify_target_commit, '\^$', '', '')
endfunction

fu! flogmenu#set_signify_older() abort
  call flogmenu#set_signify_target(flogmenu#get_older_signify_commit())
endfunction

fu! flogmenu#set_signify_younger() abort
  call flogmenu#set_signify_target(flogmenu#get_younger_signify_commit())
endfunction

fu! flogmenu#compare_older() abort 
  call flogmenu#compare_to(flogmenu#get_older_signify_commit())
endfunction

fu! flogmenu#compare_younger() abort 
  call flogmenu#compare_to(flogmenu#get_younger_signify_commit())
endfunction

fu! flogmenu#signify_this() abort
  call flogmenu#set_signify_target(g:flogmenu_normalmode_cursorinfo['selected_commit_hash'])
endfunction

fu! flogmenu#get_first_line_nr_that_differs(commit, file) abort
  " TODO make this work when not at git root dir
  let l:git_command = 'diff --unified=0 ' . a:commit . ' -- ' . a:file
  let l:diff = flogmenu#git_worktree_command(l:git_command)

  for l:line in [4, 5]
    let l:lines_changed = l:diff[l:line]
    let l:regex = '@@ -\?[^ ]* +\?\([0-9]*\),\?[0-9]* @@.*'
    let l:matches = matchlist(l:lines_changed, l:regex)
    if len(l:matches) > 1
      return max([1, l:matches[1]])
    endif
  endfor
  if len(l:matches) == 0
    echom 'Warning: flogmenu#get_first_line_nr_that_differs failed to get line number for diff'
    " for l:diff_line in l:diff
    "   echom l:diff_line
    " endfor
    return 1
  endif
endfunction

fu! flogmenu#quickfix_diffs(commit) abort
    let l:files = flogmenu#git_worktree_command('diff --name-only ' . a:commit)
    " TODO relativize the files to the pwd; they are from the git root
    " hence this doesn't work when your pwd is deeper inside the git repo

    " Create the dictionaries used to populate the quickfix list
    let l:list = []
    for l:file in l:files
        let l:line = flogmenu#get_first_line_nr_that_differs(a:commit, l:file)
        let l:dic = {'filename': l:file, "lnum": l:line}
        call add(l:list, l:dic)
    endfor

    " Populate the quickfix list
    call setqflist(l:list)
endfunction

fu! flogmenu#compare() abort
  let l:commit = g:flogmenu_normalmode_cursorinfo['selected_commit_hash']
  call flogmenu#compare_to(l:commit)
endfunction

fu! flogmenu#compare_to(commit) abort
  let l:commit_summary = flogmenu#git_worktree_command('show --pretty="(%h) %s" --no-patch ' . a:commit)[0]
  echom "Comparing to " . l:commit_summary

  try
    call flogmenu#set_signify_target(a:commit)
  catch
    echom "Note: install mhinz/vim-signify to have matching git gutter"
  endtry

  call flogmenu#quickfix_diffs(a:commit)
endfunction

" The following functions have nothing to do with flog
" they are just general git operations which I want in the git menu

fu! flogmenu#open_unmerged()
  execute 'args ' . system("git ls-files --unmerged | cut -f2 | sort -u | sed -r 's/ /\\\\ /g' | paste -sd ' ' -")
endfunction

