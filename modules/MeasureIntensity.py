import os
import sys
import re
import h5py
import numpy as np
import matplotlib.pyplot as plt
import mpld3
from skimage import measure
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

images = list()
images.append(np.array(input_args['Image1'], dtype='float64'))
images.append(np.array(input_args['Image2'], dtype='float64'))
images.append(np.array(input_args['Image3'], dtype='float64'))
images.append(np.array(input_args['Image4'], dtype='float64'))

image_names = list()
image_names.append(input_args['ImageName1'])
image_names.append(input_args['ImageName2'])
image_names.append(input_args['ImageName3'])
image_names.append(input_args['ImageName4'])

objects = list()
objects.append(np.array(input_args['Object1'], dtype='int'))
objects.append(np.array(input_args['Object2'], dtype='int'))

object_names = list()
object_names.append(input_args['ObjectName1'])
object_names.append(input_args['ObjectName2'])

doPlot = input_args['doPlot']


################
## processing ##
################

data = dict()
for i, obj in enumerate(objects):

    object_name = object_names[i]

    ### get object ids and total number of objects
    object_ids = np.unique(obj)
    object_ids = object_ids[object_ids != 0]  # remove '0' background
    object_num = object_ids.shape[0]

    for j, image in enumerate(images):

        image_name = image_names[j]
        ### measure object properties
        regions = measure.regionprops(obj, image)

        ### extract intensity measurements
        object_total_int = np.array([np.nansum(image[obj == i]) for i in object_ids])
        object_max_int = np.array([regions[i].max_intensity for i in range(object_num)])
        object_mean_int = np.array([regions[i].mean_intensity for i in range(object_num)])
        object_min_int = np.array([regions[i].min_intensity for i in range(object_num)])

        ### extract spatial moments
        # object_moments_hu = [regions[i].moments_hu for i in range(object_num)]
        # objects_weighted_moments_hu = [regions[i].weighted_moments_hu for i in range(object_num)]

        ####################
        ## prepare output ##
        ####################

        data['%s_Intensity_%s_MaxIntensity' % (object_name, image_name)] = object_max_int
        data['%s_Intensity_%s_MeanIntensity' % (object_name, image_name)] = object_mean_int
        data['%s_Intensity_%s_MinIntensity' % (object_name, image_name)] = object_min_int
        data['%s_Intensity_%s_TotalIntensity' % (object_name, image_name)] = object_total_int


        #####################
        ## display results ##
        #####################

        if doPlot:

            # This is just a fancy example plot

            X = np.column_stack((object_total_int, object_max_int,
                                object_mean_int, object_min_int))

            X_names = [
                        'total intensity', 'max intensity',
                        'mean intensity', 'min intensity'
                        ]

            # dither the data for clearer plotting
            X += 0.1 * np.random.random(X.shape)

            n = X.shape[1]

            fig, ax = plt.subplots(6, 6, sharex="col", sharey="row", figsize=(12, 12))
            fig.subplots_adjust(left=0.05, right=0.95, bottom=0.05, top=0.95,
                                hspace=0.3, wspace=0.3)

            labels = ['cell {0}'.format(int(i)) for i in object_ids]

            for i in range(n):
                for j in range(n):
                    points = ax[(n-1)-i, j].scatter(X[:, j], X[:, i], s=40, alpha=0.6)
                    ax[(n-1)-i, j].set_xlabel(X_names[i], size=12)
                    ax[(n-1)-i, j].set_ylabel(X_names[j], size=12)

            # remove ticks and tick labels
            for axi in ax.flat:
                for axis in [axi.xaxis, axi.yaxis]:
                    axis.set_major_formatter(plt.NullFormatter())
                    axis.set_major_locator(plt.NullLocator())

            # connect linked brush
            linkedbrush = mpld3.plugins.LinkedBrush(points)
            mpld3.plugins.connect(fig, linkedbrush)

            # labels = ['cell {0}'.format(int(i)) for i in object_ids]
            # tooltip = mpld3.plugins.PointLabelTooltip(points, labels=labels)
            # mpld3.plugins.connect(fig, tooltip)


            # Save figure as html file and open it in the browser
            fid = h5py.File(handles['hdf5_filename'], 'r')
            jobid = fid['jobid'][()]
            fid.close()
            figure_name = 'figures/%s_%s_%05d.html' % (mfilename, object_name, jobid)
            mpld3.save_html(fig, figure_name)
            figure2browser(os.path.abspath(figure_name))

output_args = dict()


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
