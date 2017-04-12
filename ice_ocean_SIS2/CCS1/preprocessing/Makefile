SHELL=bash -f

all: obc_data IC


showenv:
	env
	-set
	-module list
	which python
	-python --version

obc_data: 
	(source activate ESMPY;python CreateOBCsegments.py)

IC: 
	(source activate MIDAS;python IC.py)
