c*******************************************************
c
c     mail_to_gmsh: covert the GMSH mesh format to the FEM mesh format
c
c*******************************************************
c
c     nnodes : Number of nodes per element (10-node second order tetrahedron)
c
c*******************************************************
c
      subroutine mail_to_gmsh (nel, npt, nnodes, type_el, 
     *  type_nod, table_nod, nb_typ_el, n_eff, 
     *  x, gmsh_file)

c
      implicit none
      integer*8 nel, npt, nnodes, nb_typ_el
      integer*8 type_el(nel), type_nod(npt)
      integer*8 table_nod(nnodes,nel)
      integer*8 max_typ_el
      parameter (max_typ_el=10)
      complex*16 x(2,npt), n_eff(max_typ_el), r_index
c
      integer*8 gmsh_version

      integer*8 ui
c      double precision time1, time2

      character gmsh_file*100

      integer*8 i, j, k
      integer*8 gmsh_type_line, gmsh_type_tri, gmsh_type_tetra
      integer*8 gmsh_type_node
      integer*8 number_tags, physic_tag, list_tag(6)
      integer*8 choice_type, typ_e
      integer*8 type_data(max_typ_el)

      double precision  r_tmp, zz
c
ccccccccccccccccccccccccc
c
      ui = 6
      gmsh_version = 2
      choice_type = 3
c
c     For choice_type = 3, the user provide a map for the types
c
      if(nb_typ_el .gt. max_typ_el) then
         write(ui,*)
         write(ui,*) "   ???"
         write(ui,*) "mail_to_gmsh: nb_typ_el > max_typ_el : ", 
     *    nb_typ_el, max_typ_el
         write(ui,*) "mail_to_gmsh: Aborting..."
         stop
      endif
      if (nb_typ_el .eq. 1) then
        type_data(nb_typ_el) = 10
      else
        do i=1,nb_typ_el
          r_tmp = (dble(i-1)/dble(nb_typ_el-1))
          type_data(i) = 1 + 18.0d0*r_tmp
        enddo
      endif
c
cccccc
c     elment type: defines the geometrical type
c     3-node second order line
      gmsh_type_line = 8
c     6-node second order triangle
      gmsh_type_tri = 9
c     10-node second order tetrahedron
      gmsh_type_tetra = 11
c     1-node point
      gmsh_type_node = 15
cccccc

      gmsh_version = 2
        if(gmsh_version .eq. 2) then
          number_tags = 6
          physic_tag = 4
          list_tag(2) = gmsh_type_tri
          list_tag(3) = number_tags - 3
          list_tag(5) = 1
          list_tag(6) = 0
        else
          number_tags = 5
          physic_tag = 3
          list_tag(2) = gmsh_type_tri
          list_tag(4) = 4
          list_tag(5) = nnodes
        endif
c
ccccccccccccccccccccccccccccccccccccc
c

      open (unit=26,file=gmsh_file)
        if(gmsh_version .eq. 2) then
          write(26,'(a11)') "$MeshFormat"
          write(26,'(3(I1,1x))') 2, 0, 8
          write(26,'(a14)') "$EndMeshFormat"
          write(26,'(a6)') "$Nodes"
        endif
        if(gmsh_version .eq. 1) then
          write(26,'(a4)') "$NOD"
        endif
        write(26,'(I0.1)') npt
        zz = 0.0d0
        do i=1,npt
          write(26,'(I0.1,3(g25.16))') i, (dble(x(j,i)),j=1,2), zz
        enddo
        if(gmsh_version .eq. 2) then
          write(26,'(a9)') "$EndNodes"
          write(26,'(a9)') "$Elements"
        endif

        if(gmsh_version .eq. 1) then
          write(26,'(a7)') "$ENDNOD"
          write(26,'(a4)') "$ELM"
        endif

        write(26,'(I0.1)') nel

      do i=1,nel
        list_tag(1) = i
        if (choice_type .eq. 1) then
          list_tag(physic_tag) = type_el(i)
          list_tag(physic_tag+1) = type_el(i)
        elseif (choice_type .eq. 2) then
          typ_e = type_el(i)
          r_index = n_eff(typ_e)
          list_tag(physic_tag) = r_index
          list_tag(physic_tag+1) = r_index
        elseif (choice_type .eq. 3) then
          list_tag(physic_tag) = type_data(type_el(i))
          list_tag(physic_tag+1) = type_data(type_el(i))
        else
          write(*,*) "mail_to_gmsh: no action is defined when ", 
     *      " choice_type = ", choice_type
          write(*,*) "mail_to_gmsh: Aborting..."
          stop
        endif
        write(26,'(100(I0.1,2x))') (list_tag(k), k=1,number_tags), 
     *      (table_nod(k,i), k=1,nnodes)
      enddo

        if(gmsh_version .eq. 2) then
          write(26,'(a12)') "$EndElements"
        endif

        if(gmsh_version .eq. 1) then
          write(26,'(a7)') "$ENDELM"
        endif
      close(26)

      return
      end
