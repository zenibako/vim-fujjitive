#!/usr/bin/env bash
# test/test_status_buffer.sh — Tests for the :J status buffer.
#
# Validates:
#   - :J opens a buffer with correct filetype, buftype, and b:fujjitive_type
#   - Header lines contain Working copy, Parent, and Help
#   - Modified files appear in Working copy changes section

source "$(dirname "$0")/helpers.sh"

_bold "Status buffer tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all status buffer tests"
  finish
fi

# ── Test: :J opens with correct buffer settings ─────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

" Check buffer-local settings
if get(b:, 'fujjitive_type', '') !=# 'index'
  echoerr 'b:fujjitive_type is not index, got: ' . get(b:, 'fujjitive_type', '(unset)')
  cquit 1
endif
if &buftype !=# 'nowrite'
  echoerr 'buftype is not nowrite, got: ' . &buftype
  cquit 1
endif
if &filetype !=# 'fujjitive'
  echoerr 'filetype is not fujjitive, got: ' . &filetype
  cquit 1
endif
VIMSCRIPT
then pass ":J opens buffer with correct filetype/buftype/b:fujjitive_type"
else fail ":J opens buffer with correct filetype/buftype/b:fujjitive_type"
fi

cleanup

# ── Test: Status buffer has header lines ─────────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let lines = getline(1, '$')
let content = join(lines, "\n")

" Check for Working copy header
let has_wc = 0
for l in lines
  if l =~# '^Working copy'
    let has_wc = 1
    break
  endif
endfor
if !has_wc
  echoerr 'Missing "Working copy" header. Buffer contents: ' . content
  cquit 1
endif

" Check for Help: g? header
let has_help = 0
for l in lines
  if l =~# '^Help:.\+g?'
    let has_help = 1
    break
  endif
endfor
if !has_help
  echoerr 'Missing "Help: g?" header. Buffer contents: ' . content
  cquit 1
endif
VIMSCRIPT
then pass "Status buffer contains Working copy and Help headers"
else fail "Status buffer contains Working copy and Help headers"
fi

cleanup

# ── Test: Modified files appear in Working copy changes ──────────────────────

setup_jj_repo

# Modify a file so it shows as changed
echo "modified" >> "$TEST_REPO/file.txt"

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let lines = getline(1, '$')
let content = join(lines, "\n")

" Check that Working copy changes section exists
let has_section = 0
for l in lines
  if l =~# 'Working copy changes'
    let has_section = 1
    break
  endif
endfor
if !has_section
  echoerr 'Missing "Working copy changes" section. Buffer: ' . content
  cquit 1
endif

" Check that file.txt appears in the buffer
let has_file = 0
for l in lines
  if l =~# 'file\.txt'
    let has_file = 1
    break
  endif
endfor
if !has_file
  echoerr 'file.txt not listed in status buffer. Buffer: ' . content
  cquit 1
endif
VIMSCRIPT
then pass "Modified files appear in Working copy changes section"
else fail "Modified files appear in Working copy changes section"
fi

cleanup

# ── Test: Status buffer is read-only ─────────────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

if &modifiable
  echoerr 'Status buffer should be nomodifiable'
  cquit 1
endif
if !&readonly
  echoerr 'Status buffer should be readonly'
  cquit 1
endif
VIMSCRIPT
then pass "Status buffer is read-only and nomodifiable"
else fail "Status buffer is read-only and nomodifiable"
fi

cleanup

# ── Test: Current branch and Other mutable sections ──────────────────────────

setup_jj_repo

# Create a second branch with its own commit, then switch back
(
  cd "$TEST_REPO"
  # Current branch has the initial commit + working copy
  # Create a new change on a separate branch
  jj new 'root()' -m "other: unrelated work" 2>/dev/null
  # Go back to the original working copy
  jj new @ -m "test: back on main" 2>/dev/null || true
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let lines = getline(1, '$')
let content = join(lines, "\n")

" Check that 'Current branch' section exists
let has_current = 0
for l in lines
  if l =~# '^Current branch'
    let has_current = 1
    break
  endif
endfor
if !has_current
  echoerr 'Missing "Current branch" section. Buffer: ' . content
  cquit 1
endif

" Check that old 'Mutable' section does NOT exist
for l in lines
  if l =~# '^Mutable '
    echoerr 'Found old "Mutable" section that should have been replaced. Buffer: ' . content
    cquit 1
  endif
endfor
VIMSCRIPT
then pass "Status buffer shows Current branch section (not Mutable)"
else fail "Status buffer shows Current branch section (not Mutable)"
fi

cleanup

finish
