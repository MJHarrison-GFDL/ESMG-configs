# IPython log file

from midas.rectgrid import *
import numpy as np
import matplotlib.pyplot as plt
import netCDF4 as nc
import argparse



parser = argparse.ArgumentParser()
parser.add_argument('-n',type=int,help='time slice',default=0)
parser.add_argument('-v',type=str,help='variable (temp,salt,uv_normal)',default='temp')
parser.add_argument('--cmap',type=str,help='colormap',default='spectral')
parser.add_argument('--vmin',type=float,help='min contour',default=None)
parser.add_argument('--vmax',type=float,help='max contour',default=None)

args=parser.parse_args()

# Output supergrid and grid objects
sgrid=supergrid(file='ocean_hgrid.nc')
grid_out=quadmesh(supergrid=sgrid)
#Input OBC data from brushcutter
f=nc.Dataset('obc_monthly_CCS1.nc')
tlev=args.n
# Output bathymetry (at centers)
D=nc.Dataset('ocean_topog.nc').variables['depth'][:]

fig=plt.figure(1,figsize=(9.5,8))
ax1=fig.add_subplot(221)
ax2=fig.add_subplot(222)
ax3=fig.add_subplot(223)
ax4=fig.add_subplot(224)

#Loop through segments
lon_list=[]
lat_list=[]
vvar=args.v

VT=[]

for s,ax in zip([1,2,3],[ax1,ax2,ax3]):
    seg='segment_'+str(s).zfill(3)
    fnam='ilist_'+seg
    xcoords=f.variables[fnam][:]
    fnam='jlist_'+seg
    ycoords=f.variables[fnam][:]
    orient=f.variables[fnam].orientation
    
    if xcoords.shape[0]==1:
        xcoords=xcoords[0,1::2]
        ycoords=ycoords[0,1::2]
        if args.v == 'uv_normal': vvar='v'
    elif xcoords.shape[1]==1:
        xcoords=xcoords[1::2,0]
        ycoords=ycoords[1::2,0]
        print ycoords[1],ycoords[0]
        
        if args.v == 'uv_normal': vvar='u'        
    else:
        print 'section is not oriented along a model coordinate line'
        raise

    lon=sq(f.variables['lon_'+seg][:])
    lon=lon[1::2]  # at cell face centers
    lat=sq(f.variables['lat_'+seg][:])
    lat=lat[1::2]  # at cell face centers
    lon_list.append(lon)
    lat_list.append(lat)
    fnam='dz_'+vvar+'_'+seg
    DZ=sq(f.variables[fnam][tlev,:])
    DZ=DZ[:,1::2]
    D_segment=[]
    DX=sgrid.dx
    DX_segment=[]
    DY=sgrid.dy
    DY_segment=[]

    for x,y in zip(xcoords,ycoords):
        y2=y-0.5;x2=x-0.5
        D_segment.append(D[y2,x2])
        DX_segment.append(DX[y2,x2])
        DY_segment.append(DY[y2,x2])


    Z=np.cumsum(DZ,axis=0)
    Zs=np.zeros((1,Z.shape[1]))
    Z=np.concatenate((Zs,Z),axis=0)

    for k in np.arange(Z.shape[0]-1,0,-1):
        zk=Z[k,:]
        Z[k,:]=np.minimum(zk,np.array(D_segment))



    DZ=np.zeros((Z.shape[0]-1,Z.shape[1]))
    for k in np.arange(DZ.shape[0]):
        DZ[k,:]=Z[k+1,:]-Z[k,:]
    
    Z=-Z

    fnam=vvar+'_'+seg
    tv= f.variables[fnam]
    V=sq(tv[tlev,:])
    V=V[:,1::2]
    V=np.ma.masked_where(V<-1.e10,V)
    kdum=np.arange(Z.shape[0])
    X,z=np.meshgrid(lon,kdum)
    Y,z=np.meshgrid(lat,kdum)

    if args.v == 'uv_normal' and orient == 0 or orient ==2:
        DX=np.array(DX_segment)
        vtrans=V*DZ*DX
        vtrans_tot = np.sum(vtrans)/1.e6
        if orient==2: vtrans_tot=-vtrans_tot 
        print 'Total normal V transport (Sv) = ',vtrans_tot, orient
        VT.append(vtrans_tot)
        print 'Start Depth= ',D_segment[0]
        print 'End Depth= ',D_segment[-1]


    if args.v == 'uv_normal' and orient == 1 or orient ==3:
        DX=np.array(DX_segment)
        vtrans=V*DZ*DX
        vtrans_tot = np.sum(vtrans)/1.e6
        if orient == 1: vtrans_tot=-vtrans_tot
        print 'Total normal U transport (Sv) = ',vtrans_tot, orient
        VT.append(vtrans_tot)
        print 'Start Depth= ',D_segment[0]
        print 'End Depth= ',D_segment[-1]
    
    cmap=vars(plt.cm)[args.cmap]



    cf=ax.pcolormesh(X,Z,V,cmap=cmap,vmin=args.vmin,vmax=args.vmax)
    ax.plot(lon,-np.array(D_segment),color='k')
    plt.colorbar(cf,ax=ax)
    #plt.ylim(-500,0)
    tit=vvar+' '+seg+' total Inflow='+str(vtrans_tot)[0:4]
    ax.set_title(tit,fontsize=10)
    plt.grid()
    if orient == 0:
        ax.set_xlabel('Longitude (deg)')
    else:
        ax.set_xlabel('Latitude (deg)')

    ax.set_ylabel('Elevation (m)')


imin=9999;jmin=9999
imax=0;jmax=0

for s in [1,2,3]:
    seg='segment_'+str(s).zfill(3)
    fnam='ilist_'+seg
    xcoords=f.variables[fnam][:]
    fnam='jlist_'+seg
    ycoords=f.variables[fnam][:]
    orient=f.variables[fnam].orientation
    if xcoords.shape[0]==1:
        xcoords=xcoords[0,1::2]
        ycoords=ycoords[0,1::2]
        imin=np.minimum(xcoords,imin)[0]
        imax=np.maximum(xcoords,imax)[-1]
    elif xcoords.shape[1]==1:
        xcoords=xcoords[1::2,0]
        ycoords=ycoords[1::2,0]
        jmin=np.minimum(ycoords,jmin)[0]        
        jmax=np.maximum(ycoords,jmax)[-1]
    else:
        print 'section is not oriented along a model coordinate line'
        raise

X=grid_out.x_T[jmin:jmax,imin:imax]
Y=grid_out.y_T[jmin:jmax,imin:imax]
Z=D[jmin:jmax,imin:imax]

cf=ax4.pcolormesh(X,Y,np.ma.masked_where(Z<0.01,Z))
ax4.contour(X,Y,grid_out.wet[jmin:jmax,imin:imax],[0.5,0.51],color='c')
for lon,lat,c in zip(lon_list,lat_list,['r','g','b']):
    ax4.plot(lon,lat,'-',linewidth=2.0,color=c)

if args.v == 'uv_normal':
    tit='Bathymetry (m): Total Inflow (Sv)= '+str(np.sum(np.array(VT)))[0:5]
else:
    tit='Bathymetry (m) '
ax4.set_title(tit,fontsize=10)
ax4.set_xlabel('Longitude (deg)')
ax4.set_ylabel('Latitude (deg)')

plt.show()





