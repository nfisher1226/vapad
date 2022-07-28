vapad_sources = [
  'main.vala',
  'window.vala',
  'application.vala',
  'tab.vala',
  'search_dialog.vala'
]

vapad_deps = [
  dependency('gtk4'),
  dependency('gtksourceview-5'),
]

gnome = import('gnome')

vapad_sources += gnome.compile_resources('vapad-resources',
  'vapad.gresource.xml',
  c_name: 'vapad'
)

executable('vapad', vapad_sources,
  vala_args: '--target-glib=2.50',  dependencies: vapad_deps,
  install: true,
)
