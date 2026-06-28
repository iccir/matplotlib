
add_languages('objc', native: false)
py3.extension_module(
  '_macosx',
  sources: files(
    '_macosx.m',
  ),
  dependencies: dependency('appleframeworks', modules: 'Cocoa'),
  override_options: ['werror=true'],
  objc_args: ['-fobjc-arc'],
  install: true,
  subdir: 'matplotlib/backends',
)
