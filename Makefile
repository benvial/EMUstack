.PHONY: emustack

emustack:
	cd emustack/fortran/ && make purge && make clean && make
