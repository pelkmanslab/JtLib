from jterator.api import *
import os
import sys
import re
import json
import numpy as np
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

input_image_1 = np.array(input_args.InputImage1, dtype='float64')
input_image_2 = np.array(input_args.InputImage2, dtype='float64')
input_images = [input_image_1, input_image_2]

shift_descriptor_filename = input_args.ShiftDescriptor
reference_filename = input_args.ReferenceFilename


################
## processing ##
################

### load shift descriptor file
if not os.path.exists(shift_descriptor_filename):
    raise Exception('Shift descriptor file does not exist.')
shift_descriptor = json.load(open(shift_descriptor_filename))

### find the correct site index
(microscope, pattern) = microscope_type(reference_filename)
filename_match = re.search(pattern, reference_filename).group(0)
if filename_match is None:
    raise Exception('No file found that matches reference filename.')
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

# Cutting can result in inconsistent object counts, for example because a nucleus
# is removed, but there is still some part of the cell present.
# Therefore, we have to correct for such artifacts.

### ensure that object counts are identical and that object ids match.
object_ids = [np.unique(image[image != 0]) for image in input_images]
object_counts = [sum(objects) for objects in object_ids]
ix_order = np.argsort(object_counts)

# get common objects in image with highest object count and
# image with second highest object count
# (usually this corresponds to 'cells' and 'nuclei' objects, respectively)
a = in1d(object_ids[ix_order[1]], object_ids[ix_order[0]])
b = in1d(object_ids[ix_order[0]], object_ids[ix_order[1]][a])

# assign new common, continuous labels
a_ix = a[b]
b_ix = b[a]
for label in range(len(b_ix)):
    for image in input_images[ix_order[1:-1]]:
        image[image == b_ix[label]] = label
    input_images[0][input_images[0] == a_ix[label]] = label



#####################
## display results ##
#####################


####################
## prepare output ##
####################

output_args = dict()
output_args['AlignedImage1'] = aligned_images[0]
output_args['AlignedImage2'] = aligned_images[1]

data = dict()


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
