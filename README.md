# Carbon.nvim [![GitHub tag](https://img.shields.io/github/tag/SidOfc/carbon.nvim.svg?label=version)](https://github.com/SidOfc/carbon.nvim/releases) [![GitHub issues](https://img.shields.io/github/issues/SidOfc/carbon.nvim.svg)](https://github.com/SidOfc/carbon.nvim/issues)

![Carbon logo](/doc/assets/logo.svg)

<p align="center">
  <strong>The simple directory tree viewer for Neovim written in Lua.</strong>
</p>

![Carbon banner](/doc/assets/carbon-banner.gif)

Carbon.nvim uses Neovim's fantastic Lua API to provide an optimal tree view
of the parent working directory and synchronizes changes to the file system
automatically. It does not handle renaming/moving, creating, or deleting
files or folders.

## Installation

Install on Neovim v0.7.0+ using your favorite plugin manager:

[vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'SidOfc/carbon.nvim'
```

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```viml
use 'SidOfc/carbon.nvim'
```

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
    settings.setting = 'value';
  end)
EOF
```

**init.lua**

```lua
require('carbon').setup(function(settings)
  settings.setting = 'value';
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

![Carbon / Explore command example](/doc/assets/carbon-explore.gif)

The `:Carbon` command replaces the current buffer with a Carbon buffer.
When `:h carbon-setting-keep-netrw` is `false` then NetRW's `:Explore`
command is aliased to `:Carbon`.

#### Lcarbon / Lexplore

![Lcarbon / Lexplore command example](/doc/assets/carbon-lexplore.gif)

The `:Lcarbon` command opens a Carbon buffer in a split to the left of the
current buffer. When `:h carbon-setting-keep-netrw` is `false` then NetRW's
`:Lexplore` command is aliased to `:Lcarbon`.

### Mappings

See `:h carbon-plugs` for more detailed information about mappings and their
customization options.

#### Move root up

Mapping: <kbd>[</kbd>

Moves Carbon's root directory up one level and rerender. See `:h carbon-plug-up`
for more information and customization options. Accepts a **count** to go up
multiple levels at once.

![Carbon up example](/doc/assets/carbon-up.gif)

#### Move root down

Mapping: <kbd>]</kbd>

Moves Carbon's root directory down one level and rerender. See
`:h carbon-plug-down` for more information and customization options. Accepts
a **count** to go down multiple levels at once on compressed paths.

![Carbon down example](/doc/assets/carbon-down.gif)

#### Reset root

Mapping: <kbd>.</kbd>

Resets Carbon's root directory back to the directory Neovim is opened with.
See `:h carbon-plug-reset` for more information and customization options.

![Carbon reset example](/doc/assets/carbon-reset.gif)

#### Edit file or toggle directory

Mapping: <kbd>enter</kbd>

When on a directory, expand or collapse that directory. When on a file, edit
that file in the current buffer and hide Carbon. This mapping works differently
when Carbon is opened with `:Lcarbon`. See `:h carbon-plug-edit` for more
information and customization options.

![Carbon edit example](/doc/assets/carbon-edit.gif)

#### Edit file in horizontal split

Mapping: <kbd>ctrl</kbd>+<kbd>x</kbd>

Does nothing when on a directory. Edit a file in a new horizontal split. See
`:h carbon-plug-split` for more information and customization points.

![Carbon split example](/doc/assets/carbon-split.gif)

#### Edit file in vertical split

Mapping: <kbd>ctrl</kbd>+<kbd>v</kbd>

Does nothing when on a directory. Edit a file in a new vertical split. See
`:h carbon-plug-vsplit` for more information and customization points.

![Carbon vsplit example](/doc/assets/carbon-vsplit.gif)
