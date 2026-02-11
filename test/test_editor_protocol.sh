#!/usr/bin/env bash
# test/test_editor_protocol.sh — Tests for the OSC 51 editor escape protocol.
#
# Validates:
#   - strpart offset is correct for 'fujjitive:' prefix (the off-by-one fix)
#   - s:RunReceive parses the escape sequence and sets state.request = 'edit'
#   - Partial escape buffering works across split callbacks
#   - Full sentinel-file protocol works with a real jj job

source "$(dirname "$0")/helpers.sh"

_bold "Editor protocol tests"

# ── Unit: strpart offset ────────────────────────────────────────────────────

if run_nvim_test <<'VIMSCRIPT'
" 'fujjitive:' is 10 chars; strpart(cmd, 10) must yield 'edit'
if strpart('fujjitive:edit', 10) !=# 'edit'
  cquit 1
endif
" Sanity: the old offset (9) would give ':edit'
if strpart('fujjitive:edit', 9) !=# ':edit'
  cquit 1
endif
VIMSCRIPT
then pass "strpart offset correct for 'fujjitive:' prefix"
else fail "strpart offset correct for 'fujjitive:' prefix"
fi

# ── Unit: s:RunReceive parses escape (PTY mode) ────────────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let Func = SFunc('RunReceive')
let State = {'pty': 1, 'file': tempname()}
call writefile([], State.file, 'b')
let Tmp = {'err': '', 'out': '', 'escape': '', 'line_count': 0}

" Simulate PTY stdout data containing the OSC 51 escape
let data = [nr2char(27) . ']51;fujjitive:edit' . nr2char(7)]
call call(Func, [State, Tmp, 'out', 0, data])

if get(State, 'request', '') !=# 'edit'
  cquit 1
endif
VIMSCRIPT
then pass "s:RunReceive parses escape in PTY mode"
else fail "s:RunReceive parses escape in PTY mode"
fi

# ── Unit: s:RunReceive parses escape (non-PTY / stderr) ────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let Func = SFunc('RunReceive')
let State = {'pty': 0, 'file': tempname()}
call writefile([], State.file, 'b')
let Tmp = {'err': '', 'out': '', 'escape': '', 'line_count': 0}

" In non-PTY mode, escape detection only runs for type 'err'
let data = [nr2char(27) . ']51;fujjitive:edit' . nr2char(7)]
call call(Func, [State, Tmp, 'err', 0, data])

if get(State, 'request', '') !=# 'edit'
  cquit 1
endif
VIMSCRIPT
then pass "s:RunReceive parses escape in non-PTY stderr mode"
else fail "s:RunReceive parses escape in non-PTY stderr mode"
fi

# ── Unit: Partial escape buffering across split callbacks ───────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let Func = SFunc('RunReceive')
let State = {'pty': 1, 'file': tempname()}
call writefile([], State.file, 'b')
let Tmp = {'err': '', 'out': '', 'escape': '', 'line_count': 0}

" First chunk: partial escape (up to 'fujjitive:ed')
let chunk1 = [nr2char(27) . ']51;fujjitive:ed']
call call(Func, [State, Tmp, 'out', 0, chunk1])

" request should NOT be set yet
if get(State, 'request', '') !=# ''
  cquit 1
endif

" Second chunk: rest of the escape
let chunk2 = ['it' . nr2char(7)]
call call(Func, [State, Tmp, 'out', 0, chunk2])

if get(State, 'request', '') !=# 'edit'
  cquit 1
endif
VIMSCRIPT
then pass "Partial escape buffered across split callbacks"
else fail "Partial escape buffered across split callbacks"
fi

# ── Unit: non-PTY stdout is NOT parsed for escapes ──────────────────────────

if run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}

let Func = SFunc('RunReceive')
let State = {'pty': 0, 'file': tempname()}
call writefile([], State.file, 'b')
let Tmp = {'err': '', 'out': '', 'escape': '', 'line_count': 0}

" In non-PTY, 'out' type should NOT trigger escape parsing
let data = [nr2char(27) . ']51;fujjitive:edit' . nr2char(7)]
call call(Func, [State, Tmp, 'out', 0, data])

" request should remain unset — stdout is not scanned in non-PTY mode
if get(State, 'request', '') !=# ''
  cquit 1
endif
VIMSCRIPT
then pass "Non-PTY stdout is not parsed for escape sequences"
else fail "Non-PTY stdout is not parsed for escape sequences"
fi

# ── Integration: Sentinel protocol with real jj describe ────────────────────

if command -v jj &>/dev/null; then
  setup_jj_repo

  if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

let Func = SFunc('RunReceive')
let State = {'pty': 1, 'file': tempname()}
call writefile([], State.file, 'b')
let Tmp = {'err': '', 'out': '', 'escape': '', 'line_count': 0}

" Build the editor script exactly as the plugin does
let sh_file = tempname() . '.sh'
call writefile([
      \ '#!/bin/sh',
      \ '[ -f "\$FUJJITIVE.exit" ] && cat "\$FUJJITIVE.exit" >&2 && exit 1',
      \ 'echo "\$1" > "\$FUJJITIVE.edit"',
      \ 'printf "\033]51;fujjitive:edit\007" >&2',
      \ 'while [ -f "\$FUJJITIVE.edit" -a ! -f "\$FUJJITIVE.exit" ]; do sleep 0.05 2>/dev/null || sleep 1; done',
      \ 'exit 0'
      \ ], sh_file)

let env = {
      \ 'FUJJITIVE': State.file,
      \ 'NO_COLOR': '1',
      \ 'JJ_EDITOR': 'sh ' . sh_file,
      \ 'JJ_PAGER': 'cat',
      \ 'PAGER': 'cat',
      \ }

let job = jobstart(['jj', '--no-pager', 'describe'], {
      \ 'env': env,
      \ 'pty': State.pty,
      \ 'TERM': 'dumb',
      \ 'stdout_buffered': 0,
      \ 'stderr_buffered': 0,
      \ 'on_stdout': function(Func, [State, Tmp, 'out']),
      \ 'on_stderr': function(Func, [State, Tmp, 'err']),
      \ 'on_exit': {j,c,e -> 0},
      \ })

" Poll until request is set or timeout
let start = reltime()
while reltimefloat(reltime(start)) < 8.0 && get(State, 'request', '') ==# ''
  call jobwait([job], 10)
endwhile

" Assert escape was detected
if get(State, 'request', '') !=# 'edit'
  call jobstop(job)
  cquit 1
endif

" Assert sentinel file was created
if !filereadable(State.file . '.edit')
  call jobstop(job)
  cquit 1
endif

" Clean up: delete sentinel so the editor script exits
call delete(State.file . '.edit')
sleep 500m
call jobstop(job)
VIMSCRIPT
  then pass "Sentinel protocol works with real jj describe"
  else fail "Sentinel protocol works with real jj describe"
  fi

  cleanup
else
  _bold "  SKIP: jj not found — skipping integration test"
fi

finish
