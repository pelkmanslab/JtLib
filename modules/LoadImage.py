import os
import sys
import re
import numpy as np
from scipy import misc
import matplotlib.pyplot as plt
# from mpl_toolkits.axes_grid1 import make_axes_locatable
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

image_filename = input_args['ImageFilename']
image_name = input_args['ImageName']
doPlot = input_args['doPlot']


################
## processing ##
################

image = np.array(misc.imread(image_filename), dtype='float64')


#####################
## display results ##
#####################

if doPlot:

    fig = plt.figure(figsize=(8, 8))
    ax1 = fig.add_subplot(1, 1, 1)

    im1 = ax1.imshow(image,
                     vmin=np.percentile(image, 0.1),
                     vmax=np.percentile(image, 99.9),
                     cmap='gray')
    ax1.set_title(os.path.basename(image_filename), size=20)
    # divider1 = make_axes_locatable(ax1)
    # cax1 = divider1.append_axes("right", size="10%", pad=0.05)
    # fig.colorbar(im1, cax=cax1)

    fig.tight_layout()

    # Save figure as html file and open it in the browser
    fid = h5py.File(handles['hdf5_filename'], 'r')
    jobid = fid['jobid'][()]
    fid.close()
    figure_name = os.path.abspath('figures/%s_%s_%05d.html' % (mfilename,
                                  image_name, jobid))

    mpld3.save_html(fig, figure_name)
    figure2browser(figure_name)


####################
## prepare output ##
####################

output_args = dict()
output_args['Image'] = image

data = dict()


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
