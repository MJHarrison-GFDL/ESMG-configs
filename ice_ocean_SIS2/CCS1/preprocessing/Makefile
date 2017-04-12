SHELL=bash -f

all: obc_data


showenv:
	env
	-set
	-module list
	which python
	-python --version

local: 
	(cd ../../../tools/brushcutter;python setup.py install)

obc_data: local
	(source activate ESMPY;python CreateOBCsegments.py)
