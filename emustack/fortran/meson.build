

subdir('lib')

lflags = ['-lcholmod', '-lcolamd', '-lcamd', '-lmetis', '-lccolamd', '-lamd', 
  '-lsuitesparseconfig', '-lrt', '-llapack', '-lblas', '-lumfpack']

# Compiler-specific options
fortran_flags = ['-g', '-O3', '-fimplicit-none', '-fallow-argument-mismatch']

dependencies = [py_dep]

incdir_numpy = run_command(py,
  ['-c', 'import os; os.chdir(".."); import numpy; print(numpy.get_include())'],
  check : true
).stdout().strip()

incdir_f2py = run_command(py,
    ['-c', 'import os; os.chdir(".."); import numpy.f2py; print(numpy.f2py.get_include())'],
    check : true
).stdout().strip()

inc_np = include_directories(incdir_numpy, incdir_f2py, '.')

python_subroutines = files(['py_calc_modes.f', 'py_calc_modes_1d.f', 'conv_gmsh.f',
	'gmsh_plot_field_3d.f', 'gmsh_plot_field.f', 'gmsh_plot_PW.f', 'field_value_plane.f',
	'gmsh_plot_slice.f'])

fortran_files = files(['field_value_plane.f', 'write_sol.f', 'csr_length.f', 'phi3_2d_mat.f', 
'array_sol_1d.f', 'periodic_cond_1d.f', 'z_mxv_csc_64.f', 'list_face.f', 'J_overlap_1d.f',
 'asmbly_1d.f', 'lattice_vec.f', 'gmsh_post_process.f', 'csr_max_length.f', 
 'list_node_P3.f', 'pw_ordering_1d.f', 'jacobian_p1_2d.f', 'py_calc_modes_1d.f', 
 'phi1_2d_mat.f', 'mode_energy.f', 'zarpack_util.f', 'periodic_N_E_F.f', 
 'array_sol.f', 'basis_vec.f', 'zarpack.f', 'orthogonal_1d.f', 'array_sol_P2_1d.f', 
 'vector_p2_exp_1d.f', 'gmsh_plot_field_3d.f', 'quad_triangle.f', 'slice_interp.f', 
 'valpr_lapack_1d.f', 'phi2_2d_mat_J.f', 'ivalue.f', 'J_dagger_overlap.f', 
 'Completeness.f', 'sort_n.f', 'vector_p3_exp_1d.f', 'gmsh_plot_slice.f', 
 'type_node_edge_face.f', 'sort_int.f', 'orthogonal.f', 'jacobian_p2_2d.f', 
 'J_dagger_overlap_1d.f', 'matrix_kyx_1d.f', 'normalisation_1d.f', 
 'pw_matrix_1d_to_2d.f', 'periodic_node.f', 'matrix_kxy_1d.f', 'gmsh_interface_c4.f', 
 'asmbly.f', 'gmsh_plot_field.f', 'normalisation.f', 'curved_elem_tri.f', 
 'interp_nod_2d.f', 'conv_gmsh.f', 'bound_cond.f', 'gmsh_plot_PW.f', 'z_indexx.f', 
 'basis_ls.f', 'gmsh_interface_cyl.f', 'sort_csr.f', 'geometry.f', 'py_calc_modes.f', 
 'periodic_cond.f', 'matrix_mxx_1d.f', 'pw_ordering.f', 'conv_gmsh_subroutines.f', 
 'write_sol_P2_1d.f', 'valpr_umf_64.f', 'get_coord_p3.f', 'list_edge.f', 
 'matrix_kyy_1d.f', 'J_overlap.f', 'matrix_myy_1d.f', 'phi2_2d_mat.f'])


emustack_source = custom_target('libemustackmodule.c',
  input :  python_subroutines,
  output : ['libemustackmodule.c', 'libemustack-f2pywrappers.f'],
  command : [py, '-m', 'numpy.f2py', '@INPUT@',  '-m', 'libemustack', '--lower', '--build-dir', 'emustack/fortran'],
)


py.extension_module('libemustack',
  python_subroutines + fortran_files + emustack_source,
  incdir_f2py / 'fortranobject.c',
  include_directories: inc_np,
  dependencies : dependencies,
  fortran_args: fortran_flags + lflags,
  install : true,
  link_with: libumf4_f77,
  subdir: 'emustack/fortran'
)


