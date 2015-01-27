import os
import sys
import re
import numpy as np
from scipy import misc
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable
import mpld3
from jterator.api import *


mfilename = re.search('(.*).py', os.path.basename(__file__)).group(1)

###############################################################################
## jterator input

print('jt - %s:' % mfilename)

### standard input
handles_stream = sys.stdin

### retrieve handles from .YAML files
handles = gethandles(handles_stream)

### read input arguments from .HDF5 files
input_args = readinputargs(handles)

### check whether input arguments are valid
input_args = checkinputargs(input_args)

###############################################################################


####################
## input handling ##
####################

dapi_filename = input_args['DapiFilename']
celltrace_filename = input_args['CelltraceFilename']
doPlot = input_args['doPlot']


################
## processing ##
################

dapi_image = np.float64(misc.imread(dapi_filename))
celltrace_image = np.float64(misc.imread(celltrace_filename))


#####################
## display results ##
#####################

if doPlot:
    # Make figure using matplotlib
    fig = plt.figure()
    ax1 = fig.add_subplot(1, 2, 1, adjustable='box', aspect=1)
    ax2 = fig.add_subplot(1, 2, 2, adjustable='box', aspect=1)

    im1 = ax1.imshow(dapi_image,
                     vmin=np.percentile(dapi_image, 0.1),
                     vmax=np.percentile(dapi_image, 99.9),
                     cmap='gray')
    divider1 = make_axes_locatable(ax1)
    cax1 = divider1.append_axes("right", size="10%", pad=0.05)
    fig.colorbar(im1, cax=cax1)
    ax1.set_title('Dapi', size=20)

    im2 = ax2.imshow(celltrace_image,
                     vmin=np.percentile(celltrace_image, 0.1),
                     vmax=np.percentile(celltrace_image, 99.9),
                     cmap='gray')
    divider2 = make_axes_locatable(ax2)
    cax2 = divider2.append_axes("right", size="10%", pad=0.05)
    fig.colorbar(im2, cax=cax2)
    ax2.set_title('Celltrace', size=20)

    fig.tight_layout()

    fig.savefig('test.pdf')

    # Save figure as html file and open it in the browser
    fid = h5py.File(handles['hdf5_filename'], 'r')
    jobid = fid['jobid'][()]
    fid.close()
    figure_name = 'figures/%s_%05d.html' % (mfilename, jobid)
    mpld3.save_html(fig, figure_name)
    figure2browser(os.path.abspath(figure_name))


####################
## prepare output ##
####################

output_args = dict()
output_args['DapiImage'] = dapi_image
output_args['CelltraceImage'] = celltrace_image

data = dict()


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
