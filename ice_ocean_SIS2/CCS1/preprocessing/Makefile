SHELL=bash -f

all: grid_topo obc_data mosaics IC


showenv:
	env
	-set
	-module list
	which python
	-python --version

input_topo: 
	wget http://oceanus.esm.rutgers.edu:8080/thredds/fileServer/ROMS/CCS2/CCS2-BKR.HCo02T/Inputs/grid/CCS2_smoother_0-360.nc

grid_topo: input_topo
	python CreateFMSgridTopo.py

mosaics:
	(source /usr/local/Modules/default/init/bash;module load fre/bronx-11;make_solo_mosaic --num_tiles 1 --dir ./ --mosaic_name ocean_mosaic --tile_file ocean_hgrid.nc; make_quick_mosaic --input_mosaic ocean_mosaic.nc --mosaic_name grid_spec --ocean_topog ocean_topog.nc)

obc_data: input_topo
	(source activate ESMPY;python CreateOBCsegments.py)

IC: 
	(source activate MIDAS;python IC.py)
