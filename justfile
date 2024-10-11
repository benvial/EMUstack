

doc:
    cd docs && make html

test:
    pytest -svvv tests --cov=emustack

fortran:
    cd emustack/fortran && make clean && make

clean:
	rm -rf builddir .coverage *.egg-info docs/build .pytest_cache htmlcov

clean-fortran:
    cd emustack/fortran && make purge

test-import:
    python -c "from emustack.stack import *"

meson: set bld test-fortran

set:
    meson setup --wipe builddir

bld:
    meson compile -C builddir

test-fortran:
    cd builddir/emustack/fortran && python -c "import EMUstack"
