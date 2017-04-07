SHELL = bash -f


all: test_suite_gnu

compile:
	./compile_MOM6_solo linux-gnu

test_suite_gnu: compile
	(cd ocean_only/circle_obcs;mpirun -n 1 ../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6 >&output; echo "circle_obcs 1pe :" | tee  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/circle_obcs;mpirun -n 4 ../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6 >&output; echo "circle_obcs 4pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/Channel;mpirun -n 1 ../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6 >&output; echo "Channel 1pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/Channel;mpirun -n 4 ../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6 >&output; echo "Channel 4pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/seamount/z;mpirun -n 4 ../../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6 >&output; echo "Seamount 4pe :" | tee -a  ../../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/DOME;mpirun -n 4 ../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6 >&output; echo "DOME 4pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
	(cd ocean_only/Tidal_bay;mpirun -n 4 ../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6 >&output; echo "Tidal Bay 4pe :" | tee -a  ../../.results_gnu;diff -s ocean.stats ocean.stats.gnu | tee -a ../../.results_gnu)
