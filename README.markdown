# fujjitive.vim

Fujjitive is a Vim plugin for [Jujutsu (jj)](https://github.com/martinvonz/jj),
the Git-compatible VCS. Based on Tim Pope's legendary
[fugitive.vim](https://github.com/tpope/vim-fugitive), it's "so awesome, it
should be illegal". That's why it's called Fujjitive.

The crown jewel of Fujjitive is `:JJ` (or just `:J`), which calls any
arbitrary Jujutsu command. If you know how to use `jj` at the command line, you
know how to use `:JJ`. It's vaguely akin to `:!jj` but with numerous
improvements:

* The default behavior is to directly echo the command's output. Quiet
  commands avoid the dreaded "Press ENTER or type command to continue" prompt.
* `:JJ describe`, `:JJ split`, and other commands that invoke an editor do
  their editing in the current Vim instance.
* `:JJ diff`, `:JJ log`, and other verbose, paginated commands have their
  output loaded into a temporary buffer. Force this behavior for any command
  with `:JJ --paginate` or `:JJ -p`.
* `:JJ file annotate` uses a temporary buffer with maps for additional triage.
  Press enter on a line to view the commit where the line changed, or `g?` to
  see other available maps.
* Called with no arguments, `:JJ` opens a summary window with modified files.
  Press `g?` to bring up a list of maps for numerous operations including
  diffing, splitting, committing, rebasing, and more.

  **Key concept:** Since Jujutsu has no staging area, the `s` key in the
  summary buffer triggers `jj split` (to split changes into a new commit),
  and `u` triggers `jj squash` (to merge changes back). This is the JJ
  equivalent of Git's stage/unstage workflow.

* This command (along with all other commands) always uses the current
  buffer's repository, so you don't need to worry about the current working
  directory.

Additional commands are provided for higher level operations:

* View any blob, tree, commit, or tag in the repository with `:Gedit` (and
  `:Gsplit`, etc.).
* `:Gdiffsplit` (or `:Gvdiffsplit`) brings up a diff view of the file.
* `:Gread` restores the file from the parent revision.
* `:Gwrite` writes changes to the working copy.
* `:Ggrep` is `:grep` for file searching. `:Glgrep` is `:lgrep` for the same.
* `:GMove` does a file move and changes the buffer name to match.
  `:GRename` does the same with a destination filename relative to the
  current file's directory.
* `:GDelete` deletes the current file and simultaneously deletes the buffer.
  `:GRemove` does the same but leaves the (now empty) buffer open.
* `:GBrowse` to open the current file on the web front-end of your favorite
  hosting provider, with optional line range (try it in visual mode).

Add `%{FujjitiveStatusline()}` to `'statusline'` to get an indicator
with the current change ID in your statusline.

For more information, see `:help fujjitive`.

## Key Jujutsu Concepts

Fujjitive adapts fugitive.vim's Git-centric workflow to Jujutsu's model:

| Git (fugitive)     | JJ (fujjitive)    | Notes                                    |
|--------------------|---------------------|------------------------------------------|
| `git commit`       | `jj commit`         | Describe current change and start new one|
| `git add` (stage)  | `jj split`          | Split current change into two            |
| `git reset` (unstage)| `jj squash`       | Squash changes back into parent          |
| `git stash`        | `jj new`            | Just create a new empty change           |
| `git checkout`     | `jj edit`           | Edit an existing change                  |
| `git branch`       | `jj bookmark`       | Manage bookmarks (branches)              |
| `git blame`        | `jj file annotate`  | Annotate file history                    |
| `git push`         | `jj git push`       | Push to remote via Git                   |
| `git fetch`        | `jj git fetch`      | Fetch from remote via Git                |
| `git rebase`       | `jj rebase`         | Rebase changes                           |

## Installation

Install using your favorite package manager, or use Vim's built-in package
support.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "zenibako/vim-fujjitive",
}
```

### Vim packages

    mkdir -p ~/.vim/pack/tpope/start
    cd ~/.vim/pack/tpope/start
    git clone https://github.com/zenibako/vim-fujjitive.git
    vim -u NONE -c "helptags fujjitive/doc" -c q

## Configuration

Set `g:fujjitive_jj_executable` to customize the `jj` binary path:

    let g:fujjitive_jj_executable = '/usr/local/bin/jj'

## Development

This project supports AI-assisted development via OpenCode. You can trigger OpenCode assistance by:

1. Commenting `/opencode` or `/oc` on any issue or pull request
2. Including `/opencode` or `/oc` in a pull request review comment

OpenCode will help with code reviews, bug fixes, feature implementation, and documentation updates.

## License

Based on fugitive.vim by Tim Pope. Copyright (c) Tim Pope. Distributed under
the same terms as Vim itself. See `:help license`.
