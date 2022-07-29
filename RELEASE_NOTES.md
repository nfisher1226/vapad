Contents
========
- [Unreleased](#unreleased)
- [0.1.0](#0.1.0)

## Unreleased
* Make program name, version, and authors constants in application.vala
* When opening files the `FileChooserDialog` will open in the folder containing
  the current file
* Use the GtkSource provided `FileLoader` and `FileSaver` classes to do async io
* Make sure window title gets set after `save_as` action
* Set smart home, end and backspace key handling
* Open files from command line
* Implement advanced search find and replace methods
* Link to LibAdwaita and begin transition to Gnome HIG (alexkdeveloper)
  * Subclass from Adw.ApplicationWindow instead of Gtk.ApplicationWindow
  * Use Adw.HeaderBar
  * Add symbolic icons for open and save buttons in headerbar
  * Add Adw.ToastOverlay for in app notifications
* Display message on file save using AdwToast

## 0.1.0
First basic proof of concept release.

Features:
* Load/Edit/Save files
* Syntax highlighting and line numbers on by default
* Keyboard shortcuts for all editor actions
* Search forward and back (wraps by default)

Unimplemented features:
* Advanced search
* Search and replace
* Preferences for font and color scheme

