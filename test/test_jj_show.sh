#!/usr/bin/env bash
# test/test_jj_show.sh — Tests for jj show integration.
#
# Validates:
#   - :JJ show opens a pager buffer with commit info
#   - :G show works via the git compatibility layer
#   - :Gedit <commit-hash> opens a commit object buffer
#   - <CR> on a commit in the status buffer opens the commit
#   - Commit hash extraction works with jj's change ID format
#   - cat-file limitation with jj is identified

source "$(dirname "$0")/helpers.sh"

_bold "jj show tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all jj show tests"
  finish
fi

# Helper to create a repo with commit history (so Ancestors section exists)
setup_jj_repo_with_history() {
  TEST_REPO="$(mktemp -d)"
  (
    cd "$TEST_REPO"
    jj git init --quiet 2>/dev/null || jj git init
    echo "test content" > file.txt
    echo "other content" > other.txt
    jj describe -m "test: initial commit" 2>/dev/null
    # Create a new change on top so the initial commit becomes an ancestor
    jj commit -m "test: first ancestor" 2>/dev/null
    echo "more content" >> file.txt
    jj describe -m "test: working copy" 2>/dev/null
  )
  export TEST_REPO
}

# ── Test: :JJ show opens a pager buffer with commit content ─────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
JJ show

let content = join(getline(1, '$'), "\n")

" Should contain author information or commit details
if content =~# 'Author\|author\|Commit ID\|Change ID'
  " Good — jj show produced recognizable output
elseif line('$') <= 1 && getline(1) ==# ''
  echoerr 'JJ show buffer is empty'
  cquit 1
endif

" Filetype should be git for pager output
if &filetype !=# 'git'
  echoerr 'Expected filetype=git, got: ' . &filetype
  cquit 1
endif
VIMSCRIPT
then pass ":JJ show opens a pager buffer with content"
else fail ":JJ show opens a pager buffer with content"
fi

cleanup

# ── Test: :JJ show -r <rev> shows specific revision ─────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
JJ show -r @

let content = join(getline(1, '$'), "\n")

" Should contain something about the test commit
if line('$') <= 1 && getline(1) ==# ''
  echoerr 'JJ show -r @ buffer is empty'
  cquit 1
endif
VIMSCRIPT
then pass ":JJ show -r @ shows working copy revision"
else fail ":JJ show -r @ shows working copy revision"
fi

cleanup

# ── Test: :G show works via git compatibility layer ──────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
G show

let content = join(getline(1, '$'), "\n")

if line('$') <= 1 && getline(1) ==# ''
  echoerr ':G show buffer is empty'
  cquit 1
endif

if &filetype !=# 'git'
  echoerr 'Expected filetype=git for :G show, got: ' . &filetype
  cquit 1
endif
VIMSCRIPT
then pass ":G show opens pager buffer via git compatibility layer"
else fail ":G show opens pager buffer via git compatibility layer"
fi

cleanup

# ── Test: :Gedit with commit hash opens commit object ────────────────────────

setup_jj_repo

# Get the commit hash
COMMIT_HASH=$(cd "$TEST_REPO" && jj log -r @ --no-graph -T 'commit_id.short(8)' --no-pager 2>/dev/null)

if [[ -z "$COMMIT_HASH" ]]; then
  fail ":Gedit <hash> — could not get commit hash"
else
  if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
edit file.txt
try
  Gedit ${COMMIT_HASH}
catch
  echoerr 'Gedit threw error: ' . v:exception
  cquit 1
endtry

" Check if buffer has content
let content = join(getline(1, '$'), "\n")
if line('\$') <= 1 && getline(1) ==# ''
  " Buffer is empty — this means cat-file -t failed and BufReadCmd
  " could not determine the object type. This is a known limitation
  " because jj does not support the 'cat-file' subcommand.
  echoerr 'Gedit buffer is empty (cat-file -t failed). b:fujjitive_type=' . get(b:, 'fujjitive_type', '(unset)')
  cquit 1
endif

" If we got here, the commit object was rendered
" Check for expected content (author info from jj show template)
if content !~# 'author\|Author\|initial commit'
  echoerr 'Gedit commit buffer lacks expected content. Got: ' . content
  cquit 1
endif
VIMSCRIPT
  then pass ":Gedit <hash> opens commit object with content"
  else fail ":Gedit <hash> opens commit object with content"
  fi
fi

cleanup

# ── Test: StageInfo commit regex matches jj log line format ──────────────────

setup_jj_repo_with_history

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let lines = getline(1, '$')
let content = join(lines, "\n")

" Find the Ancestors section and look for a commit line
let in_ancestors = 0
let commit_line = ''
for i in range(len(lines))
  if lines[i] =~# '^Ancestors'
    let in_ancestors = 1
    continue
  endif
  " First non-empty, non-heading line after Ancestors heading
  if in_ancestors && !empty(lines[i]) && lines[i] !~# '^\u\l\+.\+(\d'
    let commit_line = lines[i]
    break
  endif
endfor

if empty(commit_line)
  echoerr 'No commit line found in Ancestors section. Buffer: ' . content
  cquit 1
endif

" Test the regex used by s:StageInfo to extract commit hashes
" The regex is: '^\%(\%(\x\x\x\)\@!\l\+\s\+\)\=\zs[0-9a-f]\{4,\}\ze '
let extracted = matchstr(commit_line, '^\%(\%(\x\x\x\)\@!\l\+\s\+\)\=\zs[0-9a-f]\{4,\}\ze ')

if empty(extracted)
  " The regex failed to find a hex commit hash. This is expected because
  " s:FormatLog only includes the change_id (e.g. "tplwt·kwu"), which
  " contains non-hex letters, not the hex commit_id.
  echoerr 'StageInfo commit regex failed to extract hash from: ' . commit_line
  cquit 1
endif
VIMSCRIPT
then pass "StageInfo regex extracts commit hash from Ancestors log lines"
else fail "StageInfo regex extracts commit hash from Ancestors log lines"
fi

cleanup

# ── Test: <CR> on commit line in status buffer opens commit ──────────────────

setup_jj_repo_with_history

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let lines = getline(1, '$')

" Find the Ancestors section and position cursor on a commit line
let found = 0
for i in range(len(lines))
  if lines[i] =~# '^Ancestors'
    " Move to the first commit line after the heading
    for j in range(i+1, len(lines)-1)
      if !empty(lines[j]) && lines[j] !~# '^\u\l\+.\+(\d' && lines[j] !~# '^$'
        call cursor(j + 1, 1)
        let found = 1
        break
      endif
    endfor
    break
  endif
endfor

if !found
  echoerr 'Could not find commit line in Ancestors. Buffer: ' . join(lines, "\n")
  cquit 1
endif

" Try pressing <CR> to open the commit
let before_buf = bufnr('%')
try
  execute "normal \<CR>"
catch
  echoerr 'CR on commit line threw error: ' . v:exception
  cquit 1
endtry

" Check if we navigated away (a new buffer was opened)
let after_buf = bufnr('%')
if after_buf == before_buf
  " We didn't navigate — CR didn't open a commit
  let new_ft = &filetype
  if new_ft ==# 'fujjitive'
    echoerr 'CR on commit line did not navigate away from status buffer. Cursor line: ' . getline('.')
    cquit 1
  endif
endif

" If we got here, we navigated to something — check it has content
let content = join(getline(1, '$'), "\n")
if line('$') <= 1 && getline(1) ==# ''
  echoerr 'CR opened empty buffer. filetype=' . &filetype . ' bufname=' . bufname('%')
  cquit 1
endif
VIMSCRIPT
then pass "<CR> on commit in status buffer opens commit object"
else fail "<CR> on commit in status buffer opens commit object"
fi

cleanup

# ── Test: PagerFor routes 'show' to pager mode ──────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt

" Test that PagerFor returns 1 for 'show'
let result = fujjitive#PagerFor(['show'])
if result != 1
  echoerr 'PagerFor(["show"]) should return 1, got: ' . result
  cquit 1
endif

" Also test 'log' and 'diff' for consistency
let result_log = fujjitive#PagerFor(['log'])
if result_log != 1
  echoerr 'PagerFor(["log"]) should return 1, got: ' . result_log
  cquit 1
endif
VIMSCRIPT
then pass "PagerFor routes 'show' to pager mode"
else fail "PagerFor routes 'show' to pager mode"
fi

cleanup

# ── Test: cat-file -t fails with jj (confirming root cause) ──────────────────

setup_jj_repo

COMMIT_HASH=$(cd "$TEST_REPO" && jj log -r @ --no-graph -T 'commit_id.short(8)' --no-pager 2>/dev/null)

if [[ -z "$COMMIT_HASH" ]]; then
  fail "cat-file test — could not get commit hash"
else
  if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
edit file.txt

" Test that cat-file -t fails (since jj doesn't support it)
let r = fujjitive#Execute([FujjitiveJJDir(), 'cat-file', '-t', '${COMMIT_HASH}'])
if !r.exit_status
  " Unexpectedly succeeded — this would mean the colocated git repo
  " is being used, which would be fine
  echoerr 'cat-file -t unexpectedly succeeded (exit ' . r.exit_status . ')'
  cquit 1
endif

" cat-file fails as expected — this confirms that BufReadCmd cannot
" determine object types when using jj without a colocated git repo.
" This is the root cause of :Gedit <hash> failing.
VIMSCRIPT
  then pass "cat-file -t fails with jj (confirming known limitation)"
  else fail "cat-file -t fails with jj (confirming known limitation)"
  fi
fi

cleanup

# ── Test: FormatLog output does not include commit_id hash ───────────────────
# This verifies the root cause of the StageInfo regex issue: the formatted
# log line only contains the change_id, not the commit_id hex hash.

setup_jj_repo_with_history

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let lines = getline(1, '$')

" Find a line in the Ancestors section
let in_ancestors = 0
let commit_line = ''
for i in range(len(lines))
  if lines[i] =~# '^Ancestors'
    let in_ancestors = 1
    continue
  endif
  if in_ancestors && !empty(lines[i]) && lines[i] !~# '^\u\l\+.\+(\d'
    let commit_line = lines[i]
    break
  endif
endfor

if empty(commit_line)
  echoerr 'No commit line in Ancestors. Buffer: ' . join(lines, "\n")
  cquit 1
endif

" The formatted log line should contain the change_id with a middle-dot
" separator (·). Check that the format is as expected.
if commit_line !~# "\xc2\xb7"
  echoerr 'Log line missing middle-dot separator (·): ' . commit_line
  cquit 1
endif

" The line should NOT have a standalone hex commit hash that StageInfo
" can extract — only the change_id is present. Verify the format.
" A change_id like "tplwt·kwu" has non-hex chars, so the regex
" [0-9a-f]{4,} may or may not match depending on the change_id value.
" This test documents the actual format for reference.
VIMSCRIPT
then pass "FormatLog output uses change_id with middle-dot separator"
else fail "FormatLog output uses change_id with middle-dot separator"
fi

cleanup

finish
