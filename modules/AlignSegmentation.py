from os.path import join
import sys
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable
import mpld3
from jtapi import *
from jtlib import aligncycles


##############
# read input #
##############

# jterator api
handles_stream = sys.stdin
handles = gethandles(handles_stream)
input_args = readinputargs(handles)
input_args = checkinputargs(input_args)

input_images = list()
for i in range(1, 5):
    im_name = 'InputImage%d' % i
    if im_name in input_args:
        input_images.append(np.array(input_args[im_name], dtype='float64'))

shift_descriptor_filename = input_args['ShiftDescriptor']
reference_filename = input_args['ReferenceFilename']
do_plot = input_args['Plot']


##############
# processing #
##############

# load shift descriptor file
shift_descriptor_filename = join(handles['project_path'],
                                 shift_descriptor_filename)
shift_descriptor = aligncycles.load_shift_descriptor(shift_descriptor_filename)

# find the correct site index
index = aligncycles.get_index_from_shift_descriptor(shift_descriptor,
                                                    reference_filename)

# align image (crop only - segmentation is based on reference cycle!)
aligned_images = list()
for image in input_images:
    cropped_image = aligncycles.shift_and_crop_image(image, shift_descriptor,
                                                     index, crop_only=True)
    if shift_descriptor['noShiftIndex'][index] == 1:
        aligned_images.append(np.zeros(cropped_image.shape))
    else:
        aligned_images.append(cropped_image)

# Cutting can result in inconsistent object counts, for example a nucleus
# can be removed, but there is still some part of the cell present in the image.
# We have to correct for such cutting artifacts.

# ensure that object counts are identical and that object ids match.
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
for i, label in enumerate(a_ix):
    output_images[ix[1]][aligned_images[ix[1]] == a_ix[i]] = label
    output_images[ix[0]][aligned_images[ix[0]] == b_ix[i]] = label

# keep track of original object labels (of the uncropped images)
original_ids = a_ix


###################
# display results #
###################

if do_plot:

    fig = plt.figure(figsize=(10, 10))

    ax1 = fig.add_subplot(2, 2, 1)
    ax2 = fig.add_subplot(2, 2, 2)
    ax3 = fig.add_subplot(2, 2, 3)
    ax4 = fig.add_subplot(2, 2, 4)

    im1 = ax1.imshow(input_images[0])
    ax1.set_title('Original', size=20)
    divider = make_axes_locatable(ax1)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    fig.colorbar(im1, cax=cax)

    im2 = ax2.imshow(output_images[0])
    ax2.set_title('Aligned', size=20)
    divider = make_axes_locatable(ax2)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    fig.colorbar(im2, cax=cax)

    im3 = ax3.imshow(input_images[1])
    ax3.set_title('Original', size=20)
    divider = make_axes_locatable(ax3)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    fig.colorbar(im3, cax=cax)

    im4 = ax4.imshow(output_images[1])
    ax4.set_title('Aligned', size=20)
    divider = make_axes_locatable(ax4)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    fig.colorbar(im4, cax=cax)

    fig.tight_layout()

    # Save figure as html file and open it in the browser
    figure_name = '%s.html' % handles['figure_filename']
    mpld3.save_html(fig, figure_name)


################
# write output #
################

output_args = dict()
for i, image in enumerate(output_images):
    output_args['AlignedImage%d' % (i+1)] = image

data = dict()
data['OriginalObjectIds'] = original_ids

# jterator api
writedata(handles, data)
writeoutputargs(handles, output_args)
