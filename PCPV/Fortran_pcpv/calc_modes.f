      subroutine calc_modes(
c     Explicit inputs
     *    parallel, lambda, nval, ordre_ls, d_in_nm,
     *    debug, mesh_file, mesh_format, npt, nel,
     *    n_eff,
     *    substrate, bloch_vec, h_1, h_2, num_h, lx, ly, tol, 
     *    E_H_field, i_cond, itermax, pol, traLambda, PropModes,
     *    PrintSolution, PrintSupModes, PrintOmega, PrintAll,
     *    Checks, q_average, plot_real, plot_imag, plot_abs,
     *    incident, what4incident, out4incident, Loss, title,
     *    neq_PW, Zeroth_Order,
c     "Optional" inputs (Python guesses these)
     *    nb_typ_el,
c     Outputs
     *    beta1, mode_pol, T12, R12, T21, R21)
C************************************************************************
C
C  Program:
C    Finite Element Method - Scattering Matrix Method (FEM-SMM)
C     for Photonic Crystal Photovoltaics
C
C  Authors:
C    Bjorn Sturmberg & Kokou B. Dossou
C
C************************************************************************
C
      implicit none
C  Local parameters:
      integer*8 int_max, cmplx_max, int_used, cmplx_used
      integer*8 real_max, real_used, n_64
C      parameter (int_max=2**22, cmplx_max=2**26)
C      parameter (real_max=2**21)
C     !   a(int_max)
      integer*8, dimension(:), allocatable :: a
C     !  b(cmplx_max)
      complex*16, dimension(:), allocatable :: b
C     !  c(real_max)
      double precision, dimension(:), allocatable :: c
      integer :: allocate_status=0
C
C  Declare the pointers of the integer super-vector
      integer*8 ip_table_E, ip_table_N_E_F, ip_visite
      integer*8 ip_type_N_E_F, ip_eq
      integer*8 ip_period_N, ip_nperiod_N
      integer*8 ip_period_N_E_F, ip_nperiod_N_E_F
C      integer*8 ip_col_ptr, ip_bandw 
C  Declare the pointers of the real super-vector
      integer*8 jp_x_N_E_F
C      integer*8 jp_matD, jp_matL, jp_matU
C      integer*8 jp_matD2, jp_matL2, jp_matU2
      integer*8 jp_vect1, jp_vect2, jp_workd, jp_resid, jp_vschur
      integer*8 jp_eigenval_tmp, jp_trav, jp_vp
      integer*8 jp_overlap_L
      integer*8 jp_T, jp_R
C  Plane wave parameters
      integer*8 neq_PW, nx_PW, ny_PW, ordre_ls
      integer*8 index_pw_inv(neq_PW)
      integer*8 Zeroth_Order, Zeroth_Order_inv, nb_typ_el
      complex*16 pp(nb_typ_el),  qq(nb_typ_el)
      complex*16 eps_eff(nb_typ_el), n_eff(nb_typ_el), test
      double precision n_eff_0, n_eff_sub, eps_eff_sub
c     i_cond = 0 => Dirichlet boundary condition
c     i_cond = 1 => Neumann boundary condition
c     i_cond = 2 => Periodic boundary condition
      integer*8 nel, npt, nnodes, ui, i_cond
C     ! Number of nodes per element
      parameter(nnodes=6)
      integer*8 type_nod(npt), type_el(nel), table_nod(nnodes, nel)
C, len_skyl, nsym
c     E_H_field = 1 => Electric field formulation (E-Field)
c     E_H_field = 2 => Magnetic field formulation (H-Field)
      integer*8 E_H_field
      integer*8 neq, debug
      integer*8 npt_p3, numberprop_S, numberprop_N, numberprop_S_b
C  Variable used by valpr
      integer*8 nval, nvect, itermax, ltrav
      integer*8 n_conv, i_base
      double precision ls_data(10)
c      integer*8 pointer_int(20), pointer_cmplx(20)
      integer*8 index(1000), n_core(2)
      complex*16 z_beta, z_tmp, z_tmp0
      integer*8 n_edge, n_face, n_ddl, n_ddl_max, n_k
c     variable used by UMFPACK
      double precision control (20), info_umf (90)
      integer*8 numeric, status, filenum
C  Renumbering
c      integer*8 ip_row_ptr, ip_bandw_1, ip_adjncy
c      integer*8 len_adj, len_adj_max, len_0_adj_max
c, iout, nonz_1, nonz_2
      integer*8 i, j, mesh_format
c     Wavelength lambda is in normalised units of d_in_nm
      double precision lambda
      double precision freq, lat_vecs(2,2), tol
      double precision k_0, pi, lx, ly, bloch_vec(2), bloch_vec_k(2)
      complex*16 shift
C  Timing variables
      double precision time1, time2
      double precision time1_fact, time2_fact
      double precision time1_asmbl, time2_asmbl
      double precision time1_postp, time2_postp
      double precision time1_arpack, time2_arpack
      double precision time1_J, time2_J
      character*(8) start_date, end_date
      character*(10) start_time, end_time
C  Names and Controls
      character mesh_file*100, gmsh_file*100, log_file*100
      character gmsh_file_pos*100
      character overlap_file*100, dir_name*100, buf1*4, buf2*4
      character*100 tchar
      integer*8 namelength, PrintAll, PrintOmega, Checks, traLambda
      integer*8 PrintSolution, pol, PrintSupModes
      integer*8 substrate, num_h
      integer*8 PropModes
C     Thicknesses h_1 and h_2 are in normalised units of d_on_lambda
      double precision h_1, h_2, hz
      integer*8 d_in_nm, pair_warning, parallel, Loss
      integer*8 incident, what4incident, out4incident
      integer*8 q_average, plot_real, plot_imag, plot_abs
      integer*8 title
C  SuperMode Plotting
      complex*16 vec_coef(1000)
      complex*16 vec_coef_down(1000)
      complex*16 vec_coef_up(1000)

c     Declare the pointers of the real super-vector
      integer*8 kp_rhs_re, kp_rhs_im, kp_lhs_re, kp_lhs_im
      integer*8 kp_mat1_re, kp_mat1_im

c     Declare the pointers of for sparse matrix storage
      integer*8 ip_col_ptr, ip_row
      integer*8 jp_mat2
      integer*8 ip_work, ip_work_sort, ip_work_sort2
      integer*8 nonz, nonz_max, max_row_len

      integer*8 ip
      integer i_32

c     new breed of variables to prise out of a, b and c
      complex*16 x_arr(2,npt)
      complex*16, target :: sol1(3,nnodes+7,nval,nel)
      complex*16, target :: sol2(3,nnodes+7,nval,nel)
      complex*16, pointer :: sol(:,:,:,:)
      complex*16 sol_avg(3, npt)
      complex*16 overlap_J(2*neq_PW, nval)
      complex*16 overlap_J_dagger(nval, 2*neq_PW)
      complex*16 overlap_K(nval, 2*neq_PW)
      complex*16 X_mat(2*neq_PW, 2*neq_PW)
      complex*16 X_mat_b(2*neq_PW, 2*neq_PW)

      complex*16, target :: beta1(nval), beta2(nval)
      complex*16, pointer :: beta(:)
      complex*16 mode_pol(4,nval)
c     Fresnel scattering matrices
      complex*16 T12(nval,2*neq_PW)
      complex*16 R12(2*neq_PW,2*neq_PW)
      complex*16 T21(2*neq_PW,nval)
      complex*16 R21(nval,nval)

      complex*16 T_Lambda(2*neq_PW, 2*neq_PW)
      complex*16 R_Lambda(2*neq_PW, 2*neq_PW)
 
Cf2py intent(out) beta1, mode_pol, T12, R12, T21, R21


      n_64 = 2
C     !n_64**28 on Vayu
      cmplx_max=n_64**27
C     Felix is subtracting off the size of matrices he's extracted.
C     mode_pol
      cmplx_max = cmplx_max - nval*4
C     T12, R12, T21, R21
      cmplx_max = cmplx_max - (2*neq_PW + nval)**2
      real_max=n_64**22
      int_max=n_64**22
c      3*npt+nel+nnodes*nel 

      !write(*,*) "cmplx_max = ", cmplx_max
      !write(*,*) "real_max = ", real_max
      !write(*,*) "int_max = ", int_max

      allocate(b(cmplx_max), STAT=allocate_status)
      if (allocate_status /= 0) then
        write(*,*) "The allocation is unsuccessful"
        write(*,*) "allocate_status = ", allocate_status
        write(*,*) "Not enough memory for the complex array b"
        write(*,*) "cmplx_max = ", cmplx_max
        write(*,*) "Aborting..."
        stop
      endif

      allocate(c(real_max), STAT=allocate_status)
      if (allocate_status /= 0) then
        write(*,*) "The allocation is unsuccessful"
        write(*,*) "allocate_status = ", allocate_status
        write(*,*) "Not enough memory for the real array c"
        write(*,*) "real_max = ", real_max
        write(*,*) "Aborting..."
        stop
      endif

      allocate(a(int_max), STAT=allocate_status)
      if (allocate_status /= 0) then
        write(*,*) "The allocation is unsuccessful"
        write(*,*) "allocate_status = ", allocate_status
        write(*,*) "Not enough memory for the integer array a"
        write(*,*) "int_max = ", int_max
        write(*,*) "Aborting..."
        stop
      endif


      

CCCCCCCCCCCCCCCCC POST F2PY CCCCCCCCCCCCCCCCCCCCCCCCC

C     clean mesh_format
      namelength = len_trim(mesh_file)
      gmsh_file = mesh_file(1:namelength-5)//'.msh'
      gmsh_file_pos = mesh_file(1:namelength)
      log_file = mesh_file(1:namelength-5)//'.log'
      if (debug .eq. 1) then
        write(*,*) "mesh_file = ", mesh_file
        write(*,*) "gmsh_file = ", gmsh_file
      endif    

c     Calculate effective permittivity
      do i_32 = 1, int(nb_typ_el)
        eps_eff(i_32) = n_eff(i_32)**2
      end do

C     !ui = Unite dImpression
      ui = 6
C     ! Number of nodes per element
      pi = 3.141592653589793d0
C      nsym = 1 ! nsym = 0 => symmetric or hermitian matrices
C
      nvect = 2*nval + nval/2 +3

CCCCCCCCCCCCCCCCC END POST F2PY CCCCCCCCCCCCCCCCCCCCC

C     ! initial time  in unit = sec.
      call cpu_time(time1)
      call date_and_time ( start_date, start_time )
C      
      if (debug .eq. 1) then
        write(ui,*)
        write(ui,*) "start_date = ", start_date
        write(ui,*) "start_time = ", start_time
        write(ui,*) "MAIN: ord_PW = ", ordre_ls
        write(ui,*) "MAIN: neq_PW = ", neq_PW
        write(ui,*)
      endif
C
      pair_warning = 0
C
C####################  Start FEM PRE-PROCESSING  ########################
C
      if (debug .eq. 1) then
        write(ui,*)
        write(ui,*) "lx,ly = ", lx, ly
        write(ui,*) "npt, nel, nnodes = ", npt, nel, nnodes
        write(ui,*) "mesh_file = ", mesh_file
        write(ui,*)
      endif
C
      if ((3*npt+nel+nnodes*nel) .gt. int_max) then
         write(ui,*) "MAIN: (3*npt+nel+nnodes*nel) + npt > int_max : ",
     *    (3*npt+nel+nnodes*nel), int_max
         write(ui,*) "MAIN: increase the size of int_max"
         write(ui,*) "MAIN: Aborting..."
         stop
      endif
      if ((7*npt) .gt. cmplx_max) then
         write(ui,*) "MAIN: (7*npt) > cmplx_max : ",
     *    (7*npt), cmplx_max
         write(ui,*) "MAIN: increase the size of cmplx_max"
         write(ui,*) "MAIN: Aborting..."
         stop
      endif
C
      call geometry (nel, npt, nnodes, nb_typ_el,
     *     lx, ly, type_nod, type_el, table_nod, 
     *     x_arr, mesh_file)
C
      if (PrintSupModes + PrintSolution .ge. 1) then
C  Export the mesh to gmsh format
        call mail_to_gmsh (nel, npt, nnodes, type_el, 
     *    type_nod, table_nod, 
     *    nb_typ_el, n_eff, x_arr, gmsh_file)
C
C        call gmsh_interface_cyl (nel, npt, nnodes, type_el, 
C     *    type_nod, table_nod, 
C     *    nb_typ_el, x_arr)
      endif
C
      call lattice_vec (npt, x_arr, lat_vecs)
C
C     if (PrintSupModes + PrintSolution .ge. 1) then
C        call gmsh_interface_c4 (nel, npt, nnodes, type_el, 
C     *    type_nod, table_nod, 
C     *    nb_typ_el, x_arr, lat_vecs)
C      endif
C
C      V = number of vertices
C      E = number of edges
C      F =  number of faces
C      C =  number of cells (3D, tetrahedron)
C
C     From Euler's theorem on 3D graphs: V-E+F-C = 1 - (number of holes)
C     npt = (number of vertices) + (number of mid-edge point) = V + E;
C
C     ! each element is a face
      n_face = nel
      ip_table_N_E_F = 1
      call list_face (nel, a(ip_table_N_E_F))

C     n_ddl_max = max(N_Vertices) + max(N_Edge) + max(N_Face)
C     For P2 FEM npt=N_Vertices+N_Edge
C     note: each element has 1 face, 3 edges and 10 P3 nodes
      n_ddl_max = npt + n_face
      ip_visite =  ip_table_N_E_F  + 14*nel 
      ip_table_E = ip_visite + n_ddl_max
C
      call list_edge (nel, npt, nnodes, n_edge, 
     *    type_nod, table_nod, 
     *    a(ip_table_E), a(ip_table_N_E_F), a(ip_visite))
      call list_node_P3 (nel, npt, nnodes, n_edge, npt_p3, 
     *    table_nod, a(ip_table_N_E_F), a(ip_visite))
      n_ddl = n_edge + n_face + npt_p3
C
      if (debug .eq. 1) then
        write(ui,*) "MAIN: npt, nel = ", npt, nel
        write(ui,*) "MAIN: npt_p3 = ", npt_p3
        write(ui,*) "MAIN: n_vertex, n_edge, n_face, nel = ", 
     *    (npt - n_edge), n_edge, n_face, nel
        write(ui,*) "MAIN: 2D case of the Euler characteristic : ",
     *    "V-E+F=1-(number of holes)"
        write(ui,*) "MAIN: Euler characteristic: V - E + F = ", 
C     !  - nel
     *    (npt - n_edge) - n_edge + n_face
      endif
cC
cC-----------
cC
cC     overwriting pointers ip_row_ptr, ..., ip_adjncy
c
      ip_type_N_E_F = ip_table_E + 4*n_edge
C
      jp_x_N_E_F = 1
      call type_node_edge_face (nel, npt, nnodes, n_ddl, 
     *      type_nod, table_nod, a(ip_table_N_E_F), 
     *      a(ip_visite), a(ip_type_N_E_F), 
     *      x_arr, b(jp_x_N_E_F))
C
      call get_coord_p3 (nel, npt, nnodes, n_ddl, 
     *      table_nod, type_nod, a(ip_table_N_E_F), 
     *      a(ip_type_N_E_F), x_arr, b(jp_x_N_E_F), a(ip_visite))
C
        ip_period_N = ip_type_N_E_F + 2*n_ddl
        ip_nperiod_N = ip_period_N + npt
        ip_period_N_E_F = ip_nperiod_N + npt
        ip_nperiod_N_E_F = ip_period_N_E_F + n_ddl
        ip_eq = ip_nperiod_N_E_F + n_ddl
C
      if (i_cond .eq. 0 .or. i_cond .eq. 1) then
        call bound_cond (i_cond, n_ddl, neq, a(ip_type_N_E_F), 
     *    a(ip_eq))
      elseif(i_cond .eq. 2) then
        if (debug .eq. 1) then
          write(ui,*) "###### periodic_node"
        endif
        call periodic_node(nel, npt, nnodes, type_nod, 
     *      x_arr, a(ip_period_N), a(ip_nperiod_N),
     *      table_nod, lat_vecs)
        if (debug .eq. 1) then
          write(ui,*) "MAIN: ###### periodic_N_E_F"
        endif
        call periodic_N_E_F (n_ddl, a(ip_type_N_E_F), 
     *      b(jp_x_N_E_F), a(ip_period_N_E_F), 
     *      a(ip_nperiod_N_E_F), lat_vecs)
        call periodic_cond (i_cond, n_ddl, neq, a(ip_type_N_E_F),
     *       a(ip_period_N_E_F), a(ip_eq), debug)
      else
        write(ui,*) "MAIN: i_cond has invalid value : ", i_cond
        write(ui,*) "MAIN: Aborting..."
        stop
      endif
C
      if (debug .eq. 1) then
        write(ui,*) "MAIN: neq, n_ddl = ", neq, n_ddl
      endif
C
C=====calcul du vecteur de localisation des colonnes
C     pour le traitement skyline de la matrice globale
C     Type of sparse storage of the global matrice:
C                                   Symmetric Sparse Skyline format
C     Determine the pointer for the Symmetric Sparse Skyline format
c
c      ip_col_ptr = ip_eq + 3*n_ddl
c      ip_bandw  = ip_col_ptr + neq + 1
c      int_used = ip_bandw + neq + 1
cC
c      if (int_max .lt. int_used) then
c        write(ui,*)
c        write(ui,*) 'The size of the integer supervector is too small'
c        write(ui,*) 'integer super-vec: int_max  = ', int_max
c        write(ui,*) 'integer super-vec: int_used = ', int_used
c        write(ui,*) 'Aborting...'
c        stop
c      endif
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c
c     Sparse matrix storage
c
      ip_col_ptr = ip_eq + 3*n_ddl

      call csr_max_length (nel, n_ddl, neq, nnodes, 
     *  a(ip_table_N_E_F), a(ip_eq), a(ip_col_ptr), nonz_max)
c
c      ip = ip_col_ptr + neq + 1 + nonz_max
      ip = ip_col_ptr + neq + 1
      if (ip .gt. int_max) then
         write(ui,*) "main: ip > int_max : ",
     *    ip, int_max
         write(ui,*) "main: nonz_max = ", nonz_max
         write(ui,*) "main: increase the size of int_max"
         write(ui,*) "main: Aborting..."
         stop
      endif
c
      ip_row = ip_col_ptr + neq + 1

      call csr_length (nel, n_ddl, neq, nnodes, a(ip_table_N_E_F), 
     *  a(ip_eq), a(ip_row), a(ip_col_ptr), nonz_max, 
     *  nonz, max_row_len, ip, int_max, debug)

      ip_work = ip_row + nonz
      ip_work_sort = ip_work + 3*n_ddl
      ip_work_sort2 = ip_work_sort + max_row_len

c     sorting csr ...
      call sort_csr (neq, nonz, max_row_len, a(ip_row), 
     *  a(ip_col_ptr), a(ip_work_sort), a(ip_work), 
     *  a(ip_work_sort2))

      if (debug .eq. 1) then
        write(ui,*) "main: nonz_max = ", nonz_max
        write(ui,*) "main: nonz = ", nonz
        write(ui,*) "main: cmplx_max/nonz = ", 
     *    dble(cmplx_max)/dble(nonz)
      endif

      int_used = ip_work_sort2 + max_row_len

      if (int_max .lt. int_used) then
        write(ui,*)
        write(ui,*) 'The size of the integer supervector is too small'
        write(ui,*) 'integer super-vec: int_max  = ', int_max
        write(ui,*) 'integer super-vec: int_used = ', int_used
        write(ui,*) 'Aborting...'
        stop
      endif
c
cccccccccccccccccccccccccccccccccccccccccccccccccc
c
cC
      jp_mat2 = jp_x_N_E_F + 3*n_ddl

      jp_vect1 = jp_mat2 + nonz
      jp_vect2 = jp_vect1 + neq
      jp_workd = jp_vect2 + neq
      jp_resid = jp_workd + 3*neq

C     ! Eigenvectors
      jp_vschur = jp_resid + neq
      jp_eigenval_tmp = jp_vschur + neq*nvect
      jp_trav = jp_eigenval_tmp + nval + 1

      ltrav = 3*nvect*(nvect+2)
      jp_vp = jp_trav + ltrav
      jp_overlap_L = jp_vp + neq*nval
      jp_T = jp_overlap_L + nval*nval
      jp_R = jp_T + 2*neq_PW*2*neq_PW
 
      cmplx_used = jp_R + 2*neq_PW*2*neq_PW

      write(ui,*) "cmplx_max  = ", cmplx_max
      write(ui,*) "cmplx_used = ", cmplx_used
C
      if (cmplx_max .lt. cmplx_used)  then
         write(ui,*) 'The size of the real supervector is too small'
         write(ui,*) 'real super-vec: cmplx_max  = ', cmplx_max
         write(ui,*) 'real super-vec: cmplx_used = ', cmplx_used
         write(ui,*) 'Aborting...'
         stop
      endif
c
      kp_rhs_re = 1
      kp_rhs_im = kp_rhs_re + neq
      kp_lhs_re = kp_rhs_im + neq
      kp_lhs_im = kp_lhs_re + neq
      kp_mat1_re = kp_lhs_im + neq
      kp_mat1_im = kp_mat1_re + nonz
      real_used = kp_mat1_im + nonz

      if (real_max .lt. real_used) then
        write(ui,*)
        write(ui,*) 'The size of the real supervector is too small'
        write(ui,*) '2*nonz  = ', 2*nonz
        write(ui,*) 'real super-vec: real_max  = ', real_max
        write(ui,*) 'real super-vec: real_used = ', real_used
        write(ui,*) 'Aborting...'
        stop
      endif
c
c
c###############################################
c
c       ----------------------------------------------------------------
c       convert from 1-based to 0-based
c       ----------------------------------------------------------------
c
      do j = 1, neq+1
          a(j+ip_col_ptr-1) = a(j+ip_col_ptr-1) - 1
      end do
      do  j = 1, nonz
          a(j+ip_row-1) = a(j+ip_row-1) - 1
      end do
c
c
c     The CSC indexing, i.e., ip_col_ptr, is 1-based 
c       (but valpr.f will change the CSC indexing to 0-based indexing)
      i_base = 0
c
C
C#####################  End FEM PRE-PROCESSING  #########################
C
C

      if (PropModes .eq. 1) then
        if (Loss .eq. 0) then
          open(unit=200, file="SuperModes"//buf2//".txt",
     *           status="unknown")   
        endif
        open(unit=565, file="detAe"//buf2//".txt",
     *         status="unknown")
        open(unit=566, file="detAo"//buf2//".txt",
     *         status="unknown")
      endif
C
C
C
C#####################  Loop over Wavelengths  ##########################
C
      write(ui,*) 
      write(ui,*) "--------------------------------------------",
     *     "-------"
      write(ui,*) "MAIN: Wavelength Slice", parallel
C
        n_eff_0 = DBLE(n_eff(1))
        freq = 1.0d0/lambda
        k_0 = 2.0d0*pi*n_eff_0*freq
C
C  Index number of the core materials (material with highest Re(eps_eff))
      if(dble(eps_eff(3)) .gt. dble(eps_eff(4))) then
          n_core(1) = 3
      else
          n_core(1) = 4
      endif
      n_core(2) = n_core(1)
      shift = 1.01d0*Dble(n_eff(n_core(1)))**2 * k_0**2
     *    - bloch_vec(1)**2 - bloch_vec(2)**2
      If(debug .eq. 1) then
        write(ui,*) "MAIN: n_core = ", n_core
        if(E_H_field .eq. 1) then
          write(ui,*) "MAIN: E-Field formulation"
        else
          write(ui,*) "MAIN: H-Field formulation"
        endif
      EndIf
C
C
         if(E_H_field .eq. 1) then
           do i=1,nb_typ_el
             qq(i) = eps_eff(i)*k_0**2
             pp(i) = 1.0d0
           enddo
         elseif(E_H_field .eq. 2) then
           do i=1,nb_typ_el
             qq(i) = k_0**2
             pp(i) = 1.0d0/eps_eff(i)
           enddo
         else
           write(ui,*) "MAIN: action indef. avec E_H_field = ", 
     *                  E_H_field
           write(ui,*) "Aborting..."
           stop
         endif
C
CCCCCCCCCCCCCCCCCCCC  Loop over Adjoint and Prime  CCCCCCCCCCCCCCCCCCCCCC
C
         do n_k = 1,2
C
           if (n_k .eq. 1) then
             dir_name = "Output"
             sol => sol1
             beta => beta1
             bloch_vec_k = bloch_vec
           else
             dir_name = "Output-"
             sol => sol2
             beta => beta2
             bloch_vec_k = -bloch_vec
           endif  
           namelength = len_trim(dir_name)
C
C     Assemble the coefficient matrix A and the right-hand side F of the
C     finite element equations
      if (debug .eq. 1) then
        write(ui,*) "MAIN: Asmbly: call to asmbly"
      endif
      call cpu_time(time1_asmbl)
      call asmbly (i_cond, i_base, nel, npt, n_ddl, neq, nnodes,
     *  shift, bloch_vec_k, nb_typ_el, pp, qq, table_nod, 
     *  a(ip_table_N_E_F), type_el, a(ip_eq),
     *   a(ip_period_N), a(ip_period_N_E_F), x_arr, b(jp_x_N_E_F), 
     *   nonz, a(ip_row), a(ip_col_ptr), c(kp_mat1_re), 
     *   c(kp_mat1_im), b(jp_mat2), a(ip_work))
      call cpu_time(time2_asmbl)
C
C     factorization of the globale matrice
C     -----------------------------------
C
      if (debug .eq. 1) then
        write(ui,*) "MAIN:        Adjoint(1) / Prime(2)", n_k
c        write(ui,*) "MAIN: factorisation: call to znsy"
      endif
C
      if (debug .eq. 1) then
        write(ui,*) "MAIN: call to valpr"
      endif
      call valpr_64 (i_base, nvect, nval, neq, itermax, ltrav,
     *  tol, nonz, a(ip_row), a(ip_col_ptr), c(kp_mat1_re),
     *  c(kp_mat1_im), b(jp_mat2), b(jp_vect1), b(jp_vect2),
     *  b(jp_workd), b(jp_resid), b(jp_vschur), beta,
     *  b(jp_trav), b(jp_vp), c(kp_rhs_re), c(kp_rhs_im),
     *  c(kp_lhs_re), c(kp_lhs_im), n_conv, ls_data,
     *  numeric, filenum, status, control, info_umf, debug)
c
      if (n_conv .ne. nval) then
         write(ui,*) "MAIN: convergence problem with valpr_64"
         write(ui,*) "MAIN: n_conv != nval : ",
     *    n_conv, nval
         write(ui,*) "n_core(1), n_eff(n_core(1)) = ",
     *                n_core(1), n_eff(n_core(1))
         write(ui,*) "MAIN: Aborting..."
         stop
      endif
c
      time1_fact = ls_data(1)
      time2_fact = ls_data(2)
c
      time1_arpack = ls_data(3)
      time2_arpack = ls_data(4)
C
      do i=1,nval
        z_tmp0 = beta(i)
        z_tmp = 1.0d0/z_tmp0+shift
        z_beta = sqrt(z_tmp)
C       Mode classification - we want the forward propagating mode
        if (abs(imag(z_beta)) .lt. 1.0d-8) then
C         re(z_beta) > 0 for forward propagating mode
          if (dble(z_beta) .lt. 0) z_beta = -z_beta
        else
C         im(z_beta) > 0 for forward decaying evanescent mode
          if (imag(z_beta) .lt. 0) z_beta = -z_beta
        endif
C     !  Effective index
C        z_beta = sqrt(z_tmp)/k_0
        beta(i) = z_beta
      enddo
c
      call cpu_time(time1_postp)
C
      call z_indexx (nval, beta, index)
C
C       The eigenvectors will be stored in the array sol
C       The eigenvalues and eigenvectors will be renumbered  
C                 using the permutation vector index
        call array_sol (i_cond, nval, nel, npt, n_ddl, neq, nnodes, 
     *   n_core, bloch_vec_k, index, table_nod, 
     *   a(ip_table_N_E_F), type_el, a(ip_eq), a(ip_period_N), 
     *   a(ip_period_N_E_F), x_arr, b(jp_x_N_E_F), beta, 
     *   b(jp_eigenval_tmp), mode_pol, b(jp_vp), sol)
C
      if(debug .eq. 1) then
        write(ui,*) 'index = ', (index(i), i=1,nval)
      endif
      if(debug .eq. 1) then
        write(ui,*)
        write(ui,*) "lambda, 1/lambda = ", lambda, 1.0d0/lambda
        write(ui,*) (bloch_vec_k(i)/(2.0d0*pi),i=1,2)
        write(ui,*) "sqrt(shift) = ", sqrt(shift)
        do i=1,nval
          write(ui,"(i4,2(g22.14),2(g18.10))") i, 
     *       beta(i)
        enddo
      endif
C
C  Dispersion Diagram
      if (PrintOmega .eq. 1 .and. n_k .eq. 2) then
        call mode_energy (nval, nel, npt, n_ddl, nnodes, 
     *     n_core, table_nod, type_el, nb_typ_el, eps_eff, 
     *     x_arr, sol, beta, mode_pol)
C        call DispersionDiagram(lambda, bloch_vec_k, shift,
C     *     nval, n_conv, beta, mode_pol, d_in_nm)
      endif
C
      enddo
C
CCCCCCCCCCCCCCCCCCCCCCCC  End Prime, Adjoint Loop  CCCCCCCCCCCCCCCCCCCCCC
C

CCCC Hardcore Debugging - Print all arrays + some variables CCCCC
      if (debug .eq. 2) then
        PrintAll = 1
        Checks = 2

        open (unit=1111,file="Normed/Debug_data.txt", status='unknown')
        write(1111,*) "lambda = ", lambda
        write(1111,*) "eps_eff = ", (eps_eff(i),i=1,nb_typ_el)
        write(1111,*) "shift = ", shift
        write(1111,*) "bloch_vec(1) = ", bloch_vec(1)
        write(1111,*) "bloch_vec(2) = ", bloch_vec(2) 
        write(1111,*) "k_0 = ", k_0
        write(1111,*) 
        do i=1,nval
          write(1111,"(i4,2(g22.14),g18.10)") i, 
     *       beta1(i)
        enddo
      endif
CCCC Hardcore Debugging - End                               CCCCC

C  Orthogonal integral
      if (debug .eq. 1) then 
        write(ui,*) "MAIN: Field product"
      endif
      overlap_file = "Normed/Orthogonal.txt"
      call cpu_time(time1_J)
      call orthogonal (nval, nel, npt, nnodes, 
     *  nb_typ_el, pp, qq, table_nod, 
     *  type_el, x_arr, beta1, beta2,
     *  sol1, sol2, b(jp_overlap_L),
     *  overlap_file, PrintAll, d_in_nm, pair_warning, k_0)
      call cpu_time(time2_J)
      if (debug .eq. 1) then
        write(ui,*) "MAIN: CPU time for orthogonal :",
     *  (time2_J-time1_J)
      endif     
C    Save Original solution
      if (PrintSolution .eq. 1) then
        dir_name = "Output/Fields"
        call write_sol (nval, nel, nnodes, E_H_field, lambda,
     *       beta1, sol1, mesh_file, dir_name)
        call write_param (E_H_field, lambda, npt, nel, i_cond,
     *       nval, nvect, itermax, tol, shift, lx, ly, 
     *       mesh_file, mesh_format, n_conv, nb_typ_el, eps_eff,
     *       bloch_vec, dir_name)
      tchar = "Output/FieldsPNG/All_plots_png_abs2_eE.geo"
      open (unit=34,file=tchar)
        do i=1,nval
          call gmsh_post_process (i, E_H_field, nval, nel, npt, 
     *       nnodes, table_nod, type_el, nb_typ_el,
     *       n_eff, x_arr, beta1, sol1,
     *       sol_avg, a(ip_visite), gmsh_file_pos, dir_name, 
     *       q_average, plot_real, plot_imag, plot_abs)
        enddo 
      close (unit=34)
      endif
C        
C  Normalisation
      if(debug .eq. 1) then
        write(ui,*) "MAIN: Field  Normalisation"
      endif 
      call cpu_time(time1_J)
      call normalisation (nval, nel, nnodes, table_nod,
     *  sol1, sol2, b(jp_overlap_L))  
      call cpu_time(time2_J)
      if (debug .eq. 1) then
        write(ui,*) "MAIN: CPU time for normalisation :",
     *  (time2_J-time1_J)
      endif  
C
C  Orthonormal integral
      if (PrintAll .eq. 1) then
        write(ui,*) "MAIN: Product of normalised field"
        overlap_file = "Normed/Orthogonal_n.txt"
        call cpu_time(time1_J)
        call orthogonal (nval, nel, npt, nnodes, 
     *    nb_typ_el, pp, qq, table_nod, 
     *    type_el, x_arr, beta1, beta2,
     *    sol1, sol2, b(jp_overlap_L),
     *    overlap_file, PrintAll, d_in_nm, pair_warning, k_0)
        call cpu_time(time2_J)
          write(ui,*) "MAIN: CPU time for orthogonal :",
     *    (time2_J-time1_J)
      endif
C


CCCCCC CUT HERE CCCCCC

      write(buf1,'(I4.4)') title
      write(buf2,'(I4.4)') parallel

      if (traLambda .eq. 1) then
        if (pol .eq. 0) then
          open(643,file="st"//buf1//"_wl"//buf2//
     *    "_T_Lambda.txt",status='unknown')
          open(644,file="st"//buf1//"_wl"//buf2//
     *    "_R_Lambda.txt",status='unknown')
          open(645,file="st"//buf1//"_wl"//buf2//
     *    "_A_Lambda.txt",status='unknown')
          open(660,file="st"//buf1//"_wl"//buf2//
     *    "_T_MAT_sp.txt",status='unknown')
          open(661,file="st"//buf1//"_wl"//buf2//
     *    "_R_MAT_sp.txt",status='unknown')
        elseif (pol .eq. 5) then
          open(643,file="st"//buf1//"_wl"//buf2//
     *    "_T_Lambda_R.txt",status='unknown')
          open(644,file="st"//buf1//"_wl"//buf2//
     *    "_R_Lambda_R.txt",status='unknown')
          open(645,file="st"//buf1//"_wl"//buf2//
     *    "_A_Lambda_R.txt",status='unknown')
          open(646,file="st"//buf1//"_wl"//buf2//
     *    "_T_Lambda_L.txt",status='unknown')
          open(647,file="st"//buf1//"_wl"//buf2//
     *    "_R_Lambda_L.txt",status='unknown')
          open(648,file="st"//buf1//"_wl"//buf2//
     *    "_A_Lambda_L.txt",status='unknown')
          open(649,file="st"//buf1//"_wl"//buf2//
     *    "_T_Lambda_CD.txt",status='unknown')
          open(650,file="st"//buf1//"_wl"//buf2//
     *    "_R_Lambda_CD.txt",status='unknown')
          open(651,file="st"//buf1//"_wl"//buf2//
     *    "_A_Lambda_CD.txt",status='unknown')
          open(660,file="st"//buf1//"_wl"//buf2//
     *    "_T_MAT_lr.txt",status='unknown')
          open(661,file="st"//buf1//"_wl"//buf2//
     *    "_R_MAT_lr.txt",status='unknown')
          open(662,file="st"//buf1//"_wl"//buf2//
     *    "_T_phase_lr.txt",status='unknown')
          open(663,file="st"//buf1//"_wl"//buf2//
     *    "_R_phase_lr.txt",status='unknown')
        else
          open(643,file="st"//buf1//"_wl"//buf2//
     *    "_T_Lambda.txt",status='unknown')
          open(644,file="st"//buf1//"_wl"//buf2//
     *    "_R_Lambda.txt",status='unknown')
          open(645,file="st"//buf1//"_wl"//buf2//
     *    "_A_Lambda.txt",status='unknown')
        endif
      endif

C  Plane wave ordering
      call pw_ordering (neq_PW, lat_vecs, bloch_vec, 
     *  index_pw_inv, Zeroth_Order, Zeroth_Order_inv, 
     *  debug, ordre_ls, k_0)
C  J_overlap
      if (debug .eq. 1) then
        write(ui,*) "MAIN: J_overlap Integral"
      endif
      call cpu_time(time1_J)
      call J_overlap (nval, nel, npt, nnodes, 
     *  nb_typ_el, type_el, table_nod, x_arr, 
     *  sol1, pp, qq, lat_vecs, lambda, freq, n_eff_0,
     *  overlap_J, neq_PW, bloch_vec, X_mat, numberprop_S,
     *  index_pw_inv, PrintAll, debug, ordre_ls, k_0)
      call cpu_time(time2_J)
      if (debug .eq. 1) then
        write(ui,*) "MAIN: CPU time for J_overlap :",
     *  (time2_J-time1_J)
      endif
C
C  J_dagger_overlap
      if (debug .eq. 1) then
        write(ui,*) "MAIN: J_dagger_overlap Integral"
      endif
      call cpu_time(time1_J)
      call J_dagger_overlap (nval, nel, npt, nnodes, 
     *  nb_typ_el, type_el, table_nod, x_arr, 
     *  sol2, pp, qq, lat_vecs, lambda, freq,
     *  overlap_J_dagger, neq_PW, bloch_vec,
     *  index_pw_inv, PrintAll, ordre_ls)
      call cpu_time(time2_J)
      if (debug .eq. 1) then
        write(ui,*) "MAIN: CPU time for J_dagger_overlap :",
     *  (time2_J-time1_J)
      endif
C
C  Overlaps at bottom Substrate
      if (substrate .eq. 1) then
        n_eff_sub = DBLE(n_eff(2))
        eps_eff_sub = DBLE(eps_eff(2))
      call J_overlap_sub ( lat_vecs, lambda, freq, n_eff_sub,
     *  eps_eff_sub, neq_PW, bloch_vec, X_mat_b, numberprop_S_b,
     *  index_pw_inv, PrintAll, ordre_ls, k_0)
C  Scattering Matrices
      if (debug .eq. 1) then
        write(ui,*) "MAIN: Scattering Matrices substrate"
      endif



      call ScatMat_sub ( overlap_J, overlap_J_dagger,  
     *    X_mat, X_mat_b, neq_PW, nval, 
     *    beta1, T12, R12, T21, R21,
     *    PrintAll, PrintSolution, 
     *    lx, h_1, h_2, num_h, Checks, T_Lambda, 
     *    R_Lambda, traLambda, pol, PropModes, lambda, d_in_nm,
     *    numberprop_S, numberprop_S_b, freq, Zeroth_Order_inv,
     *    debug, incident, what4incident, out4incident,
     *    title, parallel)
C     !No Substrate
      else
C  Scattering Matrices
      if (debug .eq. 1) then
        write(ui,*) "MAIN: Scattering Matrices"
      endif
      call ScatMat( overlap_J, overlap_J_dagger,  
     *    X_mat, neq_PW, nval, 
     *    beta1, T12, R12, T21, R21,
     *    PrintAll, PrintSolution, 
     *    lx, h_1, h_2, num_h, Checks, T_Lambda, 
     *    R_Lambda, traLambda, pol, PropModes, lambda, d_in_nm,
     *    numberprop_S, freq, Zeroth_Order_inv,
     *    debug, incident, what4incident, out4incident,
     *    title, parallel)
C     !End Substrate Options
      endif
C
      if (traLambda .eq. 1) then
        if (pol .eq. 0) then
          close(643)
          close(644)
          close(645)
          close(660)
          close(661)
          close(662)
          close(663)
        elseif (pol .eq. 5) then
          close(643)
          close(644)
          close(645)
          close(646)
          close(647)
          close(648)
          close(649)
          close(650)
          close(651)
          close(660)
          close(661)
          close(662)
          close(663)
        else
          close(643)
          close(644)
          close(645)
        endif
      endif

      if (debug .eq. 2) then
        write(1111,*) 
        write(1111,*) "neq_PW = ", neq_PW
        write(1111,*) "numberprop_S = ", numberprop_S
        if (substrate .eq. 1) then
          write(1111,*) "numberprop_S_b = ", numberprop_S_b
        endif
        write(1111,*) "Zeroth_Order = ", Zeroth_Order
        write(1111,*) "Zeroth_Order_inv = ", Zeroth_Order_inv
      PrintAll = 0
      Checks = 0
      endif
C     
C  Search for number of propagating Bloch Modes
      if (PropModes .eq. 1 .and. Loss .eq. 0) then
      numberprop_N = 0
      do i=1,nval
        test = beta1(i)
        if (ABS(IMAG(test)) .lt. 1.0d-5) then
          numberprop_N = numberprop_N + 1
        endif
      enddo
      write(200,*) lambda*d_in_nm, numberprop_N
      endif
C
C  Plot superposition of fields
      if (PrintSupModes .eq. 1) then
C     Coefficent of the modes travelling downward 
      do i=1,nval
        vec_coef(i) = T12(1,i)
      enddo
C     Coefficent of the modes travelling upward 
      do i=1,nval
        vec_coef(i+nval) = 0.0d0
      enddo
      dir_name = "Output/Fields"
C     ! hz=0 => top interface; hz=h => bottom interface
      hz = 0.0d0
C     ! reference number of the field
      i = 1
      call gmsh_plot_field (i, E_H_field, nval, nel, npt, 
     *     nnodes, table_nod, type_el, eps_eff, x_arr,  
     *     beta1, sol1, sol_avg, 
     *     vec_coef, h_1, hz, gmsh_file_pos, dir_name, nb_typ_el, 
     *       q_average, plot_real, plot_imag, plot_abs)
C
C     ! hz=0 => top interface; hz=h => bottom interface
      hz = h_1
C     ! reference number of the field
      i = 2
      call gmsh_plot_field (i, E_H_field, nval, nel, npt, 
     *     nnodes, table_nod, type_el, eps_eff, x_arr,
     *     beta1, sol1, sol_avg, 
     *     vec_coef, h_1, hz, gmsh_file_pos, dir_name, nb_typ_el, 
     *       q_average, plot_real, plot_imag, plot_abs)

      do i=1,2*neq_PW
        vec_coef_down(i) = 0.0d0
      enddo
C     ! Incident field
      vec_coef_down(1) = 1.0d0
      do i=1,2*neq_PW
C     ! Reflected field
        vec_coef_up(i) = R12(1,i)
      enddo

C     ! Upper semi-inifinite medium: Plane wave expansion
      hz = 0.0d0
      i = 1
      call gmsh_plot_PW (i, E_H_field, 
     *     nel, npt, nnodes, neq_PW, bloch_vec, 
     *  table_nod, x_arr, lat_vecs, lambda, eps_eff(1),
     *  sol_avg, vec_coef_down, vec_coef_up, 
     *  index_pw_inv, ordre_ls, h_1, hz, gmsh_file_pos,
     *  dir_name, q_average, plot_real, plot_imag, plot_abs)

C     ! Upper semi-inifinite medium: Plane wave expansion
      hz = h_1
      i = 2
      call gmsh_plot_PW (i, E_H_field, 
     *     nel, npt, nnodes, neq_PW, bloch_vec, 
     *  table_nod, x_arr, lat_vecs, lambda, eps_eff(1),
     *  sol_avg, vec_coef_down, vec_coef_up, 
     *  index_pw_inv, ordre_ls, h_1, hz, gmsh_file_pos,
     *  dir_name, q_average, plot_real, plot_imag, plot_abs)
      endif
C
C
      if (PropModes .eq. 1) then
        if (Loss .eq. 0) then
          close(200)
        endif
        close(565)
        close(566)
      endif
C
      if (pair_warning .ne. 0) then
        write(ui,*) "conjugate pair problem", pair_warning,
     *      "times, for d = ", d_in_nm
      endif
C
      call cpu_time(time2_postp)
C
CCCCCCCCCCCCCCCCCCCCC Calculation Checks CCCCCCCCCCCCCCCCCCCCC
C
C  Completeness Check
      if (Checks .eq. 1) then
        write(ui,*) "MAIN: K_overlap Integral"
        call K_overlap(nval, nel, npt, nnodes, 
     *    nb_typ_el, type_el, table_nod, x_arr,   
     *    sol2, pp, qq, lambda, freq, overlap_K, neq_PW,
     *    lat_vecs, bloch_vec, beta2, index_pw_inv,
     *    PrintAll, k_0, ordre_ls)
        write(ui,*) "MAIN: Completeness Test"
        call Completeness (nval, neq_PW, 
     *    overlap_K, overlap_J)
C  Search for number of propagating Bloch Modes
      numberprop_N = 0
      do i=1,nval
        test = beta1(i)
        if (ABS(IMAG(test)) .lt. 1.0d-5) then
          numberprop_N = numberprop_N + 1
        endif
      enddo
      write(ui,*) "numberprop_N = ", numberprop_N
C  Energy Conservation Check
        write(ui,*) "MAIN: Energy Check"
        call Energy_Cons(R12, T12, R21, T21,
     *    numberprop_S, numberprop_N, neq_PW, nval)
      endif 
C
C#########################  End Calculations  ###########################
C
      call date_and_time ( end_date, end_time )
      call cpu_time(time2)
C
      if (debug .eq. 1) then
        write(ui,*) 
        write(ui,*) 'Total CPU time (sec.)  = ', (time2-time1)

        open (unit=26,file=log_file)
        write(26,*)
        write(26,*) "Date and time formats = ccyymmdd ; hhmmss.sss"
        write(26,*) "Start date and time   = ", start_date, 
     *    " ; ", start_time
        write(26,*) "End date and time     = ", end_date, 
     *    " ; ", end_time
        write(26,*) "Total CPU time (sec.) = ",  (time2-time1)
        write(26,*) "LU factorisation : CPU time and % Total time = ",  
     *         (time2_fact-time1_fact), 
     *         100*(time2_fact-time1_fact)/(time2-time1),"%"
        write(26,*) "ARPACK : CPU time and % Total time = ",  
     *         (time2_arpack-time1_arpack), 
     *         100*(time2_arpack-time1_arpack)/(time2-time1),"%"
        write(26,*) "Assembly : CPU time and % Total time = ",  
     *         (time2_asmbl-time1_asmbl), 
     *         100*(time2_asmbl-time1_asmbl)/(time2-time1),"%"
        write(26,*) "Post-processsing : CPU time and % Total time = ",  
     *         (time2_postp-time1_postp), 
     *         100*(time2_postp-time1_postp)/(time2-time1),"%"
        write(26,*) "Pre-Assembly : CPU time and % Total time = ",  
     *         (time1_asmbl-time1), 
     *         100*(time1_asmbl-time1)/(time2-time1),"%"
        write(26,*)
        write(26,*) "lambda  = ", lambda
        write(26,*) "npt, nel, nnodes  = ", npt, nel, nnodes
        write(26,*) "neq, i_cond = ", neq, i_cond
        if ( E_H_field .eq. 1) then
          write(26,*) "E_H_field         = ", E_H_field,  
     *                 " (E-Field formulation)"
        elseif ( E_H_field .eq. 2) then
          write(26,*) "E_H_field         = ", E_H_field,  
     *                 " (H-Field formulation)"
       else
          write(ui,*) "MAIN (B): action indef. avec E_H_field = ", 
     *                 E_H_field
          write(ui,*) "Aborting..."
          stop
        endif
        write(26,*) "   bloch_vec = ", bloch_vec
        write(26,*) "bloch_vec/pi = ", (bloch_vec(i)/pi,i=1,2)
        z_tmp = sqrt(shift)/(2.0d0*pi)
        write(26,*) "shift             = ", shift, z_tmp
        write(26,*) "integer super-vector :"
        write(26,*) "int_used, int_max, int_used/int_max         = ", 
     *    int_used , int_max, dble(int_used)/dble(int_max)
        write(26,*) "cmplx super-vector : "
        write(26,*) "cmplx_used, cmplx_max, cmplx_used/cmplx_max = ",
     *     cmplx_used, cmplx_max, dble(cmplx_used)/dble(cmplx_max)
        write(26,*) "Real super-vector : "
        write(26,*) "real_used, real_max, real_max/real_used = ",
     *     real_used, real_max, dble(real_max)/dble(real_used)
        write(26,*)
        write(26,*) "neq_PW = ", neq_PW
        write(26,*) "nval, nvect, n_conv = ", nval, nvect, n_conv
        write(26,*) "nonz, npt*nval, nonz/(npt*nval) = ",
     *  nonz, npt*nval, dble(nonz)/dble(npt*nval)
        write(26,*) "nonz, nonz_max, nonz_max/nonz = ", 
     *  nonz, nonz_max, dble(nonz_max)/dble(nonz)
        write(26,*) "nonz, int_used, int_used/nonz = ", 
     *  nonz, int_used, dble(int_used)/dble(nonz)
c
c         write(26,*) "len_skyl, npt*nval, len_skyl/(npt*nval) = ",
c     *   len_skyl, npt*nval, dble(len_skyl)/dble(npt*nval)
c
        write(26,*) 
        do i=1,nval
          write(26,"(i4,2(g22.14),g18.10)") i, 
     *       beta1(i)
        enddo
        write(26,*)
        write(26,*) "n_core = ", n_core
        write(26,*) "eps_eff = ", (eps_eff(i),i=1,nb_typ_el)
        write(26,*) "n_eff = ", (n_eff(i),i=1,nb_typ_el)
        write(26,*)         
        write(26,*) "conjugate pair problem", pair_warning,
     *      "times, for d = ", d_in_nm
        write(26,*)
        write(26,*) "mesh_file = ", mesh_file
        write(26,*) "gmsh_file = ", gmsh_file
        write(26,*) "log_file  = ", log_file
        close(26)
C
        write(ui,*) "   .      .      ."
        write(ui,*) "   .      .      ."
        write(ui,*) "   .      . (d=",d_in_nm,")"

        write(ui,*) "  and   we're  done!"
      endif
C
      end subroutine calc_modes
