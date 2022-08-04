vapad_sources = [
  'main.vala',
  'window.vala',
  'application.vala',
  'tab.vala',
  'theme_switcher.vala',
  'search_dialog.vala'
]

vapad_deps = [
  dependency('gtk4'),
  dependency('gtksourceview-5'),
  dependency('libadwaita-1')
]

gnome = import('gnome')

vapad_sources += gnome.compile_resources('vapad-resources',
  'vapad.gresource.xml',
  c_name: 'vapad'
)

executable('vapad', vapad_sources,
  include_directories: config_h_dir,
  vala_args: ['--target-glib=2.68', meson.project_source_root() + '/src/config.vapi'],
  c_args: ['-include', 'config.h'],
  dependencies: vapad_deps,
  install: true,
)
