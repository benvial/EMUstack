# Makefile for EMUstack. Requires some adjustment to reflect your installation.



export FFLAGS := $(FFLAGS) -fallow-argument-mismatch

# COMPILER_VENDOR = gnu95
# #COMPILER_VENDOR = intelem

SUBROUTINES_FOR_PYTHON = py_calc_modes.f py_calc_modes_1d.f conv_gmsh.f \
	gmsh_plot_field_3d.f gmsh_plot_field.f gmsh_plot_PW.f field_value_plane.f \
	gmsh_plot_slice.f

LIB_LOCATION = $(CONDA_PREFIX)/lib
UMFPACK_NAME = umf4_f77zwrapper64
LIB_UMFPACK_LOCATION = $(PWD)/lib
# LIB_UMFPACK_LOCATION = $(LIB_LOCATION)

# UMFPACK_NAME = umf4_f77zwrapper_SS_4.2.0
# LIB_UMFPACK_LOCATION = $(PWD)/lib/old

.PHONY: EMUstack.pyf $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME).o


# ### --- IF using Fedora SuiteSparse --------------------------------------
# EMUstack.so: EMUstack.pyf *.f
# 	f2py -c EMUstack.pyf *.f --f77flags='-fallow-argument-mismatch' --fcompiler=$(COMPILER_VENDOR) \
# 	--link-lapack_opt --link-blas_opt \
# 	$(LIB_LOCATION)/$(UMFPACK_NAME) --link-umfpack

# ### With installed libsuitesparse v. < 4.0.0
# lib/umf4_f77zwrapper64.o: lib/umf4_f77zwrapper_SS_3.7.1.c
# 	gcc -O5 -DZLONG -I/usr/include/suitesparse -c lib/umf4_f77zwrapper_SS_3.7.1.c \
# 		-fPIC -o lib/umf4_f77zwrapper64.o
## With installed libsuitesparse v. >= 4.0.0
## 12/2014 libsuitesparse >= 4.0.0 does not support 64 bit linux umf4_f77zwrapper64

# EMUstack.pyf: $(SUBROUTINES_FOR_PYTHON)
# 	f2py -m EMUstack -h EMUstack.pyf $(SUBROUTINES_FOR_PYTHON) --overwrite-signature

# purge:
# 	-rm EMUstack.pyf
# 	-rm EMUstack.so
# 	-rm lib/umf4_f77zwrapper64.o
# clean:
# 	-rm EMUstack.so
# ###------------------------------------------------------------------




# ### --- ELSE IF using self built SuiteSparse ------------------------
# EMUstack.so: EMUstack.pyf *.f
# 	FFLAGS="-fallow-argument-mismatch" f2py -c EMUstack.pyf *.f --fcompiler=$(COMPILER_VENDOR) \
#         --link-lapack_opt --link-blas_opt \
#         $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME) \
# 		--include-paths $(PWD) \
# 		--f77flags="-fallow-argument-mismatch" \
#         -L$(LIB_LOCATION) -lumfpack -lamd -lcholmod \
#         -lcolamd -lcamd -lmetis -lccolamd -lamd -lsuitesparseconfig -lrt \
# 		# --backend meson

# EMUstack.pyf: $(SUBROUTINES_FOR_PYTHON)
# 	FFLAGS="-fallow-argument-mismatch" f2py -m EMUstack -h EMUstack.pyf $(SUBROUTINES_FOR_PYTHON) --overwrite-signature \
# 		--include-paths $(PWD) \
# 		# --backend meson

all: purge $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME).o EMUstack.so test-import

### --- ELSE IF using self built SuiteSparse ------------------------
EMUstack.so: $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME).o EMUstack.pyf *.f
	f2py -c EMUstack.pyf *.f \
		--backend meson \
		--lower \
		--include-paths $(PWD):$(LIB_UMFPACK_LOCATION):$(CONDA_PREFIX)/include/suitesparse \
		-I$(PWD) \
		-I$(LIB_UMFPACK_LOCATION) \
		-I$(CONDA_PREFIX)/include/suitesparse \
		-L$(LIB_LOCATION)/$(UMFPACK_NAME).o \
        -lcholmod \
        -lcolamd -lcamd -lmetis -lccolamd -lamd -lsuitesparseconfig -lrt \
		-llapack -lblas -lumfpack --debug

EMUstack.pyf: $(SUBROUTINES_FOR_PYTHON)
	f2py -m EMUstack -h EMUstack.pyf $(SUBROUTINES_FOR_PYTHON) \
	--backend meson \
	--lower --overwrite-signature \
	-I$(LIB_UMFPACK_LOCATION) \
	-I$(PWD) \
	-I$(CONDA_PREFIX)/include/suitesparse \
	--include-paths $(PWD):$(LIB_UMFPACK_LOCATION):$(CONDA_PREFIX)/include/suitesparse
		
# lib/umf4_f77zwrapper64.o: lib/umf4_f77zwrapper_SS_4.2.0.c
# 	$(CC) -O5 -DZLONG -I$(CONDA_PREFIX)/include/suitesparse -c lib/umf4_f77zwrapper_SS_4.2.0.c \
#       -fPIC -o lib/umf4_f77zwrapper64.o

$(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME).o: $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME).c
	$(CC) -O3 -DZLONG  \
		-lumfpack \
		-I$(PWD) \
		-I$(LIB_UMFPACK_LOCATION) \
		-I$(CONDA_PREFIX)/include/suitesparse \
	-c $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME).c \
	-fPIC -o $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME).o

purge:
	rm -rf $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME).o
	rm -f EMUstack.pyf
	rm -f EMUstack*.so
clean:
	rm -f EMUstack*.so
###------------------------------------------------------------------



test-import:
	# python -c "from emustack.stack import *"
	python -c "import EMUstack"


meson:
	rm -rf builddir
	meson setup builddir
	meson compile -C builddir


# meson: 
# 	FFLAGS="-fallow-argument-mismatch" f2py -c EMUstack.pyf *.f --fcompiler=$(COMPILER_VENDOR) \
#         --link-lapack_opt --link-blas_opt \
#         $(LIB_UMFPACK_LOCATION)/$(UMFPACK_NAME) \
# 		--include-paths $(PWD) \
# 		--f77flags="-fallow-argument-mismatch" \
#         -L$(LIB_LOCATION) -lumfpack -lamd -lcholmod \
#         -lcolamd -lcamd -lmetis -lccolamd -lamd -lsuitesparseconfig -lrt \
# 		--backend meson --build-dir mesontest