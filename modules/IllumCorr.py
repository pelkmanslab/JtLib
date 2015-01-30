import os
import sys
import re
import h5py
import numpy as np
import scipy.ndimage as ndi
from jterator.api import *


mfilename = re.search('(.*).py', os.path.basename(__file__)).group(1)

###############################################################################
## jterator input

print("jt - %s:" % mfilename)

### read YAML from standard input
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

orig_image = np.array(input_args['OrigImage'])
stats_directory = input_args['StatsDirectory']
stats_filename = input_args['StatsFilename']
doPlot = input_args['doPlot']


################
## processing ##
################

### build absolute path to illumination correction file
stats_path = os.path.join(stats_directory, stats_filename)
if not os.path.isabs(stats_path):
    stats_path = os.path.join(os.getcwd(), stats_path)

### load illumination correction file and extract statistics
stats = h5py.File(stats_path, 'r')
stats = stats['stat_values']
mean_image = np.array(stats['mean'][()], dtype='float64')
std_image = np.array(stats['std'][()], dtype='float64')

### correct intensity image for illumination artifact
orig_image[orig_image == 0] = 1
corr_image = (np.log10(orig_image) - mean_image) / std_image
corr_image = (corr_image * mean(std_image)) + mean(mean_image)
corr_image = 10 ** corr_image

### fix "bad" pixels with non numeric values (NaN or Inf)
ix_bad = np.logical_not(np.isfinite(corr_image))
print('IllumCorr: identified %d bad pixels' % len(ix_bad))
# med_filt_image = ndi.filters.median_filter(corr_image, 3)
med_filt_image = ndi.filters.generic_filter(corr_image, np.nanmedian, size=3)
corr_image[ix_bad] = med_filt_image[ix_bad]
corr_image[ix_bad] = med_filt_image[ix_bad]


#####################
## display results ##
#####################

if doPlot:

    # Using 'PyPlot'
    orig_vmin = np.percentile(orig_image, 0.001)
    orig_vmax = np.percentile(orig_image, 0.999)

    corr_vmin = np.percentile(corr_image, 0.001)
    corr_vmax = np.percentile(corr_image, 0.999)

    figure

    subplot(221)
    imshow(orig_image.T, cmap="gray", vmin=orig_vmin, vmax=orig_vmax)
    title("Original image")

    subplot(222)
    imshow(corr_image.T, cmap="gray", vmin=corr_vmin, vmax=corr_vmax)
    title("Corrected image")

    subplot(223)
    plt.hist(orig_image[:], bins=1000, range=(orig_vmin, orig_vmax),
             histtype="stepfilled")
    title("Original histogram")

    subplot(224)
    plt.hist(corr_image[:], bins=1000, range=(corr_vmin, corr_vmax),
             histtype="stepfilled")
    title("Corrected histogram")

    fig = gcf()

    mousepos = mpld3.plugins.MousePosition(fontsize=14)
    mpld3.plugins.connect(fig, mousepos)

    fid = h5py.File(handles['hdf5_filename'], 'r')
    jobid = fid['jobid'][()]
    fid.close()
    figure_name = 'figures/%s_%05d.html' % (mfilename, jobid)
    mpld3.save_html(fig, figure_name)
    figure2browser(os.path.abspath(figure_name))


####################
## prepare output ##
####################

output_args = dict()
output_args["CorrImage"] = corr_image
data = dict()


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
