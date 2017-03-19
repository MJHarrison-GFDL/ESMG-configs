#!/bin/csh -v

sed -i 's/EXTEND_OBC_SEGMENTS = True/EXTEND_OBC_SEGMENTS = False/g' MOM_override
echo 'No extensions'
mpirun -n 1 ../../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6  >& output.A
cat ocean.stats;cp ocean.stats ocean.stats.no_extension
echo 'No extensions w/ 4pe'
mpirun -n 4 ../../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6  >& output.B
cat ocean.stats;cp ocean.stats ocean.stats.4pe
sed -i 's/EXTEND_OBC_SEGMENTS = False/EXTEND_OBC_SEGMENTS = True/g' MOM_override
echo 'With extensions'
mpirun -n 1 ../../../build/MOM6_solo.linux-gnu.symmetric.repro/MOM6  >& output.B
cat ocean.stats;cp ocean.stats ocean.stats.extension
