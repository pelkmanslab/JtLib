import os
import sys
import re
import numpy as np
from scipy import misc
import matplotlib.pyplot as plt
# from mpl_toolkits.axes_grid1 import make_axes_locatable
import mpld3
from jtapi import *


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

image_filenames = list()
image_filenames.append(input_args['ImageFilename1'])
image_filenames.append(input_args['ImageFilename2'])
image_filenames.append(input_args['ImageFilename3'])
image_filenames.append(input_args['ImageFilename4'])

doPlot = input_args['doPlot']


################
## processing ##
################

images = list()
for f in image_filenames:
    if f is None:
        images.append(None)
        continue
    images.append(np.array(misc.imread(f), dtype='float64'))


#####################
## display results ##
#####################

if doPlot:

    fig = plt.figure(figsize=(8, 8))
    ax1 = fig.add_subplot(1, 1, 1)

    im1 = ax1.imshow(images[0],
                     vmin=np.percentile(images[0], 0.1),
                     vmax=np.percentile(images[0], 99.9),
                     cmap='gray')
    ax1.set_title(os.path.basename(image_filenames[0]), size=20)
    # divider1 = make_axes_locatable(ax1)
    # cax1 = divider1.append_axes("right", size="10%", pad=0.05)
    # fig.colorbar(im1, cax=cax1)

    fig.tight_layout()

    # Save figure as html file and open it in the browser
    fid = h5py.File(handles['hdf5_filename'], 'r')
    jobid = fid['jobid'][()]
    fid.close()
    image_name = os.path.basename(image_filenames[0])
    figure_name = os.path.abspath('figures/%s_%s_%05d.html' % (mfilename,
                                  image_name, jobid))

    mpld3.save_html(fig, figure_name)
    figure2browser(figure_name)


####################
## prepare output ##
####################

output_args = dict()
for i, image in images:
    if image is None:
        continue
    output_args['Image%d' % i] = image

data = dict()


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
