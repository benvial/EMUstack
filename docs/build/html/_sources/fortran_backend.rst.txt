==================
Fortran Backends
==================

The intention of EMUstack is that the Fortran FEM routines are essentially black boxes. They are called from mode_calcs.py and return the modes (Eigenvalues) of a structured layer, as well as some matrices of overlap integrals that are then used to compute the scattering matrices.

There are however a few important things to know about the workings of these routines.

.. toctree::
    :maxdepth: 4
    :hidden:

    fem_1d
    fem_2d

