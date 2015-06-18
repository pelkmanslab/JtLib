import sys
import re
import glob
from os.path import join
import matplotlib.pyplot as plt
import mahotas as mh
# from mpl_toolkits.axes_grid1 import make_axes_locatable
import mpld3
import jtapi
from plia import file_util, aligncycles


##############
# read input #
##############

handles_stream = sys.stdin
handles = jtapi.gethandles(handles_stream)
input_args = jtapi.readinputargs(handles)
input_args = jtapi.checkinputargs(input_args)

object_names = list()
for i in range(1, 4+1):
    currentObject = 'ObjectName%s' % i
    if currentObject in input_args:
        object_names.append(input_args[currentObject])

ref_filename = input_args['ReferenceFilename']
segmentation_folder = input_args['SegmentationDirectory']
do_shift = input_args['Shift']
shift_descriptor_filename = input_args['ShiftDescriptor']


##############
# processing #
##############

if do_shift:
    # load shift descriptor file
    shift_descriptor_filename = join(handles['project_path'],
                                     shift_descriptor_filename)
    shift_descriptor = aligncycles.load_shift_descriptor(shift_descriptor_filename)

    # use segmentation directory stored in shift descriptor
    segmentation_folder = shift_descriptor['SegmentationDirectory']

# determine filenames of segmentation images
(microscope, pattern) = file_util.get_microscope_type(ref_filename)
filename_identifier = re.search(pattern, ref_filename).group(1)
if not filename_identifier:
    raise Exception('Pattern doesn\'t match reference filename.')

segmentation_filenames = list()
for obj in object_names:
    if not obj:
        segmentation_filenames.append(None)
        continue

    wildcard_string = join(handles['project_path'], segmentation_folder,
                           '*%s*_segmented%s.png' % (filename_identifier, obj))

    filenames = glob.glob(wildcard_string)

    if len(filenames) == 0:
        raise Exception('No file found that matches %s.' % wildcard_string)
    elif len(filenames) > 1:
        raise Exception('Several files found that match %s.' % wildcard_string)
    else:
        segmentation_filenames.append(filenames[0])

# load segmentation images
segmentations = list()
for f in segmentation_filenames:
    if not f:
        segmentations.append(None)
        continue
    segmentations.append(mh.imread(f))


###################
# display results #
###################

if handles['plot']:

    fig = plt.figure(figsize=(10, 10))
    ax1 = fig.add_subplot(1, 2, 1, adjustable='box', aspect=1)
    ax2 = fig.add_subplot(1, 2, 2, adjustable='box', aspect=1)

    im1 = ax1.imshow(segmentations[0])
    ax1.set_title(object_names[0], size=20)

    im2 = ax2.imshow(segmentations[1])
    ax2.set_title(object_names[1], size=20)

    fig.tight_layout()

    figure_name = '%s.html' % handles['figure_filename']
    mpld3.save_html(fig, figure_name)

################
# write output #
################

data = dict()

output_args = dict()
for i, image in enumerate(segmentations):
    if image is None:
        continue
    output_args['Objects%d' % (i+1)] = image

jtapi.writedata(handles, data)
jtapi.writeoutputargs(handles, output_args)
