Contents
========
* [Introduction](#introduction)
* [Features](#features)
* [Building](#building)
* [Keyboard Shortcuts](#keyboard_shortcuts)

## Introduction
This is a simple text editor written in Vala. It was undertaken as a learning
exercise to explore using Vala, but turned into a fairly feature complete text
editor.  Vapad takes as inspiration the old Gtk2 editor
[Leafpad](http://tarot.freeshell.org/leafpad/) which has been around forever,
but updates the interface somewhat and adds tabs and syntax highlighting.

Vapad does not have a plethora of configuration options, by design. Comfort
features like syntax highlighting and line numbers are considered a sane default
and thus are always on. Focus on your writing, not configuring your editor.

### Naming
In Star Wars lore, Mace Windu's style of lightsaber conflict was known as vaapad.
Anything involving both Samual L Jackson and Star Wars must by definition be
badass. Vapad is also a nice amalgam of Vala and Notepad, so it seemed a good fit.

## Features
- Syntax highlighting for all languages supported by GtkSourceView'
- Comfort features like line numbers, long line marker, and auto-indent on by default
- Tabbed interface
- Light and dark application themes using LibAdwaita
- Themeable syntax highlighting
- Quick search bar
- Advanced search including replace all in document/session/selection
- Simple and lightweight interface with no preferences window
- Standard keyboard shortcuts for all major interactions
- Vi emulation mode (requires Ibus)
- No preferences dialog - all settings via the application menu
- Translated into Russian, Spanish and German

## Building
Vapad requires Gtk+-4.0 or greater and GtkSourceView 5. You will also need to
have the Vala compiler (valac) installed, along with Meson and Ninja. Package
names for these packages will vary depending on your OS, and in some cases may
not yet be available. Be sure to also install the development headers for Gtk+
and GtkSourceView, if your OS ships them separate from the binaries (most mainline
Linux distros other than Arch). Once all dependencies are installed, open a
terminal and navigate to the source directory before issuing these commands.
```Sh
meson build
ninja -C build
# To install under /usr/local/bin
ninja -C build install
```

## Keyboard Shortcuts
| Action | Shortcut |
| --- | --- |
| New File | `<Ctrl>N` |
| Open File | `<Ctrl>O` |
| Save File | `<Ctrl>S` |
| Save As | `<Ctrl><Shift>S` |
| Save All | `<Ctrl><Shift>L` |
| Search | `<Ctrl>F` |
| Find Next | `<Ctrl>G` |
| Find Previous | `<Ctrl><Shift>G` |
| Hide Search | `<Shift>Escape` |
| Close Tab | `<Ctrl>W` |
| Close Window | `<Ctrl>Q` |
| Next Tab | `<Alt>Right` |
| Previous Tab | `<Alt>Left` |
| Go To Tab[number] | `<Alt>number` |
| Go to last Tab | `<Alt>0` |

