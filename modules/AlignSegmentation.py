import os
import sys
import re
import json
import numpy as np
import matplotlib.pyplot as plt
import mpld3
from jterator.api import *
from pysubfunctions import microscope_type


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

input_image_1 = np.array(input_args['InputImage1'], dtype='float64')
input_image_2 = np.array(input_args['InputImage2'], dtype='float64')
input_images = [input_image_1, input_image_2]

shift_descriptor_filename = input_args['ShiftDescriptor']
ref_filename = input_args['ReferenceFilename']

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
(microscope, pattern) = microscope_type(ref_filename)
filename_match = re.search(pattern, ref_filename).group(0)
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
# ensure that there is only one file that matches pattern
if len(index) == 0:
    raise Exception('No file found that matches reference pattern.')
elif len(index) > 1:
    raise Exception('Several files found that match reference pattern.')
else:
    index = index[0]

### align image (shift and crop)
upper = shift_descriptor['upperOverlap']
lower = shift_descriptor['lowerOverlap']
left = shift_descriptor['leftOverlap']
right = shift_descriptor['rightOverlap']
y = shift_descriptor['yShift'][index]
x = shift_descriptor['xShift'][index]
aligned_images = list()
for image in input_images:
    if shift_descriptor['noShiftIndex'][index] == 1:
        aligned_images.append(np.zeros(image[lower:-upper, right:-left].shape))
    else:
        aligned_images.append(image[(lower-y):-(upper+y), (right-x):-(left+x)])

# Cutting can result in inconsistent object counts, for example a nucleus
# can be removed, but there is still some part of the cell present in the image.
# We have to correct for such cutting artifacts.

### ensure that object counts are identical and that object ids match.
object_ids = [np.unique(image[image != 0]) for image in aligned_images]
object_counts = [len(objects) for objects in object_ids]
ix = np.argsort(object_counts)

# get common objects in image with highest object count and
# image with second highest object count
# (usually this corresponds to 'cells' and 'nuclei' objects, respectively)
b = np.in1d(object_ids[ix[1]], object_ids[ix[0]])
a = np.in1d(object_ids[ix[0]], object_ids[ix[1]][b])

# assign new common, continuous labels
a_ix = object_ids[ix[1]][b]
b_ix = object_ids[ix[0]][a]

if not all(a_ix == b_ix):
    raise Exception('New object ids do not match.')

output_images = list()
output_images.append(np.zeros(aligned_images[ix[0]].shape))
output_images.append(np.zeros(aligned_images[ix[1]].shape))
for label in range(len(a_ix)):
    output_images[ix[1]][aligned_images[ix[1]] == a_ix[label]] = label
    output_images[ix[0]][aligned_images[ix[0]] == b_ix[label]] = label

# keep track of original object labels (of the uncropped images)
original_ids = a_ix


#####################
## display results ##
#####################


if doPlot:

    fig = plt.figure(figsize=(12, 12))
    ax1 = fig.add_subplot(2, 2, 1)
    ax2 = fig.add_subplot(2, 2, 2)
    ax3 = fig.add_subplot(2, 2, 3)
    ax4 = fig.add_subplot(2, 2, 4)

    im1 = ax1.imshow(input_images[0])
    ax1.set_title('Original segmentation', size=20)

    im2 = ax2.imshow(output_images[0])
    ax2.set_title('Aligned segmentation', size=20)

    im3 = ax3.imshow(input_images[1])
    ax3.set_title('Original segmentation', size=20)

    im4 = ax4.imshow(output_images[1])
    ax4.set_title('Aligned segmentation', size=20)

    fig.tight_layout()

    # Save figure as html file and open it in the browser
    fid = h5py.File(handles['hdf5_filename'], 'r')
    jobid = fid['jobid'][()]
    fid.close()
    figure_name = os.path.abspath('figures/%s_%05d.html' % (mfilename, jobid))

    mpld3.save_html(fig, figure_name)
    figure2browser(figure_name)


####################
## prepare output ##
####################

output_args = dict()
output_args['AlignedImage1'] = output_images[0]
output_args['AlignedImage2'] = output_images[1]

data = dict()
data['OriginalObjectIds'] = original_ids


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
