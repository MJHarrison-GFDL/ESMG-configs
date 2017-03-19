from midas.rectgrid import *
import numpy as np
import netCDF4 as nc
import matplotlib.pyplot as plt

cmap=plt.cm.viridis
grid=quadmesh(path='ocean_geometry.nc',grid_type='gold_geometry')
S=state('bt_hifreq.nc',grid=grid,fields=['ubt','vbt'],verbose=False)
fig=plt.figure(1)
cf=plt.pcolormesh(grid.x_T,grid.y_T,sq(S.ubt[35,0,:]),cmap=cmap,vmin=-2,vmax=2)
plt.colorbar(cf)
plt.show()
