from midas.rectgrid import *
import numpy as np
import netCDF4 as nc
import matplotlib.pyplot as plt
grid=quadmesh(path='ocean_geometry.nc',grid_type='gold_geometry')
nt=nc.Dataset('prog.nc').variables['u'].shape[0]
S=state('prog.nc',grid=grid,fields=['u','v','h'],interfaces='e',verbose=False,time_indices=np.arange(nt-1,nt))
asym_sum=0.0
asym=np.sum(S.h[-1,:,:,-1]-S.h[-1,:,:,0])
asym_sum=asym_sum+asym
print 'h E-W asym=',asym
asym=np.sum(S.h[-1,:,0,:]-S.h[-1,:,-1,:])
asym_sum=asym_sum+asym
print 'h N-S asym=',asym
asym=np.sum(S.u[-1,:,:,1]+S.u[-1,:,:,-1])
asym_sum=asym_sum+asym
print 'normal vel E-W asym ',asym
asym=np.sum(S.v[-1,:,1,:]+S.v[-1,:,-1,:])
asym_sum=asym_sum+asym
print 'normal vel N-S asym=',asym
asym=np.sum(S.v[-1,:,1:-1,0]-S.v[-1,:,1:-1,-1])
asym_sum=asym_sum+asym
print 'tangential vel E-W asym ',asym
asym=np.sum(S.u[-1,:,0,1:-1]-S.u[-1,:,-1,1:-1])
asym_sum=asym_sum+asym
print 'tangential vel N-S asym=',asym
if asym_sum == 0.0:
    print 'RESULTS ARE SYMMETRIC'
else:
    print 'FAILED SYMMETRY CHECK'
