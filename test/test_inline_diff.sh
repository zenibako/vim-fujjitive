#!/usr/bin/env bash
# test/test_inline_diff.sh — Tests for inline diff keymaps (=, >, <).
#
# Validates:
#   - = on a file line expands inline diff lines below the file entry
#   - = again on the same file line collapses the inline diff
#   - > forces expansion of inline diff
#   - < forces collapse of inline diff
#   - Expanded diff lines contain diff content (@@, +, - lines)

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

finish
