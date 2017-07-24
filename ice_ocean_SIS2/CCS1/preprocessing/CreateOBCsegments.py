from brushcutter import lib_obc_variable as lov
from brushcutter import lib_obc_vectvariable as losv
from brushcutter import lib_obc_segments as los
from brushcutter import lib_ioncdf as ncdf
import subprocess as sp
import numpy as np
import netCDF4 as nc

ts_data = './data/global_3d_data.nc'
uv_data = './data/global_3d_data.nc'
ssh_data = './data/global_ssh_data.nc'
momgrd = 'ocean_hgrid.nc'
srcgrd = 'data/ocean_hgrid.nc'

#nt=nc.Dataset(ssh_data).variables['ssh'].shape[0]
nt=12


# ---------- define segments on MOM grid -----------------------
south = los.obc_segment('segment_001', momgrd,istart=0,iend=360,jstart=0,  jend=0  )
north = los.obc_segment('segment_002', momgrd,istart=360,iend=0,jstart=960,jend=960)
west  = los.obc_segment('segment_003', momgrd,istart=0,iend=0,  jstart=960,  jend=0)

# ---------- define variables on each segment ------------------
temp_south = lov.obc_variable(south,'temp',geometry='surface',obctype='radiation',use_locstream=True)
temp_north = lov.obc_variable(north,'temp',geometry='surface',obctype='radiation',use_locstream=True)
temp_west  = lov.obc_variable(west, 'temp',geometry='surface',obctype='radiation',use_locstream=True)

salt_south = lov.obc_variable(south,'salt',geometry='surface',obctype='radiation',use_locstream=True)
salt_north = lov.obc_variable(north,'salt',geometry='surface',obctype='radiation',use_locstream=True)
salt_west  = lov.obc_variable(west, 'salt',geometry='surface',obctype='radiation',use_locstream=True)

vel_south = losv.obc_vectvariable(south,'u','v',geometry='surface',obctype='radiation',use_locstream=True)
vel_north = losv.obc_vectvariable(north,'u','v',geometry='surface',obctype='radiation',use_locstream=True)
vel_west  = losv.obc_vectvariable(west, 'u','v',geometry='surface',obctype='radiation',use_locstream=True)

zeta_south = lov.obc_variable(south,'zeta',geometry='line',obctype='flather',use_locstream=True)
zeta_north = lov.obc_variable(north,'zeta',geometry='line',obctype='flather',use_locstream=True)
zeta_west  = lov.obc_variable(west ,'zeta',geometry='line',obctype='flather',use_locstream=True)


xsrc=nc.Dataset(srcgrd).variables['x'][1::2,1::2]
ysrc=nc.Dataset(srcgrd).variables['y'][1::2,1::2]


for kt in np.arange(nt):
	mm=str(kt+1).zfill(2)
	# ---------- interpolate T/S from monthly file, frame = kt (jan-dec) and using locstream (x2 speedup)
 	temp_south.interpolate_from( ts_data,'thetao',frame=kt,depthname='zt', drown='ncl',\
	from_global=True,x_coords=xsrc,y_coords=ysrc,method='bilinear')
	temp_north.interpolate_from( ts_data,'thetao',frame=kt,depthname='zt', drown='ncl', \
	from_global=True,x_coords=xsrc,y_coords=ysrc,method='bilinear')
	temp_west.interpolate_from( ts_data,'thetao',frame=kt,depthname='zt', drown='ncl', \
	from_global=True,x_coords=xsrc,y_coords=ysrc,method='bilinear')

	salt_south.interpolate_from( ts_data,'so',frame=kt,depthname='zt', drown='ncl', \
	from_global=True,x_coords=xsrc,y_coords=ysrc,method='bilinear')
	salt_north.interpolate_from( ts_data,'so',frame=kt,depthname='zt', drown='ncl',\
	from_global=True,x_coords=xsrc,y_coords=ysrc,method='bilinear')
	salt_west.interpolate_from( ts_data,'so',frame=kt,depthname='zt', drown='ncl', \
	from_global=True,x_coords=xsrc,y_coords=ysrc,method='bilinear')

	vel_south.interpolate_from( uv_data,'uo','vo',frame=kt,depthname='zt', drown='ncl',  \
	from_global=True,x_coords_u=xsrc,y_coords_u=ysrc,x_coords_v=xsrc,y_coords_v=ysrc)
	vel_north.interpolate_from( uv_data,'uo','vo',frame=kt,depthname='zt', drown='ncl', \
	from_global=True,x_coords_u=xsrc,y_coords_u=ysrc,x_coords_v=xsrc,y_coords_v=ysrc)
	vel_west.interpolate_from( uv_data,'uo','vo',frame=kt,depthname='zt', drown='ncl', \
	from_global=True,x_coords_u=xsrc,y_coords_u=ysrc,x_coords_v=xsrc,y_coords_v=ysrc)			
	
	# ---------- set constant value for SSH ----------------------
	zeta_south.interpolate_from(ssh_data,'ssh',frame=kt,from_global=True,x_coords=xsrc,y_coords=ysrc, drown='ncl')
	zeta_north.interpolate_from(ssh_data,'ssh',frame=kt,from_global=True,x_coords=xsrc,y_coords=ysrc, drown='ncl')
	zeta_west.interpolate_from(ssh_data,'ssh',frame=kt,from_global=True,x_coords=xsrc,y_coords=ysrc, drown='ncl')	

	# ---------- list segments and variables to be written -------
	list_segments = [north,south,west]
#	list_segments = [south]	

	list_variables = [temp_south,temp_north,temp_west, \
	                  salt_south,salt_north,salt_west, \
	                  zeta_south,zeta_north,zeta_west ]
#	list_variables = [temp_south,salt_south] 


        list_vectvariables = [vel_south,vel_north,vel_west]
#	list_vectvariables = [vel_south]	

	#----------- time --------------------------------------------
	time = temp_south.timesrc
	time.calendar = nc.Dataset(ts_data).variables['time'].calendar

	# ---------- write to file -----------------------------------
	ncdf.write_obc_file(list_segments,list_variables,list_vectvariables,time,output='obc_d' + mm + '_CCS1.nc')

# ---------- concat to a single file ---------------------------------
cmdcat = 'ncrcat obc_d??_CCS1.nc -O -o obc_monthly_CCS1.nc'
cmdclean = 'rm obc_d??_CCS1.nc'
sp.call(cmdcat,shell=True)
sp.call(cmdclean,shell=True)
