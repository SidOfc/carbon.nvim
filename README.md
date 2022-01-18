# Carbon.nvim

The simple directory tree viewer for Neovim written in Lua.

Carbon.nvim uses Neovim's fantastic Lua API to provide an optimal tree view
of the parent working directory and synchronizes changes to the file system
automatically. It does not handle renaming/moving, creating, or deleting
files or folders by the user.

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

See `:h carbon-setup` for a more detailed explanation on configuration.
See `:h carbon-carbon-setup` for documentation about the `.setup` method.

## Usage

Carbon comes with a few mappings out of the box, each is described below:

### Move root up

![Carbon up example](/doc/assets/carbon-up.gif)

Mapping: <kbd>[</kbd>

Moves Carbon's root directory up one level and rerender. See `:h carbon-plug-up`
for more information and customization options. Accepts a **count** to go up
multiple levels at once.

### Move root down

Mapping: <kbd>]</kbd>

Moves Carbon's root directory down one level and rerender. See
`:h carbon-plug-down` for more information and customization options. Accepts
a **count** to go down multiple levels at once on compressed paths.

### Reset root

Mapping: <kbd>.</kbd>

Resets Carbon's root directory back to the directory Neovim is opened with.
See `:h carbon-plug-reset` for more information and customization options.

### Edit file or toggle directory

Mapping: <kbd>enter</kbd>

When on a directory, expand or collapse that directory. When on a file, edit
that file in the current buffer and hide Carbon. This mapping works differently
when Carbon is opened with `:Lcarbon`. See `:h carbon-plug-edit` for more
information and customization options.

### Edit file in horizontal split

Mapping: <kbd>ctrl</kbd>+<kbd>x</kbd>

Does nothing when on a directory. Edit a file in a new horizontal split. See
`:h carbon-plug-split` for more information and customization points.

### Edit file in vertical split

Mapping: <kbd>ctrl</kbd>+<kbd>v</kbd>

Does nothing when on a directory. Edit a file in a new vertical split. See
`:h carbon-plug-vsplit` for more information and customization points.

