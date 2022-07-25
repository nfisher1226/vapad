Contents
========
* [Introduction](#introduction)
* [Building](#building)
* [Keyboard Shortcuts](#keyboard_shortcuts)

## Introduction
This is a simple text editor written in Vala, and is little more than a learning
exercise undertaken to explore using Vala. It's not expected to turn into
anything serious. Vapad takes as inspiration the old Gtk2 editor
[Leafpad](http://tarot.freeshell.org/leafpad/) which has been around forever,
but updates the interface somewhat and adds tabs and syntax highlighting.
Printing is not yet supported and there are not any user-customizable settings,
although those features are planned.

On the plus side, the resulting binary is just 52K on my system and thus well
suited to minimalist installations.

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
```
The result should be a binary at build/src/vapad. This binary can be run from
there or placed into your $PATH. There are currently no other files which need
to be installed (the icons and .desktop file in the source distribution are
placeholders).

## Keyboard Shortcuts
| Action | Shortcut |
| --- | --- |
| New File | <Ctrl>N |
| Open File | <Ctrl>O |
| Save File | <Ctrl>S |
| Save As | <Ctrl><Shift>S |
| Close Tab | <Ctrl>W |
| Close Window | <Ctrl>Q |
| Next Tab | <Alt>Right |
| Previous Tab | <Alt>Left |
| Go To Tab[number] | <Alt>number |
| Go to last Tab | <Alt>0 |

