Carbon.nvim
[![GitHub tag](https://img.shields.io/github/tag/SidOfc/carbon.nvim.svg?label=version)](https://github.com/SidOfc/carbon.nvim/releases)
[![GitHub issues](https://img.shields.io/github/issues/SidOfc/carbon.nvim.svg)](https://github.com/SidOfc/carbon.nvim/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/sidofc/carbon.nvim)](https://github.com/SidOfc/carbon.nvim/commits)
===========

![Carbon logo](/doc/assets/logo.svg)

<p align="center">
  <strong>The simple directory tree viewer for Neovim written in Lua.</strong>
</p>

## Introduction

Carbon.nvim provides a simple tree view of the directory Neovim was opened with/in.
Its main goal is to remain synchronized with the state of the current working directory.
When files are added, moved/renamed, or removed, Carbon automatically updates its state
to reflect these changes.

Special file types such as symlinks, broken symlinks, and executables are highlighted differently
and deeply nested files and folders are compressed as much as possible to reduce the need to
manually traverse directories to be able to open files.

Carbon provides the ability to [add](#creating-files-and-directories),
[move/rename](#moving-files-and-directories), and [delete](#deleting-files-and-directories)
files and directories, supports mappings to view [parent](#move-root-up) or [child](#move-root-down)
directories, settings to control Neovim's pwd (`:h carbon-setting-sync-pwd`) and lock Carbon's root
to Neovim's pwd (`:h carbon-setting-sync-on-cd`) and much more!

## Changelog

See the [releases](https://github.com/SidOfc/carbon.nvim/releases) page for more information.

## Installation

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

## Configuration

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

## Usage

Carbon comes with a few commands and mappings out of the box, each is described below:

### Commands

See `:h carbon-commands` for more detailed information about commands and their
customization options.

#### Carbon / Explore

| Command   | Alias      |
|:----------|:-----------|
| `:Carbon` | `:Explore` |

The `:Carbon` command replaces the current buffer with a Carbon buffer.
When `:h carbon-setting-keep-netrw` is `false` then NetRW's `:Explore`
command is aliased to `:Carbon`.

![Carbon / Explore command example](/doc/assets/carbon-explore.gif)

#### Lcarbon / Lexplore

| Command    | Alias       |
|:-----------|:------------|
| `:Lcarbon` | `:Lexplore` |

The `:Lcarbon` command opens a Carbon buffer in a split to the left of the
current buffer. When `:h carbon-setting-keep-netrw` is `false` then NetRW's
`:Lexplore` command is aliased to `:Lcarbon`.

![Lcarbon / Lexplore command example](/doc/assets/carbon-lexplore.gif)

#### Fcarbon

| Command    |
|:-----------|
| `:Fcarbon` |

The `:Fcarbon` command opens a Carbon buffer in a floating window. This
window can be configured using `:h carbon-setting-float-settings`.

![Fcarbon command example](/doc/assets/carbon-fexplore.gif)

### Mappings

See `:h carbon-plugs` for more detailed information about mappings and their
customization options.

#### Move root up

| Mapping      |
|:-------------|
| <kbd>[</kbd> |

Moves Carbon's root directory up one level and rerender. See `:h carbon-plug-up`
for more information and customization options. Accepts a **count** to go up
multiple levels at once.

![Carbon up example](/doc/assets/carbon-up.gif)

#### Move root down

| Mapping      |
|:-------------|
| <kbd>]</kbd> |

Moves Carbon's root directory down one level and rerender. See
`:h carbon-plug-down` for more information and customization options. Accepts
a **count** to go down multiple levels at once on compressed paths.

![Carbon down example](/doc/assets/carbon-down.gif)

#### Reset root

| Mapping      |
|:-------------|
| <kbd>.</kbd> |

Resets Carbon's root directory back to the directory Neovim is opened with.
See `:h carbon-plug-reset` for more information and customization options.

![Carbon reset example](/doc/assets/carbon-reset.gif)

#### Edit file or toggle directory

| Mapping          |
|:-----------------|
| <kbd>enter</kbd> |

When on a directory, expand or collapse that directory. When on a file, edit
that file in the current buffer and hide Carbon. This mapping works differently
when Carbon is opened with `:Lcarbon`. See `:h carbon-plug-edit` for more
information and customization options.

![Carbon edit example](/doc/assets/carbon-edit.gif)

#### Edit file in horizontal split

| Mapping                      |
|:-----------------------------|
| <kbd>ctrl</kbd>+<kbd>x</kbd> |

Does nothing when on a directory. Edit a file in a new horizontal split. See
`:h carbon-plug-split` for more information and customization points.

![Carbon split example](/doc/assets/carbon-split.gif)

#### Edit file in vertical split

| Mapping                      |
|:-----------------------------|
| <kbd>ctrl</kbd>+<kbd>v</kbd> |

Does nothing when on a directory. Edit a file in a new vertical split. See
`:h carbon-plug-vsplit` for more information and customization points.

![Carbon vsplit example](/doc/assets/carbon-vsplit.gif)

#### Close a Carbon buffer

| Mapping      | Alias             |
|:-------------|:------------------|
| <kbd>q</kbd> | <kbd>escape</kbd> |

Close a Carbon buffer, useful for closing Carbon buffers which were
opened with [`Fcarbon`](#fcarbon) or [`Lcarbon`](#lcarbon--lexplore).

![Close Carbon buffer example](/doc/assets/carbon-quit.gif)

#### Creating files and directories

| Mapping      |
|:-------------|
| <kbd>c</kbd> |

![Creating files and directories example](/doc/assets/carbon-create-action.gif)

Enters an interactive mode in which a path can be entered. When
done typing, press <kbd>enter</kbd> to confirm or <kbd>escape</kbd>
to cancel. Prepending a `count` to <kbd>c</kbd> will select the `count`_nth_
directory from the left as base. See `:h carbon-buffer-create` for more details.

#### Moving files and directories

| Mapping      |
|:-------------|
| <kbd>m</kbd> |

![Moving files and directories example](/doc/assets/carbon-move-action.gif)

Prompts to enter a new destination of the current entry under the cursor.
Will throw an error when the new destination already exists. Prepending
a `count` to <kbd>c</kbd> will select the `count`_nth_ directory from
the left as base. See `:h carbon-buffer-move` for more details.

#### Deleting files and directories

| Mapping      |
|:-------------|
| <kbd>d</kbd> |

![Deleting files and directories example](/doc/assets/carbon-delete-action-3.gif)

Prompts confirmation to delete the current entry under the cursor. Press <kbd>enter</kbd>
to confirm the currently highlighted option, <kbd>D</kbd> to confirm deletion directly,
or <kbd>escape</kbd> to cancel. Prepending a `count` to <kbd>c</kbd> will select
the `count`_nth_ directory from the left as base. See `:h carbon-buffer-delete`
for more details.
