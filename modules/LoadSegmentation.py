import os
import sys
import re
import glob
import numpy as np
from scipy import misc
import matplotlib.pyplot as plt
# from mpl_toolkits.axes_grid1 import make_axes_locatable
import mpld3
from jtapi import *
from jtsubfunctions import microscope_type


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

object_names = list()
object_names.append(input_args['ObjectName1'])
object_names.append(input_args['ObjectName2'])

ref_filename = input_args['ReferenceFilename']
segmentation_folder = input_args['SegmentationDirectory']
doPlot = input_args['doPlot']


################
## processing ##
################

### determine filenames of segmentation images
(microscope, pattern) = microscope_type(ref_filename)
filename_match = re.search(pattern, ref_filename).group(1)
if filename_match is None:
    raise Exception('Pattern doesn\'t match reference filename.')

segmentation_filenames = list()
for obj in object_names:

    filenames = glob.glob(os.path.join(os.getcwd(),
                          segmentation_folder, '*%s*_segmented%s.png'
                          % (filename_match, obj)))

    if len(filenames) == 0:
        raise Exception('No file found that matches reference pattern.')
    elif len(filenames) > 1:
        raise Exception('Several files found that match reference pattern.')
    else:
        segmentation_filenames.append(filenames[0])


### load segmentation images
segmentations = list()
for f in segmentation_filenames:
    segmentations.append(np.array(misc.imread(f), dtype='int'))
    segmentations.append(np.array(misc.imread(f), dtype='int'))


#####################
## display results ##
#####################

if doPlot:

    fig = plt.figure(figsize=(12, 12))
    ax1 = fig.add_subplot(1, 2, 1, adjustable='box', aspect=1)
    ax2 = fig.add_subplot(1, 2, 2, adjustable='box', aspect=1)

    im1 = ax1.imshow(segmentations[0])
    ax1.set_title(object_names[0], size=20)

    im2 = ax2.imshow(segmentations[1])
    ax2.set_title(object_names[1], size=20)

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

data = dict()

output_args = dict()
output_args['Objects1'] = segmentations[0]
output_args['Objects2'] = segmentationa[1]


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
