
c_compiler = meson.get_compiler('c')

umfpack_dep_tmp = c_compiler.find_library('umfpack')

umfpack_inc_dir = '/home/bench/prg/mambaforge/envs/oslumen/include/suitesparse'

umfpack_dep = declare_dependency(dependencies : [ umfpack_dep_tmp ],
  include_directories: include_directories(umfpack_inc_dir))

libumf4_f77 = library('umf4_f77zwrapper64.o', 'umf4_f77zwrapper64.c',
    dependencies: umfpack_dep, install: true)