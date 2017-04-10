SHELL = bash -f
# make test platform=linux compiler=gnu type=debug
RESULTSFILE = .results/$(platform)/$(compiler)/$(type)

all: test_solo

env:
	repro_flag=0;debug_flag=0
	if [ $(type) = "repro" ]; then repro_flag=1;debug_flag=0; fi
	echo $(RESULTSFILE)
	mkdir -p $(RESULTSFILE)


compile_libs: env
	mkdir -p build/shared.$(platform).$(compiler).$(type)
	(cd build/shared.$(platform).$(compiler).$(type)/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/FMS; \
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(platform)-$(compiler).mk -p libfms.a -o '-I/usr/local/include' -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS" path_names; \
	source ../../build/env/$(platform)-$(compiler); make  NETCDF=4 REPRO=$(repro_flag) DEBUG=$(debug_flag) libfms.a)

	mkdir -p build/MOM6.$(platform).$(compiler).$(type)
	(cd build/MOM6.$(platform).$(compiler).$(type)/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/MOM6/{config_src/dynamic_symmetric,config_src/solo_driver/coupler_types*,src/*,src/*/*,pkg/*/src/*}   ;\
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(platform)-$(compiler).mk -o '-I/usr/local/include -I../../src/FMS/include -I../shared.$(platform).$(compiler).$(type)' -p libMOM6.a -l '-L../shared.$(platform).$(compiler).$(type) -lfms' -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS -Duse_AM3_physics" path_names; \
	source ../../build/env/$(platform)-$(compiler); make  NETCDF=4 REPRO=$(repro_flag) DEBUG=$(debug_flag) -j 8 libMOM6.a)

compile_MOM6_solo: compile_libs
	mkdir -p build/MOM6_solo.$(platform).$(compiler).$(type)
	(cd build/MOM6_solo.$(platform).$(compiler).$(type)/; \
	rm -f path_names; ../../src/mkmf/bin/list_paths ../../src/MOM6/config_src/solo_driver/*  ;\
	../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/$(platform)-$(compiler).mk -o  '-I../../src/MOM6/src/framework -I../../src/MOM6/config_src/dynamic_symmetric -I../MOM6.$(platform).$(compiler).$(type) -I../shared.$(platform).$(compiler).$(type)' -l '-L../MOM6.$(platform).$(compiler).$(type) -lMOM6 -L../shared.$(platform).$(compiler).$(type) -lfms -L/usr/local/lib -lmpi -lmpifort -lnetcdf -lnetcdff' -p MOM6 -c "-Duse_libMPI -Duse_netCDF -DSPMD -DLAND_BND_TRACERS -Duse_AM3_physics" path_names; \
	source ../../build/env/$(platform)-$(compiler); make  NETCDF=4 REPRO=$(repro_flag) DEBUG=$(debug_flag) -j 8 MOM6)


test_solo: compile_MOM6_solo
	(cd ocean_only/circle_obcs;mpirun -n 1 ../../build/MOM6_solo.$(platform).$(compiler).$(type)/MOM6 >&output; echo "circle_obcs 1pe :" | tee  ../../$(RESULTSFILE)/results;diff -s ocean.stats ocean.stats.$(platform).$(compiler).$(type) | tee -a ../../$(RESULTSFILE)/results)
	(cd ocean_only/circle_obcs;mpirun -n 4 ../../build/MOM6_solo.$(platform).$(compiler).$(type)/MOM6 >&output; echo "circle_obcs 4pe :" | tee -a  ../../$(RESULTSFILE)/results;diff -s ocean.stats ocean.stats.$(platform).$(compiler).$(type) | tee -a ../../$(RESULTSFILE)/results)
	(cd ocean_only/Channel;mpirun -n 1 ../../build/MOM6_solo.$(platform).$(compiler).$(type)/MOM6 >&output; echo "Channel 1pe :" | tee -a  ../../$(RESULTSFILE)/results;diff -s ocean.stats ocean.stats.$(platform).$(compiler).$(type) | tee -a ../../$(RESULTSFILE)/results)
	(cd ocean_only/Channel;mpirun -n 4 ../../build/MOM6_solo.$(platform).$(compiler).$(type)/MOM6 >&output; echo "Channel 4pe :" | tee -a  ../../$(RESULTSFILE)/results;diff -s ocean.stats ocean.stats.$(platform).$(compiler).$(type) | tee -a ../../$(RESULTSFILE)/results)
	(cd ocean_only/seamount/z;mpirun -n 4 ../../../build/MOM6_solo.$(platform).$(compiler).$(type)/MOM6 >&output; echo "Seamount 4pe :" | tee -a  ../../../$(RESULTSFILE)/results;diff -s ocean.stats ocean.stats.$(platform).$(compiler).$(type) | tee -a ../../../$(RESULTSFILE)/results)
	(cd ocean_only/DOME;mpirun -n 4 ../../build/MOM6_solo.$(platform).$(compiler).$(type)/MOM6 >&output; echo "DOME 4pe :" | tee -a  ../../$(RESULTSFILE)/results;diff -s ocean.stats ocean.stats.$(platform).$(compiler).$(type) | tee -a ../../$(RESULTSFILE)/results)
	(cd ocean_only/Tidal_bay;mpirun -n 4 ../../build/MOM6_solo.$(platform).$(compiler).$(type)/MOM6 >&output; echo "Tidal Bay 4pe :" | tee -a  ../../$(RESULTSFILE)/results;diff -s ocean.stats ocean.stats.$(platform).$(compiler).$(type) | tee -a ../../$(RESULTSFILE)/results)

clean:
	(rm -rf build/{MOM6_solo.$(platform).$(compiler).$(type),MOM6.$(platform).$(compiler).$(type),shared.$(platform).$(compiler).$(type)})
