from midas.rectgrid import *
import numpy as np
import netCDF4 as nc
import matplotlib.pyplot as plt

vmax=1
vmax_bc=.1

cmap=plt.cm.viridis
grid=quadmesh(path='ocean_geometry.nc',grid_type='gold_geometry')
S=state('prog.nc',grid=grid,fields=['u'],verbose=False)
fig=plt.figure(1)
cf=plt.pcolormesh(S.grid.lonh,np.arange(S.u.shape[0]),sq(S.u[:,0,grid.jm/2,:]),cmap=cmap,vmin=-vmax,vmax=vmax)
plt.title('Zonal Velocity in top layer (m/s)')
plt.ylim(0,25)
plt.colorbar(cf)
fig=plt.figure(2)
cf=plt.pcolormesh(S.grid.lonh,np.arange(S.u.shape[0]),sq(S.u[:,0,grid.jm/2,:]),cmap=cmap,vmin=-vmax_bc,vmax=vmax_bc)
plt.title('Zonal Velocity in top layer (m/s)')
plt.colorbar(cf)
plt.show()
