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

ref_filename = input_args['ReferenceFilename']
segmentation_folder = input_args['SegmentationFolder']
object_name_1 = input_args['ObjectName1']
object_name_2 = input_args['ObjectName2']
doPlot = input_args['doPlot']


################
## processing ##
################

### determine filenames of segmentation images
(microscope, pattern) = microscope_type(ref_filename)
filename_match = re.search(pattern, ref_filename).group(1)
if filename_match is None:
    raise Exception('Pattern doesn\'t match reference filename.')

segmentation_filename_1 = glob.glob(os.path.join(os.getcwd(),
                                    segmentation_folder, '*%s*_segmented%s.png'
                                    % (filename_match, object_name_1)))

if len(segmentation_filename_1) == 0:
    raise Exception('No file found that matches reference pattern.')
elif len(segmentation_filename_1) > 1:
    raise Exception('Several files found that match reference pattern.')
else:
    segmentation_filename_1 = segmentation_filename_1[0]


segmentation_filename_2 = glob.glob(os.path.join(os.getcwd(),
                                    segmentation_folder, '*%s*_segmented%s.png'
                                    % (filename_match, object_name_2)))

if len(segmentation_filename_2) == 0:
    raise Exception('No file found that matches reference pattern.')
elif len(segmentation_filename_2) > 1:
    raise Exception('Several files found that match reference pattern.')
else:
    segmentation_filename_2 = segmentation_filename_2[0]

### load segmentation images
segmentation_1 = np.array(misc.imread(segmentation_filename_1), dtype='int')
segmentation_2 = np.array(misc.imread(segmentation_filename_2), dtype='int')


#####################
## display results ##
#####################

if doPlot:

    fig = plt.figure(figsize=(12, 12))
    ax1 = fig.add_subplot(1, 2, 1, adjustable='box', aspect=1)
    ax2 = fig.add_subplot(1, 2, 2, adjustable='box', aspect=1)

    im1 = ax1.imshow(segmentation_1)
    ax1.set_title(object_name_1, size=20)

    im2 = ax2.imshow(segmentation_2)
    ax2.set_title(object_name_2, size=20)

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
output_args['Objects1'] = segmentation_1
output_args['Objects2'] = segmentation_2


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
