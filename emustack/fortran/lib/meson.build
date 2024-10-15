

## finding suitesparse the dependency way
ss_dep =  dependency('suitesparse', required:false)
if ss_dep.found() == false
  # find suitesparse installed with conda/mamba
  c_compiler = meson.get_compiler('c')
  umfpack_dep_tmp = c_compiler.find_library('umfpack')
  incdir_python= run_command(py,
      ['-c', 'import os; from sysconfig import get_paths; print(os.path.dirname(get_paths()["include"]))'],
      check : true
  ).stdout().strip()
  inc_ss = incdir_python + '/suitesparse'
  if run_command('[', '-d', inc_ss, ']').returncode() != 0
    inc_ss = '/usr/include/suitesparse'
  endif
  ss_dep = declare_dependency(dependencies : [ umfpack_dep_tmp ],
    include_directories: inc_ss)
endif
link_args = ['-fPIC', '-O5', '-DZLONG']
libumf4_f77 = library('umf4_f77zwrapper64.o', 'umf4_f77zwrapper64.c',
  dependencies: ss_dep, link_args: link_args, install: true)
