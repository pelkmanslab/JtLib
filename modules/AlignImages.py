import os
import sys
import re
import json
import numpy as np
import matplotlib.pyplot as plt
import mpld3
# from mpl_toolkits.axes_grid1 import make_axes_locatable
from jtapi import *
from jtsubfunctions import get_microscope_type


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

input_images = list()
input_images.append(input_args['InputImage1'])
input_images.append(input_args['InputImage2'])
input_images.append(input_args['InputImage3'])
input_images.append(input_args['InputImage4'])

shift_descriptor_filename = input_args['ShiftDescriptor']
reference_filename = input_args['ReferenceFilename']

doPlot = input_args['doPlot']


################
## processing ##
################

### load shift descriptor file
if not os.path.exists(shift_descriptor_filename):
    raise Exception('Shift descriptor file does not exist.')
shift_descriptor = json.load(open(shift_descriptor_filename))

### find the correct site index
# get search pattern
(microscope, pattern) = get_microscope_type(reference_filename)
filename_match = re.search(pattern, reference_filename).group(0)
if filename_match is None:
    raise Exception('Pattern doesn\'t match reference filename.')
# find file that matches pattern
i = -1
index = list()
for site in shift_descriptor['fileName']:
    i += 1
    if re.search(filename_match, site):
        index.append(i)
        break
# Assert that there is only one file that matches pattern
if len(index) == 0:
    raise Exception('No file found that matches reference pattern.')
elif len(index) > 1:
    raise Exception('Several files found that match reference pattern.')
else:
    index = index[0]

### align image
upper = shift_descriptor['upperOverlap']
lower = shift_descriptor['lowerOverlap']
left = shift_descriptor['leftOverlap']
right = shift_descriptor['rightOverlap']
y = shift_descriptor['yShift'][index]
x = shift_descriptor['xShift'][index]

aligned_images = list()
for image in input_images:
    if image is None:
        aligned_images.append(None)
        continue
    if shift_descriptor['noShiftIndex'][index] == 1:
        aligned_images.append(np.zeros(image[lower:-(upper+1), right:-(left+1)].shape))
    else:
        aligned_images.append(image[(lower-y):-(upper+y+1), (right-x):-(left+x+1)])


#####################
## display results ##
#####################

if doPlot:

    fig = plt.figure(figsize=(12, 12))
    ax1 = fig.add_subplot(1, 2, 1)
    ax2 = fig.add_subplot(1, 2, 2)

    im1 = ax1.imshow(input_image,
                     vmin=np.percentile(input_image, 0.1),
                     vmax=np.percentile(input_image, 99.9),
                     cmap='gray')
    ax1.set_title('Original image', size=20)
    # divider1 = make_axes_locatable(ax1)
    # cax1 = divider1.append_axes("right", size="10%", pad=0.05)
    # fig.colorbar(im1, cax=cax1)

    # Only display the first image
    im2 = ax2.imshow(aligned_images[0],
                     vmin=np.percentile(aligned_images[0], 0.1),
                     vmax=np.percentile(aligned_images[0], 99.9),
                     cmap='gray')
    ax2.set_title('Aligned image', size=20)
    # divider2 = make_axes_locatable(ax2)
    # cax2 = divider2.append_axes("right", size="10%", pad=0.05)
    # fig.colorbar(im2, cax=cax2)

    fig.tight_layout()

    # Save figure as html file and open it in the browser
    fid = h5py.File(handles['hdf5_filename'], 'r')
    jobid = fid['jobid'][()]
    fid.close()
    image_name = os.path.basename(reference_filename)
    figure_name = os.path.abspath('figures/%s_%s_%05d.html' % (mfilename,
                                  image_name, jobid))

    mpld3.save_html(fig, figure_name)
    figure2browser(figure_name)


####################
## prepare output ##
####################

output_args = dict()
for i, image in enumerate(aligned_images):
    if image is None:
        continue
    output_args['AlignedImage%d' % i] = image

data = dict()


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
