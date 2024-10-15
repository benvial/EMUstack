Installation
================


From source
------------

The source code for EMUstack is hosted `here on Github <https://github.com/benvial/EMUstack>`_. 
Please download the latest release from here, or clone the repository:
::
    git clone git@github.com:benvial/EMUstack.git
    cd EMUstack

The installation uses `Meson <https://mesonbuild.com/>`_ to compile the fortran routines and 
build their Python binders.

Dependencies
~~~~~~~~~~~~~

Using system packages
''''''''''''''''''''''

EMUstack has been developed on Ubuntu and is easiest to install on this platform. 
Simply `sudo apt-get install` the required packages

.. code-block:: bash

    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
    python3-full python3-pip python3-dev gcc gfortran make pkg-config cmake \
    libsuitesparse-dev liblapack-dev libopenblas-dev



Using conda/mamba
'''''''''''''''''''
.. code-block:: bash
    
    mamba env create -f environment.yml

Python package
~~~~~~~~~~~~~~~

Then install the package with `pip`

.. code-block:: bash
    
    pip install .


Docker
------------

See `Dockerfile`

.. code-block:: bash
    
    cd EMUstack
    mamba env create -f environment.yml
