import os
import sys
import re
import h5py
import numpy as np
import matplotlib.pyplot as plt
import mpld3
from skimage import measure
from jterator.api import *


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

image = np.array(input_args['Image'], dtype='float64')
objects = np.array(input_args['Objects'], dtype='int')
object_name = input_args['ObjectName']

doPlot = input_args['doPlot']


################
## processing ##
################

### get object ids and total number of objects
object_ids = np.unique(objects)
object_ids = object_ids[object_ids != 0]  # remove '0' background
object_num = object_ids.shape[0]

### measure object properties
regions = measure.regionprops(objects, image)

### extract area/shape measurements
object_area = np.array([regions[i].area for i in range(object_num)])
object_eccentricity = np.array([regions[i].eccentricity for i in range(object_num)])
object_perimeter = np.array([regions[i].perimeter for i in range(object_num)])
object_solidity = np.array([regions[i].solidity for i in range(object_num)])
object_equidiameter = np.array([regions[i].equivalent_diameter for i in range(object_num)])
object_formfactor = (4.0 * np.pi * object_area) / (object_perimeter**2)

### extract intensity measurements
object_total_int = np.array([np.nansum(image[objects == i]) for i in object_ids])
object_max_int = np.array([regions[i].max_intensity for i in range(object_num)])
object_mean_int = np.array([regions[i].mean_intensity for i in range(object_num)])
object_min_int = np.array([regions[i].min_intensity for i in range(object_num)])

### extract spatial moments
# object_moments_hu = [regions[i].moments_hu for i in range(object_num)]
# objects_weighted_moments_hu = [regions[i].weighted_moments_hu for i in range(object_num)]


#####################
## display results ##
#####################

if doPlot:

    X = np.column_stack((object_area, object_eccentricity, object_solidity,
                        object_formfactor, object_total_int, object_mean_int))

    X_names = [
                'area', 'eccentricity', 'solidity',
                'form factor', 'total intensity', 'mean intensity'
                ]

    # dither the data for clearer plotting
    X += 0.1 * np.random.random(X.shape)

    fig, ax = plt.subplots(6, 6, sharex="col", sharey="row", figsize=(12, 12))
    fig.subplots_adjust(left=0.05, right=0.95, bottom=0.05, top=0.95,
                        hspace=0.3, wspace=0.3)

    labels = ['cell {0}'.format(int(i)) for i in object_ids]

    for i in range(6):
        for j in range(6):
            points = ax[5-i, j].scatter(X[:, j], X[:, i], s=40, alpha=0.6)
            ax[5-i, j].set_xlabel(X_names[i], size=12)
            ax[5-i, j].set_ylabel(X_names[j], size=12)

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
    figure_name = 'figures/%s_%05d.html' % (mfilename, jobid)
    mpld3.save_html(fig, figure_name)
    figure2browser(os.path.abspath(figure_name))


####################
## prepare output ##
####################

data = dict()
data['%s_AreaShape_Area' % object_name] = object_area
data['%s_AreaShape_Eccentricity' % object_name] = object_eccentricity
data['%s_AreaShape_Solidity' % object_name] = object_solidity
data['%s_AreaShape_Perimeter' % object_name] = object_solidity
data['%s_AreaShape_FormFactor' % object_name] = object_formfactor
data['%s_Intensity_MaxIntensity' % object_name] = object_max_int
data['%s_Intensity_MeanIntensity' % object_name] = object_mean_int
data['%s_Intensity_MinIntensity' % object_name] = object_min_int
data['%s_Intensity_TotalIntensity' % object_name] = object_total_int

output_args = dict()
output_args['Area'] = object_area
output_args['Intensity'] = object_total_int

###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
