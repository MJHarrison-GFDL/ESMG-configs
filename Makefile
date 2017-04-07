SHELL = bash -f
site = linux
platform = gnu

all: test_suite_gnu

compile_libs:
	mkdir -p build/shared.$(platform).repro
	(cd build/shared.$(platform).repro/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/FMS; \
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(site)-$(platform).mk -p libfms.a -o '-I/usr/local/include' -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS" path_names; \
	source ../../build/env/$(site)-$(platform); make  NETCDF=4 REPRO=1 libfms.a)

	mkdir -p build/MOM6.$(platform).repro
	(cd build/MOM6.$(platform).repro/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/MOM6/{config_src/dynamic_symmetric,config_src/solo_driver/coupler_types*,src/*,src/*/*,pkg/*/src/*}   ;\
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(site)-$(platform).mk -o '-I/usr/local/include -I../../src/FMS/include -I../shared.$(platform).repro' -p libMOM6.a -l '-L../shared.$(platform).repro -lfms' -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS -Duse_AM3_physics" path_names; \
	source ../../build/env/$(site)-$(platform); make  NETCDF=4 REPRO=1 -j 8 libMOM6.a)

compile_MOM6_solo: compile_libs
	mkdir -p build/MOM6_solo.$(platform).repro
	(cd build/MOM6_solo.$(platform).repro/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/MOM6/config_src/solo_driver/*  ;\
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(site)-$(platform).mk -o  '-I../../src/MOM6/src/framework -I../../src/MOM6/config_src/dynamic_symmetric -I../MOM6.$(platform).repro -I../shared.$(platform).repro' -l '-L../MOM6.$(platform).repro -lMOM6 -L../shared.$(platform).repro -lfms -L/usr/local/lib -lmpi -lmpifort -lnetcdf -lnetcdff' -p MOM6 -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS -Duse_AM3_physics" path_names; \
	source ../../build/env/$(site)-$(platform); make  NETCDF=4 REPRO=1 -j 8 MOM6)


test_suite_gnu: compile_MOM6_solo
	(cd ocean_only/circle_obcs;mpirun -n 1 ../../build/MOM6_solo.gnu.repro/MOM6 >&output; echo "circle_obcs 1pe :" | tee  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/circle_obcs;mpirun -n 4 ../../build/MOM6_solo.gnu.repro/MOM6 >&output; echo "circle_obcs 4pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/Channel;mpirun -n 1 ../../build/MOM6_solo.gnu.repro/MOM6 >&output; echo "Channel 1pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/Channel;mpirun -n 4 ../../build/MOM6_solo.gnu.repro/MOM6 >&output; echo "Channel 4pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/seamount/z;mpirun -n 4 ../../../build/MOM6_solo.gnu.repro/MOM6 >&output; echo "Seamount 4pe :" | tee -a  ../../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/DOME;mpirun -n 4 ../../build/MOM6_solo.gnu.repro/MOM6 >&output; echo "DOME 4pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/Tidal_bay;mpirun -n 4 ../../build/MOM6_solo.gnu.repro/MOM6 >&output; echo "Tidal Bay 4pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
