# IPython log file
#
#Generate Initial Conditions for CCS1 domain from global 
from midas.rectgrid import *
import netCDF4 as nc
import numpy as np

sgrid=supergrid(file='ocean_hgrid.nc')
grid=quadmesh(supergrid=sgrid)
sgrid=supergrid(file='data/ocean_hgrid.nc')
grid_in=quadmesh(supergrid=sgrid,cyclic=True)
grid.D=nc.Dataset('ocean_topog.nc').variables['depth'][:]
S=state('data/global_3d_data.nc',grid=grid_in,fields=['thetao','so','uo','vo'],time_indices=np.arange(0,1))
SSH=state('data/global_ssh_data.nc',grid=grid_in,fields=['ssh'],time_indices=np.arange(0,1))
R=S.horiz_interp('thetao',target=grid)
R=S.horiz_interp('so',target=grid,PrevState=R)
R=S.horiz_interp('uo',target=grid,PrevState=R)
R=S.horiz_interp('vo',target=grid,PrevState=R)
R=SSH.horiz_interp('ssh',target=grid,PrevState=R)
R.rename_field('thetao','temp')
R.rename_field('so','salt')
R.rename_field('uo','u')
R.rename_field('vo','v')
R.adjust_thickness('temp')
R.adjust_thickness('salt')
R.adjust_thickness('u')
R.adjust_thickness('v')
vdict=R.var_dict['temp'].copy()
vdict['units']='m'
h=vdict['dz'].copy()
h=h[np.newaxis,:]
R.add_field_from_array(h,'h',vdict)
R.fill_interior('temp')
R.fill_interior('salt')
R.fill_interior('u')
R.fill_interior('v')
R.fill_interior('ssh')
R.ssh[:,:,grid.D<0.25]=0.0
R.v[:,:,np.roll(R.grid.D,shift=-1,axis=0)<0.1]=0.0
R.v[:,:,0,:]=0.0
R.v[:,:,-1,:]=0.0
R.u[:,:,np.roll(R.grid.D,shift=-1,axis=1)<0.1]=0.0
R.u[:,:,:,0]=0.0
R.u[:,:,:,-1]=0.0

R.write_nc('IC.nc',['temp','salt','u','v','h','ssh'],write_interface_positions=True)


