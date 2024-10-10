
project('emustack','fortran','c',
  meson_version: '>=0.64.0',
  default_options : ['warning_level=2'],
)

py_mod = import('python')
py = py_mod.find_installation(pure: false)
py_dep = py.dependency()

subdir('emustack')
