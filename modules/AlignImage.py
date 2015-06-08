from os.path import join
import sys
import numpy as np
import matplotlib.pyplot as plt
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

input_image = np.array(input_args['InputImage'], dtype='float64')
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
if input_image is None:
    aligned_image = None
elif shift_descriptor['noShiftIndex'][index] == 1:
    aligned_image = aligncycles.shift_and_crop_image(input_image,
                                                     shift_descriptor, index,
                                                     crop_only=True)
    aligned_image = np.zeros(aligned_image.shape)
else:
    aligned_image = aligncycles.shift_and_crop_image(input_image,
                                                     shift_descriptor, index)


###################
# display results #
###################

if handles['plot']:

    fig = plt.figure(figsize=(10, 10))
    ax1 = fig.add_subplot(1, 2, 1)
    ax2 = fig.add_subplot(1, 2, 2)

    im1 = ax1.imshow(input_image,
                     vmin=np.percentile(input_image, 0.1),
                     vmax=np.percentile(input_image, 99.9),
                     cmap='gray')
    ax1.set_title('Original', size=20)

    im2 = ax2.imshow(aligned_image,
                     vmin=np.percentile(aligned_image, 0.1),
                     vmax=np.percentile(aligned_image, 99.9),
                     cmap='gray')
    ax2.set_title('Aligned', size=20)

    fig.tight_layout()

    # Save figure as html file and open it in the browser
    figure_name = '%s.html' % handles['figure_filename']
    mpld3.save_html(fig, figure_name)


################
# write output #
################

output_args = dict()
output_args['AlignedImage'] = aligned_image

data = dict()

# jterator api
writedata(handles, data)
writeoutputargs(handles, output_args)
