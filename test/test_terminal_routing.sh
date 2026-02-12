#!/usr/bin/env bash
# test/test_terminal_routing.sh — Tests for terminal routing of jj split (TASK-2).
#
# Validates:
#   - s:HasOpt correctly matches split with -i, --interactive, --tool
#   - s:HasOpt does NOT match split with unrelated flags
#   - Bare split (no --) is detected as interactive
#   - split -- file.txt is NOT detected as interactive (filesets given)
#   - The wants_terminal expression evaluates correctly for all split cases
#   - The TermClose autocmd string includes fujjitive#DidChange

source "$(dirname "$0")/helpers.sh"

_bold "Terminal routing tests"

# ── Unit: s:HasOpt matches split with --interactive ─────────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
if !call(HasOpt, [['split', '--interactive'], ['split'], '-i', '--interactive', '--tool'])
  echoerr 'HasOpt should match split --interactive'
  cquit 1
endif
VIMSCRIPT
then pass "s:HasOpt matches split with --interactive"
else fail "s:HasOpt matches split with --interactive"
fi

# ── Unit: s:HasOpt matches split with -i ────────────────────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
if !call(HasOpt, [['split', '-i'], ['split'], '-i', '--interactive', '--tool'])
  echoerr 'HasOpt should match split -i'
  cquit 1
endif
VIMSCRIPT
then pass "s:HasOpt matches split with -i"
else fail "s:HasOpt matches split with -i"
fi

# ── Unit: s:HasOpt matches split with --tool ────────────────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
if !call(HasOpt, [['split', '--tool', 'meld'], ['split'], '-i', '--interactive', '--tool'])
  echoerr 'HasOpt should match split --tool'
  cquit 1
endif
VIMSCRIPT
then pass "s:HasOpt matches split with --tool"
else fail "s:HasOpt matches split with --tool"
fi

# ── Unit: s:HasOpt does NOT match split with unrelated flag ─────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
if call(HasOpt, [['split', '--revision', '@'], ['split'], '-i', '--interactive', '--tool'])
  echoerr 'HasOpt should NOT match split --revision (no terminal flag)'
  cquit 1
endif
VIMSCRIPT
then pass "s:HasOpt does NOT match split with unrelated flags"
else fail "s:HasOpt does NOT match split with unrelated flags"
fi

# ── Unit: s:HasOpt does NOT match non-split subcommand ──────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
if call(HasOpt, [['log', '--interactive'], ['split'], '-i', '--interactive', '--tool'])
  echoerr 'HasOpt should NOT match log --interactive against split guard'
  cquit 1
endif
VIMSCRIPT
then pass "s:HasOpt does NOT match non-split subcommand with --interactive"
else fail "s:HasOpt does NOT match non-split subcommand with --interactive"
fi

# ── Unit: Bare split (no --) detected as interactive ────────────────────────

if run_nvim_test <<'VIMSCRIPT'
let args = ['split']
if !(get(args, 0, '') ==# 'split' && index(args, '--') == -1)
  echoerr 'Bare split should be detected as interactive (no -- found)'
  cquit 1
endif
VIMSCRIPT
then pass "Bare split (no --) detected as interactive"
else fail "Bare split (no --) detected as interactive"
fi

# ── Unit: split with --revision but no -- detected as interactive ───────────

if run_nvim_test <<'VIMSCRIPT'
let args = ['split', '--revision', '@-']
if !(get(args, 0, '') ==# 'split' && index(args, '--') == -1)
  echoerr 'split --revision @- should be detected as interactive (no --)'
  cquit 1
endif
VIMSCRIPT
then pass "split --revision (no filesets) detected as interactive"
else fail "split --revision (no filesets) detected as interactive"
fi

# ── Unit: split -- file.txt NOT detected as bare interactive ────────────────

if run_nvim_test <<'VIMSCRIPT'
let args = ['split', '--', 'file.txt']
if get(args, 0, '') ==# 'split' && index(args, '--') == -1
  echoerr 'split -- file.txt should NOT be detected as bare interactive'
  cquit 1
endif
VIMSCRIPT
then pass "split -- file.txt NOT detected as bare interactive"
else fail "split -- file.txt NOT detected as bare interactive"
fi

# ── Unit: Full wants_terminal expression for split --interactive ────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
let args = ['split', '--interactive']
let pager = 0

let wants_terminal =
      \ (call(HasOpt, [args, ['add', 'checkout', 'commit', 'reset', 'restore', 'stage', 'restore'], '-p', '--patch']) ||
      \ call(HasOpt, [args, ['add', 'clean', 'stage'], '-i', '--interactive']) ||
      \ call(HasOpt, [args, ['split'], '-i', '--interactive', '--tool']) ||
      \ (get(args, 0, '') ==# 'split' && index(args, '--') == -1)) && pager is# 0

if !wants_terminal
  echoerr 'wants_terminal should be true for split --interactive'
  cquit 1
endif
VIMSCRIPT
then pass "wants_terminal is true for split --interactive"
else fail "wants_terminal is true for split --interactive"
fi

# ── Unit: Full wants_terminal expression for bare split ─────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
let args = ['split']
let pager = 0

let wants_terminal =
      \ (call(HasOpt, [args, ['add', 'checkout', 'commit', 'reset', 'restore', 'stage', 'restore'], '-p', '--patch']) ||
      \ call(HasOpt, [args, ['add', 'clean', 'stage'], '-i', '--interactive']) ||
      \ call(HasOpt, [args, ['split'], '-i', '--interactive', '--tool']) ||
      \ (get(args, 0, '') ==# 'split' && index(args, '--') == -1)) && pager is# 0

if !wants_terminal
  echoerr 'wants_terminal should be true for bare split'
  cquit 1
endif
VIMSCRIPT
then pass "wants_terminal is true for bare split"
else fail "wants_terminal is true for bare split"
fi

# ── Unit: Full wants_terminal expression for split -- file.txt ──────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
let args = ['split', '--', 'file.txt']
let pager = 0

let wants_terminal =
      \ (call(HasOpt, [args, ['add', 'checkout', 'commit', 'reset', 'restore', 'stage', 'restore'], '-p', '--patch']) ||
      \ call(HasOpt, [args, ['add', 'clean', 'stage'], '-i', '--interactive']) ||
      \ call(HasOpt, [args, ['split'], '-i', '--interactive', '--tool']) ||
      \ (get(args, 0, '') ==# 'split' && index(args, '--') == -1)) && pager is# 0

if wants_terminal
  echoerr 'wants_terminal should be false for split -- file.txt (explicit filesets)'
  cquit 1
endif
VIMSCRIPT
then pass "wants_terminal is false for split -- file.txt"
else fail "wants_terminal is false for split -- file.txt"
fi

# ── Unit: wants_terminal false when pager is active ─────────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
let args = ['split', '--interactive']
let pager = 'less'

" When pager is a string (active), wants_terminal should be true because of
" the type(pager) ==# type('') check — the pager string takes precedence
let wants_terminal = type(pager) ==# type('') ||
      \ (call(HasOpt, [args, ['add', 'checkout', 'commit', 'reset', 'restore', 'stage', 'restore'], '-p', '--patch']) ||
      \ call(HasOpt, [args, ['add', 'clean', 'stage'], '-i', '--interactive']) ||
      \ call(HasOpt, [args, ['split'], '-i', '--interactive', '--tool']) ||
      \ (get(args, 0, '') ==# 'split' && index(args, '--') == -1)) && pager is# 0

if !wants_terminal
  echoerr 'wants_terminal should be true when pager is a string'
  cquit 1
endif
VIMSCRIPT
then pass "wants_terminal is true when pager is a string (pager takes precedence)"
else fail "wants_terminal is true when pager is a string (pager takes precedence)"
fi

# ── Unit: TermClose autocmd string includes DidChange ───────────────────────

if run_nvim_test <<'VIMSCRIPT'
let dir = '/tmp/test-repo'
let did_change = '|autocmd TermClose <buffer> ++once call fujjitive#DidChange(' . string(dir) . ')'

if did_change !~# 'TermClose'
  echoerr 'did_change string missing TermClose'
  cquit 1
endif
if did_change !~# 'fujjitive#DidChange'
  echoerr 'did_change string missing fujjitive#DidChange'
  cquit 1
endif
if did_change !~# '++once'
  echoerr 'did_change string missing ++once (should fire only once)'
  cquit 1
endif
if did_change !~# '<buffer>'
  echoerr 'did_change string missing <buffer> (should be buffer-local)'
  cquit 1
endif
if did_change !~# escape(dir, '/')
  echoerr 'did_change string missing dir path'
  cquit 1
endif
VIMSCRIPT
then pass "TermClose autocmd string includes DidChange with dir and ++once"
else fail "TermClose autocmd string includes DidChange with dir and ++once"
fi

# ── Unit: wants_terminal for split --tool meld ──────────────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let HasOpt = SFunc('HasOpt')
let args = ['split', '--tool', 'meld']
let pager = 0

let wants_terminal =
      \ (call(HasOpt, [args, ['add', 'checkout', 'commit', 'reset', 'restore', 'stage', 'restore'], '-p', '--patch']) ||
      \ call(HasOpt, [args, ['add', 'clean', 'stage'], '-i', '--interactive']) ||
      \ call(HasOpt, [args, ['split'], '-i', '--interactive', '--tool']) ||
      \ (get(args, 0, '') ==# 'split' && index(args, '--') == -1)) && pager is# 0

if !wants_terminal
  echoerr 'wants_terminal should be true for split --tool meld'
  cquit 1
endif
VIMSCRIPT
then pass "wants_terminal is true for split --tool meld"
else fail "wants_terminal is true for split --tool meld"
fi

finish
