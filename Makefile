SHELL = bash -f
PLATFORM = linux
COMPILER = gnu
RESULTS_DEBUG = .results/$(PLATFORM)/$(COMPILER)/debug
RESULTS_REPRO = .results/$(PLATFORM)/$(COMPILER)/repro

all: test_solo

env:
	mkdir -p $(RESULTS_DEBUG);\
	mkdir -p $(RESULTS_REPRO);\

compile_libs: env
	mkdir -p build/shared.$(PLATFORM).$(COMPILER).debug
	(cd build/shared.$(PLATFORM).$(COMPILER).debug/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/FMS; \
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(PLATFORM)-$(COMPILER).mk -p libfms.a -o '-I/usr/local/include' -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS" path_names; \
	source ../../build/env/$(PLATFORM)-$(COMPILER); make  NETCDF=4 DEBUG=1 libfms.a)

	mkdir -p build/shared.$(PLATFORM).$(COMPILER).repro
	(cd build/shared.$(PLATFORM).$(COMPILER).repro/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/FMS; \
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(PLATFORM)-$(COMPILER).mk -p libfms.a -o '-I/usr/local/include' -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS" path_names; \
	source ../../build/env/$(PLATFORM)-$(COMPILER); make  NETCDF=4 REPRO=1 libfms.a)

	mkdir -p build/MOM6.$(PLATFORM).$(COMPILER).debug
	(cd build/MOM6.$(PLATFORM).$(COMPILER).debug/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/MOM6/{config_src/dynamic_symmetric,config_src/solo_driver/coupler_types*,src/*,src/*/*,pkg/*/src/*}   ;\
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(PLATFORM)-$(COMPILER).mk -o '-I/usr/local/include -I../../src/FMS/include -I../shared.$(PLATFORM).$(COMPILER).debug' -p libMOM6.a -l '-L../shared.$(PLATFORM).$(COMPILER).debug -lfms' -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS -Duse_AM3_physics" path_names; \
	source ../../build/env/$(PLATFORM)-$(COMPILER); make  NETCDF=4 DEBUG=1 -j 8 libMOM6.a)

	mkdir -p build/MOM6.$(PLATFORM).$(COMPILER).repro
	(cd build/MOM6.$(PLATFORM).$(COMPILER).repro/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/MOM6/{config_src/dynamic_symmetric,config_src/solo_driver/coupler_types*,src/*,src/*/*,pkg/*/src/*}   ;\
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(PLATFORM)-$(COMPILER).mk -o '-I/usr/local/include -I../../src/FMS/include -I../shared.$(PLATFORM).$(COMPILER).repro' -p libMOM6.a -l '-L../shared.$(PLATFORM).$(COMPILER).repro -lfms' -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS -Duse_AM3_physics" path_names; \
	source ../../build/env/$(PLATFORM)-$(COMPILER); make  NETCDF=4 REPRO=1 -j 8 libMOM6.a)

compile_MOM6_solo: compile_libs
	mkdir -p build/MOM6_solo.$(PLATFORM).$(COMPILER).debug
	(cd build/MOM6_solo.$(PLATFORM).$(COMPILER).debug/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/MOM6/config_src/solo_driver/*  ;\
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(PLATFORM)-$(COMPILER).mk -o  '-I../../src/MOM6/src/framework -I../../src/MOM6/config_src/dynamic_symmetric -I../MOM6.$(PLATFORM).$(COMPILER).debug -I../shared.$(PLATFORM).$(COMPILER).debug' -l '-L../MOM6.$(PLATFORM).$(COMPILER).debug -lMOM6 -L../shared.$(PLATFORM).$(COMPILER).debug -lfms -L/usr/local/lib -lmpi -lmpifort -lnetcdf -lnetcdff' -p MOM6 -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS -Duse_AM3_physics" path_names; \
	source ../../build/env/$(PLATFORM)-$(COMPILER); make  NETCDF=4 DEBUG=1 -j 8 MOM6)

	mkdir -p build/MOM6_solo.$(PLATFORM).$(COMPILER).repro
	(cd build/MOM6_solo.$(PLATFORM).$(COMPILER).repro/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/MOM6/config_src/solo_driver/*  ;\
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(PLATFORM)-$(COMPILER).mk -o  '-I../../src/MOM6/src/framework -I../../src/MOM6/config_src/dynamic_symmetric -I../MOM6.$(PLATFORM).$(COMPILER).repro -I../shared.$(PLATFORM).$(COMPILER).repro' -l '-L../MOM6.$(PLATFORM).$(COMPILER).repro -lMOM6 -L../shared.$(PLATFORM).$(COMPILER).repro -lfms -L/usr/local/lib -lmpi -lmpifort -lnetcdf -lnetcdff' -p MOM6 -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS -Duse_AM3_physics" path_names; \
	source ../../build/env/$(PLATFORM)-$(COMPILER); make  NETCDF=4 REPRO=1 -j 8 MOM6)


test_solo: compile_MOM6_solo
	(cd ocean_only/circle_obcs;mpirun -n 1 ../../build/MOM6_solo.$(PLATFORM).$(COMPILER).debug/MOM6 >&output; echo "circle_obcs 1pe :" | tee  ../../$(RESULTS_DEBUG)/results;diff -s ocean.stats ocean.stats.$(PLATFORM).$(COMPILER).debug | tee -a ../../$(RESULTS_DEBUG)/results)
	(cd ocean_only/circle_obcs;mpirun -n 4 ../../build/MOM6_solo.$(PLATFORM).$(COMPILER).debug/MOM6 >&output; echo "circle_obcs 4pe :" | tee -a  ../../$(RESULTS_DEBUG)/results;diff -s ocean.stats ocean.stats.$(PLATFORM).$(COMPILER).debug | tee -a ../../$(RESULTS_DEBUG)/results)
	(cd ocean_only/Channel;mpirun -n 1 ../../build/MOM6_solo.$(PLATFORM).$(COMPILER).debug/MOM6 >&output; echo "Channel 1pe :" | tee -a  ../../$(RESULTS_DEBUG)/results;diff -s ocean.stats ocean.stats.$(PLATFORM).$(COMPILER).debug | tee -a ../../$(RESULTS_DEBUG)/results)
	(cd ocean_only/Channel;mpirun -n 4 ../../build/MOM6_solo.$(PLATFORM).$(COMPILER).debug/MOM6 >&output; echo "Channel 4pe :" | tee -a  ../../$(RESULTS_DEBUG)/results;diff -s ocean.stats ocean.stats.$(PLATFORM).$(COMPILER).debug | tee -a ../../$(RESULTS_DEBUG)/results)
	(cd ocean_only/seamount/z;mpirun -n 4 ../../../build/MOM6_solo.$(PLATFORM).$(COMPILER).debug/MOM6 >&output; echo "Seamount 4pe :" | tee -a  ../../../$(RESULTS_DEBUG)/results;diff -s ocean.stats ocean.stats.$(PLATFORM).$(COMPILER).debug | tee -a ../../../$(RESULTS_DEBUG)/results)
	(cd ocean_only/DOME;mpirun -n 4 ../../build/MOM6_solo.$(PLATFORM).$(COMPILER).debug/MOM6 >&output; echo "DOME 4pe :" | tee -a  ../../$(RESULTS_DEBUG)/results;diff -s ocean.stats ocean.stats.$(PLATFORM).$(COMPILER).debug | tee -a ../../$(RESULTS_DEBUG)/results)
	(cd ocean_only/Tidal_bay;mpirun -n 4 ../../build/MOM6_solo.$(PLATFORM).$(COMPILER).debug/MOM6 >&output; echo "Tidal Bay 4pe :" | tee -a  ../../$(RESULTS_DEBUG)/results;diff -s ocean.stats ocean.stats.$(PLATFORM).$(COMPILER).debug | tee -a ../../$(RESULTS_DEBUG)/results)

clean:
	(rm -rf build/{MOM6_solo.$(PLATFORM).$(COMPILER).debug,MOM6.$(PLATFORM).$(COMPILER).debug,shared.$(PLATFORM).$(COMPILER).debug})