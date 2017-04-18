SHELL=bash -f

all: grid_topo obc_data IC


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
obc_data: input_topo
	(source activate ESMPY;python CreateOBCsegments.py)

IC: input_topo
	(source activate MIDAS;python IC.py)
