from os.path import join
import sys
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable
import mpld3
import jtapi
from plia import aligncycles


##############
# read input #
##############

handles_stream = sys.stdin
handles = jtapi.gethandles(handles_stream)
input_args = jtapi.readinputargs(handles)
input_args = jtapi.checkinputargs(input_args)

input_images = list()
for i in range(1, 5):
    im_name = 'InputImage%d' % i
    if im_name in input_args:
        input_images.append(np.array(input_args[im_name], dtype='float64'))

object_names = list()
for i in range(1, 5):
    currentObject = 'ObjectName%s' % i
    if currentObject in input_args:
        object_names.append(input_args[currentObject])

parent = input_args['ParentObjects']

shift_descriptor_filename = input_args['ShiftDescriptor']
reference_filename = input_args['ReferenceFilename']


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

# align image
# crop only (no shift required) since segmentation is based on reference cycle
aligned_images = list()
for image in input_images:
    cropped_image = aligncycles.shift_and_crop_image(image, shift_descriptor,
                                                     index, crop_only=True)
    if shift_descriptor['noShiftIndex'][index] == 1:
        aligned_images.append(np.zeros(cropped_image.shape))
    else:
        aligned_images.append(cropped_image)

# NOTE: Cutting can result in inconsistent object counts, for example a nucleus
# can be removed, but there is still some part of the cell present in the image.
# We have to correct for such cutting artifacts.

# Assign new, continuous labels to the parent objects
ix = [i for i, name in enumerate(object_names) if name == parent]

if len(ix) == 1:
    ix = ix[0]
elif len(ix) > 1:
    raise ValueError('Name of parent objects "%s" matches more than one of '
                     'the object names' % parent)
else:
    raise ValueError('Name of parent objects "%s" doesn\'t match any of '
                     'the object names' % parent)

parent_image = np.zeros(aligned_images[ix].shape, dtype=aligned_images[ix].dtype)
retained_parent_ids = np.unique(aligned_images[ix][aligned_images[ix] != 0])
for j, retained_id in enumerate(retained_parent_ids):
    # new one-based labels (background = 0)
    parent_image[aligned_images[ix] == retained_id] = j + 1
parent_ids = np.unique(parent_image[parent_image != 0])
orig_parent_ids_num = len(np.unique(input_images[ix][input_images[ix] != 0]))

# Remove child objects that have lost their parent and re-label the ones that
# are left relative to the parent objects
output_images = list()
original_ids = list()  # also keep track of original object labels
for i, image in enumerate(aligned_images):

    if i == ix:
        output_images.append(parent_image)
        original_ids.append(retained_parent_ids)
        continue

    # Which child objects retained their parent?
    stack = np.dstack((parent_image > 1, image > 1))
    stack = np.array(np.sum(stack, axis=2), dtype=int)
    retained_child_ids = np.unique(image[stack == 2])

    # Assign new, continuous labels to child objects
    child_image = np.zeros(image.shape, dtype=image.dtype)
    orig_child_ids_num = len(np.unique(input_images[i][input_images[i] != 0]))
    # If children had same number of objects as parent, re-label them the same
    if orig_child_ids_num == orig_parent_ids_num:
        for j, retained_id in enumerate(retained_child_ids):
            child_image[image == retained_id] = parent_ids[j]
    # If children had more objects than parent, re-label them independently
    else:
        for j, retained_id in enumerate(retained_child_ids):
            # new one-based labels (background = 0)
            child_image[image == retained_id] = j + 1

    output_images.append(child_image)
    original_ids.append(retained_child_ids)


###################
# display results #
###################

if handles['plot']:

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
for i, obj in enumerate(object_names):
    data['%s_OriginalObjectIds' % obj] = original_ids[i]

jtapi.writedata(handles, data)
jtapi.writeoutputargs(handles, output_args)
