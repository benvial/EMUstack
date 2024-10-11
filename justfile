
PROJECT_NAME := "pylatt"

BRANCH := "$(git branch --show-current)"

PROJECT_DIR := "$(realpath $PWD)"

VERSION := """$(python3 -c "from configparser import ConfigParser; p = ConfigParser(); p.read('setup.cfg'); print(p['metadata']['version'])")"""

doc:
    cd docs && make html


fortran:
    cd emustack/fortran && make clean && make

clean:
    rm -rf builddir .coverage *.egg-info docs/build .pytest_cache htmlcov
    cd docs && make clean

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


# Push to gitlab
gl:
    @git add -A
    @read -p "Enter commit message: " MSG; \
    git commit -a -m "$MSG"
    @git push origin {{BRANCH}}


# Clean, reformat and push to gitlab
save: gl


test:
    pytest