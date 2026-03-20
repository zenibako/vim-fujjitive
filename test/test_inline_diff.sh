#!/usr/bin/env bash
# test/test_inline_diff.sh — Tests for inline diff keymaps (=, >, <).
#
# Validates:
#   - = on a file line expands inline diff lines below the file entry
#   - = again on the same file line collapses the inline diff
#   - > forces expansion of inline diff
#   - < forces collapse of inline diff
#   - Expanded diff lines contain diff content (@@, +, - lines)
#   - Edge cases: newly added file (no prior content), multiple files,
#     = on non-file lines (headers, blank lines)

source "$(dirname "$0")/helpers.sh"

_bold "Inline diff (=, >, <) tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all inline diff tests"
  finish
fi

# ── Test: = on a file line expands inline diff ──────────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify file" 2>/dev/null
  echo "added line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let before = line('$')

if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Expand inline diff
execute "normal ="

let after = line('$')
if after <= before
  echoerr 'Expected line count to increase after expansion. Before: ' . before . ' After: ' . after
  cquit 1
endif
VIMSCRIPT
then pass "= on file line expands inline diff (line count increases)"
else fail "= on file line expands inline diff (line count increases)"
fi

cleanup

# ── Test: = again collapses inline diff ─────────────────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify file" 2>/dev/null
  echo "added line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let original = line('$')

if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Expand
execute "normal ="
let expanded = line('$')

" Move back to file line
call search('^M file\.txt')

" Collapse
execute "normal ="
let collapsed = line('$')

if expanded <= original
  echoerr 'Expansion failed. Original: ' . original . ' Expanded: ' . expanded
  cquit 1
endif
if collapsed != original
  echoerr 'Collapse did not restore original line count. Original: ' . original . ' Collapsed: ' . collapsed
  cquit 1
endif
VIMSCRIPT
then pass "= again on same file line collapses inline diff"
else fail "= again on same file line collapses inline diff"
fi

cleanup

# ── Test: > forces expansion of inline diff ─────────────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify file" 2>/dev/null
  echo "added line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let before = line('$')

if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Force expand with >
execute "normal >"

let after = line('$')
if after <= before
  echoerr 'Expected line count to increase after >. Before: ' . before . ' After: ' . after
  cquit 1
endif
VIMSCRIPT
then pass "> forces expansion of inline diff"
else fail "> forces expansion of inline diff"
fi

cleanup

# ── Test: > on already expanded diff does not collapse ──────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify file" 2>/dev/null
  echo "added line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Expand first
execute "normal >"
let expanded = line('$')

" Move back to file line
call search('^M file\.txt')

" > again should NOT collapse (unlike =)
execute "normal >"
let still_expanded = line('$')

if still_expanded != expanded
  echoerr '> should not collapse. Expanded: ' . expanded . ' After second >: ' . still_expanded
  cquit 1
endif
VIMSCRIPT
then pass "> on already expanded diff does not collapse"
else fail "> on already expanded diff does not collapse"
fi

cleanup

# ── Test: < forces collapse of inline diff ──────────────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify file" 2>/dev/null
  echo "added line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let original = line('$')

if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Expand first
execute "normal ="
let expanded = line('$')
if expanded <= original
  echoerr 'Expansion failed. Original: ' . original . ' Expanded: ' . expanded
  cquit 1
endif

" Move back to file line
call search('^M file\.txt')

" Force collapse with <
execute "normal <"
let collapsed = line('$')

if collapsed != original
  echoerr 'Collapse failed. Original: ' . original . ' Collapsed: ' . collapsed
  cquit 1
endif
VIMSCRIPT
then pass "< forces collapse of inline diff"
else fail "< forces collapse of inline diff"
fi

cleanup

# ── Test: < on collapsed diff is a no-op ────────────────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify file" 2>/dev/null
  echo "added line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let original = line('$')

if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" < on unexpanded diff should not change anything
execute "normal <"
let after = line('$')

if after != original
  echoerr '< on unexpanded diff should be no-op. Original: ' . original . ' After: ' . after
  cquit 1
endif
VIMSCRIPT
then pass "< on collapsed diff is a no-op"
else fail "< on collapsed diff is a no-op"
fi

cleanup

# ── Test: Expanded diff lines contain diff content ──────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify file" 2>/dev/null
  echo "added line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

let file_lnum = line('.')

" Expand
execute "normal ="

" Check lines after the file entry for diff content
let has_hunk_header = 0
let has_plus_line = 0
let has_context = 0
let lnum = file_lnum + 1
while lnum <= line('$')
  let l = getline(lnum)
  if l =~# '^@@'
    let has_hunk_header = 1
  elseif l =~# '^+'
    let has_plus_line = 1
  elseif l =~# '^ '
    let has_context = 1
  elseif l !~# '^[ @\+-]'
    break
  endif
  let lnum += 1
endwhile

if !has_hunk_header
  echoerr 'No @@ hunk header found in expanded diff'
  cquit 1
endif
if !has_plus_line
  echoerr 'No + (addition) line found in expanded diff'
  cquit 1
endif
VIMSCRIPT
then pass "Expanded diff lines contain @@ headers and + lines"
else fail "Expanded diff lines contain @@ headers and + lines"
fi

cleanup

# ── Test: = on newly added file shows diff with only + lines ─────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "add new file" 2>/dev/null
  echo "brand new content" > newfile.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit newfile.txt
J

if !search('^A newfile\.txt')
  echoerr 'newfile.txt not found as Added. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

let file_lnum = line('.')

" Expand
execute "normal ="

" All diff lines should be additions (+ lines) since file is new
let has_hunk = 0
let has_minus = 0
let lnum = file_lnum + 1
while lnum <= line('$')
  let l = getline(lnum)
  if l =~# '^@@'
    let has_hunk = 1
  elseif l =~# '^-'
    let has_minus = 1
  elseif l !~# '^[ @\+-]'
    break
  endif
  let lnum += 1
endwhile

if !has_hunk
  echoerr 'No @@ hunk header in new file diff'
  cquit 1
endif
if has_minus
  echoerr 'New file diff should not contain - (removal) lines'
  cquit 1
endif
VIMSCRIPT
then pass "= on newly added file shows diff with only + lines"
else fail "= on newly added file shows diff with only + lines"
fi

cleanup

# ── Test: = expands multiple files independently ─────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify two files" 2>/dev/null
  echo "change A" >> file.txt
  echo "change B" >> other.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let original = line('$')

" Expand first file
if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif
execute "normal ="
let after_first = line('$')

" Expand second file
if !search('^M other\.txt')
  echoerr 'other.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif
execute "normal ="
let after_second = line('$')

if after_first <= original
  echoerr 'First expand failed. Original: ' . original . ' After: ' . after_first
  cquit 1
endif
if after_second <= after_first
  echoerr 'Second expand failed. After first: ' . after_first . ' After second: ' . after_second
  cquit 1
endif

" Collapse first file — should not affect second
call search('^M file\.txt')
execute "normal ="
let after_collapse_first = line('$')

" Second file diff lines should still be present
if !search('^M other\.txt')
  echoerr 'other.txt disappeared after collapsing file.txt'
  cquit 1
endif
" Check that diff lines still follow other.txt
let lnum = line('.') + 1
if getline(lnum) !~# '^[ @\+-]'
  echoerr 'other.txt inline diff was lost when file.txt was collapsed'
  cquit 1
endif
VIMSCRIPT
then pass "= expands multiple files independently"
else fail "= expands multiple files independently"
fi

cleanup

# ── Test: = on non-file lines does not error ─────────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "modify file" 2>/dev/null
  echo "added line" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

" Move to a blank line if one exists and press =
let blank_lnum = 0
for lnum in range(1, line('$'))
  if getline(lnum) ==# ''
    let blank_lnum = lnum
    break
  endif
endfor
if blank_lnum > 0
  call cursor(blank_lnum, 1)
  let before = line('$')
  execute "normal ="
  let after = line('$')
  " Blank lines should not trigger expansion
  if after != before
    echoerr '= on blank line changed buffer. Before: ' . before . ' After: ' . after
    cquit 1
  endif
endif

" Also press > and < on blank line — should be safe
if blank_lnum > 0
  call cursor(blank_lnum, 1)
  execute "normal >"
  call cursor(blank_lnum, 1)
  execute "normal <"
endif
VIMSCRIPT
then pass "= > < on blank line does not error"
else fail "= > < on blank line does not error"
fi

cleanup

finish
