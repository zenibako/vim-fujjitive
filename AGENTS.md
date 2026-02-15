# AGENTS.md — vim-fujjitive

## Project Overview

vim-fujjitive is a Vim/Neovim plugin that wraps Jujutsu (jj) VCS commands, adapted from Tim Pope's vim-fugitive.
Pure VimScript — no build step, no external dependencies beyond `jj` and Vim 9.0+ or Neovim 0.9.5+.

## Build / Lint / Test Commands

### Linting

```bash
# Install vint (one-time)
pip install "setuptools<70" vim-vint

# Lint all source files (must pass with zero errors)
vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/
```

### Running Tests

Tests require Neovim and `jj` installed. Tests run headless Neovim instances.

```bash
# Run the full test suite
bash test/run_tests.sh

# Run tests matching a substring (filters on filename)
bash test/run_tests.sh editor        # runs test_editor_protocol.sh
bash test/run_tests.sh blame         # runs test_blame.sh
bash test/run_tests.sh status        # runs test_status_buffer.sh + test_statusline.sh

# Run a single test file directly
bash test/test_editor_protocol.sh
```

Test environment variables:
- `JJ_USER` / `JJ_EMAIL` — Set automatically by helpers (defaults: "Test User" / "test@example.com")
- `NVIM_TIMEOUT` — Override per-test timeout (default: 10s)

### Verifying Plugin Loads (quick smoke test)

```bash
nvim --headless -u NONE -N \
  --cmd 'set rtp^=.' \
  --cmd 'runtime plugin/fujjitive.vim' \
  -c 'if exists("g:loaded_fujjitive") == 0 | cquit 1 | endif' \
  -c 'quit'
```

### CI Matrix

CI runs on push/PR to master/main: vint lint, Vim 9.0/9.1 smoke tests, and Neovim 0.9.5/0.11.0/stable full test suite. See `.github/workflows/ci.yml`.

## Code Style Guidelines

### File Structure

Each VimScript file begins with a header:
```vim
" Location:     autoload/fujjitive.vim
" Maintainer:   Tim Pope <http://tpo.pe/>
" Based on fugitive.vim, adapted for Jujutsu (jj) VCS
```

Code is organized into named sections with comment markers:
```vim
" Section: Utility
" Section: JJ Command
```

### Indentation and Formatting

- **2-space indentation** inside functions and control structures
- Line continuations use backslash (`\`) with standard indent
- All functions **must** use the `abort` keyword — this halts on error
- Guard loaded plugins: `if exists('g:loaded_fujjitive') | finish | endif`

### Naming Conventions

| Scope | Convention | Example |
|-------|-----------|---------|
| Public API functions | `FujjitiveXxx()` PascalCase | `FujjitiveJJDir()`, `FujjitiveStatusline()` |
| Autoload functions | `fujjitive#Xxx()` PascalCase after `#` | `fujjitive#Statusline()`, `fujjitive#Config()` |
| Script-local functions | `s:Xxx()` PascalCase | `s:Tree()`, `s:JoinChomp()` |
| Script-local variables | `s:snake_case` | `s:bad_jj_dir`, `s:head_cache` |
| Buffer-local variables | `b:snake_case` | `b:jj_dir`, `b:fujjitive_type` |
| Global variables | `g:snake_case` with prefix | `g:loaded_fujjitive`, `g:fujjitive_no_maps` |

### Functions

- All functions declared with `abort`: `function! s:Foo() abort`
- Public API functions live in `plugin/fujjitive.vim` with doc comments
- Internal functions live in `autoload/fujjitive.vim` — never call these externally
- Autoload functions are lazy-loaded on first `fujjitive#Xxx()` call
- Use `s:function()` helper to convert `s:name` references to Funcrefs

### Type Checking

Use explicit type comparisons — no magic coercion:
```vim
if type(a:arg) == type(0)      " number
if type(a:arg) == type('')     " string
if type(a:arg) == type([])     " list
if type(a:arg) == type({})     " dict
```

### Error Handling

- Throw errors with the `fujjitive:` prefix via `s:throw()`:
  ```vim
  function! s:throw(string) abort
    throw 'fujjitive: '.a:string
  endfunction
  ```
- Catch with pattern matching: `catch /^fujjitive:/`
- Use `try/catch/finally` blocks for operations that may fail
- Version checks: guard features behind `v:version` or `has()` checks
- Graceful degradation for older Vim versions (`v:version < 704`)

### Imports and Dependencies

No import system — VimScript uses autoload. The `autoload/` directory provides lazy loading: `fujjitive#Foo()` auto-sources `autoload/fujjitive.vim`.
Do not add external plugin dependencies.

### Shell / Path Handling

- Use `s:shellesc()` for cross-platform shell escaping (handles Windows)
- Use `s:Slash()` / `s:VimSlash()` for path separator normalization
- Never assume Unix paths — support Windows via `s:winshell()` checks

### Git-to-JJ Bridge

The plugin maintains translation tables for Git compatibility:
- `s:git_bridge_commands` — commands needing `jj git` prefix (e.g., `push`, `fetch`)
- `s:git_to_jj_commands` — direct equivalents (e.g., `stash` -> `bookmark`)
- `s:git_to_jj_renames` — renamed commands (e.g., `checkout` -> `edit`)

When adding new command support, update these mappings in `autoload/fujjitive.vim`.

## Test Conventions

### Test File Structure

Each `test/test_*.sh` file follows this pattern:
```bash
source "$(dirname "$0")/helpers.sh"
_bold "Section Name"
command -v jj >/dev/null 2>&1 || { echo "SKIP: jj not found"; finish; }

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
  " ... VimScript test code ...
  if some_condition | cquit 1 | endif
  qall!
VIMSCRIPT
then pass "description of what passed"
else fail "description of what failed"
fi

cleanup
finish
```

### Testing Script-Local Functions

Use the `RESOLVE_SID_VIM` snippet to access `s:` functions in tests:
```bash
run_nvim_test <<VIMSCRIPT
${RESOLVE_SID_VIM}
let Func = SFunc('RunReceive')
call call(Func, [args])
VIMSCRIPT
```

### Key Helpers

- `setup_jj_repo` — creates a temp jj repo with test files
- `cleanup` — removes the temp repo
- `run_nvim_test` — runs VimScript in headless Neovim with plugin loaded
- `run_nvim_test_in "$dir"` — same, but cds into `$dir` first
- `pass "msg"` / `fail "msg"` — record test result
- `finish` — print summary, exit nonzero if any failures

## Contributing

- **Commit messages**: Follow [commit.style](https://commit.style) conventions
- **Pull requests**: Squash and force-push requested changes for clean history
- **Configuration options**: Strongly discouraged — prefer autocommands and maps
- **Ask before patching**: Open an issue to discuss before large changes
- See `CONTRIBUTING.markdown` for full guidelines

## Version Control

This repository uses Jujutsu (jj) colocated with Git. 
Prefer `jj` commands and conventional commit messages (`fix:`, `feat:`, `chore:`, `test:`).
