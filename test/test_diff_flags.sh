#!/usr/bin/env bash
# test/test_diff_flags.sh — Tests for diff command construction (no Git-specific flags).
#
# Validates:
#   - s:StageDiff() does not emit --no-ext-diff or --submodule flags
#   - s:StageDiffEdit() does not emit --no-ext-diff
#   - s:ToolStream() uses --git and --color=never instead of Git-specific flags
#   - :JJ diff from the status buffer works without errors (integration)

source "$(dirname "$0")/helpers.sh"

_bold "Diff flag tests"

# ── Unit: s:StageDiff returns no --no-ext-diff when paths are empty ─────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let StageDiff = SFunc('StageDiff')

" Simulate being in a fujjitive status buffer with cursor on an empty/heading line.
" s:StageInfo will return empty paths when not on a file line, which triggers
" the 'elseif empty(info.paths)' branch. We test the function's return value
" by creating a minimal buffer environment.

" Create a fake fujjitive buffer context
setlocal filetype=fujjitive
let b:fujjitive_type = 'index'

" Put a heading line (no file info => empty paths)
call setline(1, 'Changed files (1)')
call setline(2, 'M file.txt')
normal! 1G

let result = call(StageDiff, ['Gdiffsplit'])

if result =~# '--no-ext-diff'
  echoerr 'StageDiff should not contain --no-ext-diff, got: ' . result
  cquit 1
endif

if result =~# '--submodule'
  echoerr 'StageDiff should not contain --submodule, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "s:StageDiff does not emit --no-ext-diff for empty paths"
else fail "s:StageDiff does not emit --no-ext-diff for empty paths"
fi

# ── Unit: s:StageDiffEdit returns no --no-ext-diff ──────────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let StageDiffEdit = SFunc('StageDiffEdit')

" Create a minimal fujjitive buffer context
setlocal filetype=fujjitive
let b:fujjitive_type = 'index'

" We need a b:jj_dir for s:Tree() to work
let b:jj_dir = '/tmp/fake-repo/.jj'

call setline(1, 'Changed files (1)')
call setline(2, 'M file.txt')
normal! 2G

let result = call(StageDiffEdit, [])

if result =~# '--no-ext-diff'
  echoerr 'StageDiffEdit should not contain --no-ext-diff, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "s:StageDiffEdit does not emit --no-ext-diff"
else fail "s:StageDiffEdit does not emit --no-ext-diff"
fi

# ── Unit: StageDiff empty-paths branch returns 'JJ --paginate diff' ─────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let StageDiff = SFunc('StageDiff')

setlocal filetype=fujjitive
let b:fujjitive_type = 'index'

" Heading line => empty paths
call setline(1, 'Changed files (1)')
normal! 1G

let result = call(StageDiff, ['Gdiffsplit'])

" The result should be exactly 'JJ --paginate diff' (no extra flags)
if result !=# 'JJ --paginate diff'
  echoerr 'Expected "JJ --paginate diff", got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "s:StageDiff returns 'JJ --paginate diff' for heading lines"
else fail "s:StageDiff returns 'JJ --paginate diff' for heading lines"
fi

# ── Unit: StageDiffEdit result contains 'JJ --paginate diff' without Git flags

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let StageDiffEdit = SFunc('StageDiffEdit')

setlocal filetype=fujjitive
let b:fujjitive_type = 'index'
let b:jj_dir = '/tmp/fake-repo/.jj'

call setline(1, 'Changed files (1)')
call setline(2, 'M file.txt')
normal! 2G

let result = call(StageDiffEdit, [])

if result !~# '^JJ --paginate diff '
  echoerr 'StageDiffEdit should start with "JJ --paginate diff ", got: ' . result
  cquit 1
endif

if result =~# '--no-ext-diff\|--no-color\|--no-prefix'
  echoerr 'StageDiffEdit should not contain Git-specific flags, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "s:StageDiffEdit returns clean JJ diff command"
else fail "s:StageDiffEdit returns clean JJ diff command"
fi

# ── Unit: No --no-ext-diff anywhere in autoload/fujjitive.vim ───────────────

if run_nvim_test <<'VIMSCRIPT'
let plugin_dir = fnamemodify(findfile('autoload/fujjitive.vim', &rtp), ':p')
if empty(plugin_dir)
  echoerr 'Could not find autoload/fujjitive.vim'
  cquit 1
endif

let content = join(readfile(plugin_dir), "\n")
if content =~# '--no-ext-diff'
  echoerr 'autoload/fujjitive.vim still contains --no-ext-diff'
  cquit 1
endif
VIMSCRIPT
then pass "No --no-ext-diff in autoload/fujjitive.vim"
else fail "No --no-ext-diff in autoload/fujjitive.vim"
fi

# ── Unit: No --submodule in autoload/fujjitive.vim ──────────────────────────

if run_nvim_test <<'VIMSCRIPT'
let plugin_dir = fnamemodify(findfile('autoload/fujjitive.vim', &rtp), ':p')
if empty(plugin_dir)
  echoerr 'Could not find autoload/fujjitive.vim'
  cquit 1
endif

let content = join(readfile(plugin_dir), "\n")
if content =~# '--submodule'
  echoerr 'autoload/fujjitive.vim still contains --submodule'
  cquit 1
endif
VIMSCRIPT
then pass "No --submodule in autoload/fujjitive.vim"
else fail "No --submodule in autoload/fujjitive.vim"
fi

# ── Unit: ToolStream diff command uses --git and --color=never ───────────────

if run_nvim_test <<'VIMSCRIPT'
let plugin_dir = fnamemodify(findfile('autoload/fujjitive.vim', &rtp), ':p')
if empty(plugin_dir)
  echoerr 'Could not find autoload/fujjitive.vim'
  cquit 1
endif

let lines = readfile(plugin_dir)
let found = 0
for line in lines
  if line =~# "\\['diff', '--git', '--color=never'\\]"
    let found = 1
    break
  endif
endfor

if !found
  echoerr "ToolStream should use ['diff', '--git', '--color=never']"
  cquit 1
endif
VIMSCRIPT
then pass "ToolStream uses --git and --color=never"
else fail "ToolStream uses --git and --color=never"
fi

# ── Integration: :JJ diff works without --no-ext-diff error ─────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping integration tests"
  finish
fi

setup_jj_repo

# Make a change so there's something to diff
echo "added line" >> "$TEST_REPO/file.txt"

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
JJ diff

let content = join(getline(1, '$'), "\n")

" Should not contain error messages about --no-ext-diff
if content =~# 'unexpected argument.*--no-ext-diff'
  echoerr 'JJ diff produced --no-ext-diff error: ' . content
  cquit 1
endif

" Should contain actual diff content
if content !~# 'file\.txt'
  echoerr 'JJ diff does not reference file.txt. Content: ' . content
  cquit 1
endif
VIMSCRIPT
then pass ":JJ diff works without --no-ext-diff error"
else fail ":JJ diff works without --no-ext-diff error"
fi

cleanup

# ── Integration: dd on status heading does not error ────────────────────────

setup_jj_repo

echo "another change" >> "$TEST_REPO/file.txt"

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt

" Open the status buffer
J

" Wait for status to load
sleep 500m

" Verify we're in a fujjitive buffer
if &filetype !=# 'fujjitive'
  echoerr 'Expected filetype=fujjitive, got: ' . &filetype
  cquit 1
endif

" Move to the first line (heading) and try dd
normal! 1G

" Execute dd mapping — this should produce a :JJ diff command
" We capture messages to check for errors
redir => g:messages
silent! execute "normal dd"
redir END

" Check that no --no-ext-diff error appeared
if g:messages =~# 'unexpected argument.*--no-ext-diff'
  echoerr 'dd on heading produced --no-ext-diff error'
  cquit 1
endif
VIMSCRIPT
then pass "dd on status heading does not produce --no-ext-diff error"
else fail "dd on status heading does not produce --no-ext-diff error"
fi

cleanup

# ── Integration: dd on modified file opens diff with content on both sides ──

setup_jj_repo

# Create a parent commit with file content, then a new working copy with changes
(
  cd "$TEST_REPO"
  jj new -m "test: working copy" 2>/dev/null
  echo "modified line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt

" Open the status buffer
J

" Wait for status to load
sleep 500m

" Verify we're in a fujjitive buffer
if &filetype !=# 'fujjitive'
  echoerr 'Expected filetype=fujjitive, got: ' . &filetype
  cquit 1
endif

" Find the line with 'M file.txt' in the Changes section
let found_lnum = 0
for lnum in range(1, line('$'))
  if getline(lnum) =~# '^M file\.txt'
    let found_lnum = lnum
    break
  endif
endfor

if found_lnum == 0
  echoerr 'Could not find "M file.txt" line in status buffer. Contents: ' . join(getline(1, '$'), ' | ')
  cquit 1
endif

" Move cursor to the modified file line
execute 'normal! ' . found_lnum . 'G'

" Execute dd to open the diff split
execute "normal dd"

" Wait for buffers to load
sleep 1000m

" We should now have a diff split with two windows
if winnr('$') < 2
  echoerr 'Expected at least 2 windows for diff split, got: ' . winnr('$')
  cquit 1
endif

" Check that both windows have content (not empty buffers)
let win1_lines = line('$')
wincmd w
let win2_lines = line('$')

if win1_lines <= 1
  echoerr 'Left diff buffer appears empty (lines: ' . win1_lines . ')'
  cquit 1
endif

if win2_lines <= 1
  echoerr 'Right diff buffer appears empty (lines: ' . win2_lines . ')'
  cquit 1
endif

" Verify both windows are in diff mode
wincmd w
if !&diff
  echoerr 'First window is not in diff mode'
  cquit 1
endif
wincmd w
if !&diff
  echoerr 'Second window is not in diff mode'
  cquit 1
endif
VIMSCRIPT
then pass "dd on modified file opens diff with content on both sides"
else fail "dd on modified file opens diff with content on both sides"
fi

cleanup

# ── Integration: BufReadCmd loads blob content for commit:path URIs ─────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "test: blob loading" 2>/dev/null
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
" Get the parent commit hash
let parent_hash = trim(system('jj log --no-graph -r @- -T commit_id --limit 1'))
if empty(parent_hash)
  echoerr 'Could not get parent commit hash'
  cquit 1
endif

" Open the file at the parent revision using the fujjitive URI scheme
execute 'Gedit ' . parent_hash . ':file.txt'

" Wait for buffer to load
sleep 500m

" The buffer should have content
let content = join(getline(1, '$'), "\n")
if content !~# 'test content'
  echoerr 'Blob buffer does not contain expected content. Got: ' . content
  cquit 1
endif

" Buffer type should be blob
if get(b:, 'fujjitive_type', '') !=# 'blob'
  echoerr 'Expected b:fujjitive_type=blob, got: ' . get(b:, 'fujjitive_type', '(unset)')
  cquit 1
endif
VIMSCRIPT
then pass "BufReadCmd loads file content at parent revision"
else fail "BufReadCmd loads file content at parent revision"
fi

cleanup

# ── Integration: dd on a newly added file does not error ────────────────────

setup_jj_repo

# Create a parent commit, then add a new file in the working copy
(
  cd "$TEST_REPO"
  jj new -m "test: new file diff" 2>/dev/null
  echo "brand new content" > newfile.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit newfile.txt

" Open the status buffer
J

" Wait for status to load
sleep 500m

" Find the line with 'A newfile.txt'
let found_lnum = 0
for lnum in range(1, line('$'))
  if getline(lnum) =~# '^A newfile\.txt'
    let found_lnum = lnum
    break
  endif
endfor

if found_lnum == 0
  echoerr 'Could not find "A newfile.txt" line. Contents: ' . join(getline(1, '$'), ' | ')
  cquit 1
endif

" Move cursor to the new file line and execute dd
execute 'normal! ' . found_lnum . 'G'
execute "normal dd"

" Wait for buffers to load
sleep 1000m

" Should have a diff split with 2 windows and no errors
if winnr('$') < 2
  echoerr 'Expected at least 2 windows for diff split, got: ' . winnr('$')
  cquit 1
endif

" Verify both windows are in diff mode, and at least one has content.
" For a new file the "before" side (parent) is empty, the "after"
" side (working copy) has content.
let diff_wins = 0
let content_wins = 0
for w in range(1, winnr('$'))
  execute w . 'wincmd w'
  if &diff
    let diff_wins += 1
    if line('$') > 1 || (line('$') == 1 && getline(1) !=# '')
      let content_wins += 1
    endif
  endif
endfor

if diff_wins < 2
  echoerr 'Expected 2 diff windows, got: ' . diff_wins
  cquit 1
endif

if content_wins < 1
  echoerr 'Expected at least 1 diff window with content, got: ' . content_wins
  cquit 1
endif
VIMSCRIPT
then pass "dd on newly added file does not error"
else fail "dd on newly added file does not error"
fi

cleanup

finish
