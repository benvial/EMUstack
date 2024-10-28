
PROJECT_NAME := "emustack"

BRANCH := "$(git branch --show-current)"

PROJECT_DIR := "$(realpath $PWD)"

VERSION := """$(python3 -c "import toml; print(toml.load('pyproject.toml')['project']['version'])")"""

version:
    @echo {{VERSION}}

doc:
    cd docs && make html

show:
    firefox docs/build/html/index.html

fortran:
    cd emustack/fortran && make clean && make

clean:
    rm -rf builddir build .coverage *.egg-info docs/build .pytest_cache htmlcov .ruff_cache
    cd examples && rm -rf  *.txt *.log *.npz *.png *.pdf *.csv
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
    cd builddir/emustack/fortran && python -c "import libemustack"


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