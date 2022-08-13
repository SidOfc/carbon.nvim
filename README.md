Carbon.nvim
[![GitHub tag](https://img.shields.io/github/v/tag/SidOfc/carbon.nvim.svg?label=version&sort=semver&color=f200ff)](https://github.com/SidOfc/carbon.nvim/releases)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/SidOfc/carbon.nvim.svg?color=4b1)](https://github.com/SidOfc/carbon.nvim/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/sidofc/carbon.nvim?color=4b1)](https://github.com/SidOfc/carbon.nvim/commits)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/SidOfc/carbon.nvim/CI)](https://github.com/SidOfc/carbon.nvim/actions/workflows/ci.yml)
===========

![Carbon logo](/doc/assets/logo.svg)

<p align="center">
  <strong>The simple directory tree viewer for Neovim written in Lua.</strong>
</p>

# Introduction

Carbon.nvim provides a simple tree view of the directory Neovim was opened with/in.
Its main goal is to remain synchronized with the state of the current working directory.
When files are added, moved/renamed, or removed, Carbon automatically updates its state
to reflect these changes even if they were made external to Neovim.

Special file types such as symlinks, broken symlinks, and executables are highlighted differently
and deeply nested files and folders are compressed as much as possible to reduce the need to
manually traverse directories to be able to open files.

Carbon provides the ability to [add](#creating-files-and-directories),
[move/rename](#moving-files-and-directories), and [delete](#deleting-files-and-directories)
files and directories, supports mappings to view [parent](#move-root-up) or [child](#move-root-down)
directories, settings to control Neovim's pwd (`:h carbon-setting-sync-pwd`) and lock Carbon's root
to Neovim's pwd (`:h carbon-setting-sync-on-cd`) and much more!

# Changelog

See the [releases](https://github.com/SidOfc/carbon.nvim/releases) page for more information.

# Installation

Install on Nightly Neovim (0.8.0+) using your favorite plugin manager:

| Name                                                         | Code                                          |
|:-------------------------------------------------------------|:----------------------------------------------|
| **[vim-plug](https://github.com/junegunn/vim-plug)**         | `Plug 'SidOfc/carbon.nvim'`                   |
| **[Vundle.vim](https://github.com/VundleVim/Vundle.vim)**    | `Plugin 'SidOfc/carbon.nvim'`                 |
| **[Vundle.vim](https://github.com/VundleVim/Vundle.vim)**    | `Plugin 'SidOfc/carbon.nvim'`                 |
| **[dein.vim](https://github.com/Shougo/dein.vim)**           | `call dein#add('SidOfc/carbon.nvim')`         |
| **[minpac](https://github.com/k-takata/minpac)**             | `call minpac#add('SidOfc/carbon.nvim')`       |
| **[packer.nvim](https://github.com/wbthomason/packer.nvim)** | `use 'SidOfc/carbon.nvim'`                    |
| **[paq-nvim](https://github.com/savq/paq-nvim)**             | `require 'paq' { 'SidOfc/carbon.nvim', ... }` |

# Configuration

Configuration can be supplied like this:

**init.vim**

```viml
lua << EOF
  require('carbon').setup({
    setting = 'value',
  })
EOF
```

**init.lua**

```lua
require('carbon').setup({
  setting = 'value',
})
```

These settings will be deep merged with the default settings. See
`:h carbon-settings-table` for a list of available settings. An
alternative option of calling this method also exists:

**init.vim**

```viml
lua << EOF
  require('carbon').setup(function(settings)
    settings.setting = 'value'
  end)
EOF
```

**init.lua**

```lua
require('carbon').setup(function(settings)
  settings.setting = 'value'
end)
```

This option is more flexible as you have full control over the settings.
You are free to modify them as you wish, no merging will occur.

See `:h carbon-setup` for a more detailed explanation on configuration.
See `:h carbon-carbon-setup` for documentation about the `.setup` method.

# Usage

After installation, Carbon will launch automatically and disable NetRW.
These behaviors and many others can be customized, see `:h carbon-settings` for
more information about customization or `:h carbon-toc` for a table of contents.

Carbon comes with a few commands and mappings out of the box, each is described below:

## Commands

See `:h carbon-commands` for more detailed information about commands and their
customization options.

All commands also support bang (`!`) versions which will make Carbon expand the
tree to reveal the current buffer path if possible. When successful, the cursor
will be moved to the entry and it will be highlighted for a short time as well.

See `:h carbon-buffer-flash-bang` for more information.
This behavior can also be enabled by default by setting: `:h carbon-setting-always-reveal`.

### `:Carbon` / `:Explore`

The `:Carbon` command replaces the current buffer with a Carbon buffer.
When `:h carbon-setting-keep-netrw` is `false` then NetRW's `:Explore`
command is aliased to `:Carbon`.

![Carbon / Explore command example](/doc/assets/carbon-explore.gif)

### `:Lcarbon` / `:Lexplore`

The `:Lcarbon` command opens a Carbon buffer in a split to the left of the
current buffer. When `:h carbon-setting-keep-netrw` is `false` then NetRW's
`:Lexplore` command is aliased to `:Lcarbon`.

Subsequent calls to `:Lcarbon` will attempt to navigate to an existing
window opened via `:Lcarbon`.

![Lcarbon / Lexplore command example](/doc/assets/carbon-lexplore.gif)

### `:Fcarbon`

The `:Fcarbon` command opens a Carbon buffer in a floating window. This
window can be configured using `:h carbon-setting-float-settings`.

![Fcarbon command example](/doc/assets/carbon-fexplore.gif)

## Mappings

See `:h carbon-plugs` for more detailed information about mappings and their
customization options.

### <kbd>[</kbd> Move root up

Moves Carbon's root directory up one level and rerender. See `:h carbon-plug-up`
for more information and customization options. Accepts a **count** to go up
multiple levels at once.

![Carbon up example](/doc/assets/carbon-up.gif)

### <kbd>]</kbd> Move root down

Moves Carbon's root directory down one level and rerender. See
`:h carbon-plug-down` for more information and customization options. Accepts
a **count** to go down multiple levels at once on compressed paths.

![Carbon down example](/doc/assets/carbon-down.gif)

### <kbd>.</kbd> Reset root

Resets Carbon's root directory back to the directory Neovim is opened with.
See `:h carbon-plug-reset` for more information and customization options.

![Carbon reset example](/doc/assets/carbon-reset.gif)

### <kbd>enter</kbd> Edit file or toggle directory

When on a directory, expand or collapse that directory. When on a file, edit
that file in the current buffer and hide Carbon. This mapping works differently
when Carbon is opened with `:Lcarbon`. See `:h carbon-plug-edit` for more
information and customization options.

![Carbon edit example](/doc/assets/carbon-edit.gif)

### <kbd>!</kbd> Recursively toggle directories

When on a directory, expand or collapse that directory recursively. When on a
file nothing will happen.

![Carbon recursive directory toggle example](/doc/assets/carbon-toggle-recursive-action.gif)

**NOTE:** This mapping is probably best remapped to <kbd>shift</kbd>+<kbd>enter</kbd>. The reason
it is not the default is due to specific configuration required to make it work.

Some emulators send the same codes for <kbd>enter</kbd> and <kbd>shift</kbd>+<kbd>enter</kbd>
which means Neovim cannot distinguish one from another. This can usually be fixed by setting
them manually for your emulator. Included from this [SO answer](https://stackoverflow.com/a/42461580/2224331):

> I managed to correct my terminal key-code for <kbd>Shift</kbd>+<kbd>Enter</kbd>
> by sending the key-code Vim apparently expects. Depending on your terminal,
> _(Adding <kbd>Ctrl</kbd>+<kbd>Enter</kbd> as a bonus!)_
>
> **[iTerm2](https://www.iterm2.com/)**, open _Preferences_ → _Profiles_ → _Keys_ → _[+] (Add)_ →
> - _Keyboard shortcut:_ (Hit <kbd>Shift</kbd>+<kbd>Enter</kbd>)
> - _Action:_ _Send Escape Sequence_
> - _Esc+_ `[[13;2u`
>   Repeat for <kbd>Ctrl</kbd>+<kbd>Enter</kbd>, with sequence: `[[13;5u`
>
> **[urxvt](http://software.schmorp.de/pkg/rxvt-unicode.html)**, append to your `.Xresources` file:
>
>     URxvt.keysym.S-Return:     \033[13;2u
>     URxvt.keysym.C-Return:     \033[13;5u
>
> **[Alacritty](https://github.com/jwilm/alacritty)**, under `key_bindings`, add following to your `~/.config/alacritty/alacritty.yml`:
>
>     - { key: Return,   mods: Shift,   chars: "\x1b[13;2u" }
>     - { key: Return,   mods: Control, chars: "\x1b[13;5u" }

### <kbd>ctrl</kbd>+<kbd>x</kbd> Edit file in horizontal split

Does nothing when on a directory. Edit a file in a new horizontal split. See
`:h carbon-plug-split` for more information and customization points.

![Carbon split example](/doc/assets/carbon-split.gif)

### <kbd>ctrl</kbd>+<kbd>v</kbd> Edit file in vertical split

Does nothing when on a directory. Edit a file in a new vertical split. See
`:h carbon-plug-vsplit` for more information and customization points.

![Carbon vsplit example](/doc/assets/carbon-vsplit.gif)

### <kbd>q</kbd> / <kbd>escape</kbd> Close a Carbon buffer

Close a Carbon buffer, useful for closing Carbon buffers which were
opened with [`Fcarbon`](#fcarbon) or [`Lcarbon`](#lcarbon--lexplore).

![Close Carbon buffer example](/doc/assets/carbon-quit.gif)

### <kbd>c</kbd> Creating files and directories

![Creating files and directories example](/doc/assets/carbon-create-action.gif)

Enters an interactive mode in which a path can be entered. When
done typing, press <kbd>enter</kbd> to confirm or <kbd>escape</kbd>
to cancel. Prepending a `count` to <kbd>c</kbd> will select the `count`_nth_
directory from the left as base. See `:h carbon-buffer-create` for more details.

### <kbd>m</kbd> Moving files and directories

![Moving files and directories example](/doc/assets/carbon-move-action.gif)

Prompts to enter a new destination of the current entry under the cursor.
Will throw an error when the new destination already exists. Prepending
a `count` to <kbd>c</kbd> will select the `count`_nth_ directory from
the left as base. See `:h carbon-buffer-move` for more details.

### <kbd>d</kbd> Deleting files and directories

![Deleting files and directories example](/doc/assets/carbon-delete-action-3.gif)

Prompts confirmation to delete the current entry under the cursor. Press <kbd>enter</kbd>
to confirm the currently highlighted option, <kbd>D</kbd> to confirm deletion directly,
or <kbd>escape</kbd> to cancel. Prepending a `count` to <kbd>c</kbd> will select
the `count`_nth_ directory from the left as base. See `:h carbon-buffer-delete`
for more details.

# Development

The following dependencies must be installed before you can work on carbon.nvim:

- [git](https://git-scm.com/)
- [make](https://www.gnu.org/software/make/)
- [neovim](https://github.com/neovim/neovim)
- [stylua](https://github.com/JohnnyMorganz/StyLua)
- [luacheck](https://github.com/mpeterv/luacheck)

## Running tasks

The `make` command is used to perform various tasks such as running the tests or
linting the code. The [Makefile](/Makefile) defines the following tasks:

- [`all`](/Makefile#L1-L5)
- [`test`](/Makefile#L7-L9)
- [`lint`](/Makefile#L11-L13)
- [`format-check`](/Makefile#L15-L17)

Run `make` to execute all tasks. To execute a specific task run `make {task}`
where `{task}` is one of the tasks listed above.

### Formatting

[stylua](https://github.com/JohnnyMorganz/StyLua) is used to format code.
Please make sure it is installed and integrated into your editor or run
`make format-check` and fix any errors before committing the code.

### Linting

[luacheck](https://github.com/mpeterv/luacheck) is used for linting.
Please make sure it is installed and integrated into your editor or run
`make lint` and fix any errors before committing the code.

### Testing

[plenary.nvim](https://github.com/nvim-lua/plenary.nvim) is used to run tests.
You do not need to have it installed. If it is not installed the test [bootstrap](https://github.com/SidOfc/carbon.nvim/blob/master/test/config/bootstrap.lua#L7-L12)
process will handle installing it Run `make test` and ensure tests pass
before committing the code.

The list below shows which modules have been fully tested.

- [x] [`carbon`](/lua/carbon.lua) ([specs](/test/specs/carbon_spec.lua))
- [x] [`carbon.util`](/lua/carbon/util.lua) ([specs](/test/specs/util_spec.lua))
- [ ] [`carbon.entry`](/lua/carbon/entry.lua)
- [ ] [`carbon.buffer`](/lua/carbon/buffer.lua) ([specs](/test/specs/buffer_spec.lua))
- [x] [`carbon.watcher`](/lua/carbon/watcher.lua) ([specs](/test/specs/watcher_spec.lua))
- [x] [`carbon.settings`](/lua/carbon/settings.lua) ([specs](/test/specs/settings_spec.lua))
- [x] [`carbon.constants`](/lua/carbon/constants.lua) ([specs](/test/specs/constants_spec.lua))

## Github Actions

carbon.nvim uses Github Actions to run [tests](#testing), [lint](#linting), and
[validate formatting](#formatting) of the code. Pull requests must pass these
checks before they will be considered. See [ci.yml](/.github/workflows/ci.yml) for
more details about the workflow.

