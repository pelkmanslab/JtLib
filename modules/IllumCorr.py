import os
import sys
import re
import h5py
import numpy as np
import matplotlib.pyplot as plt
import mpld3
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

orig_image = np.array(input_args['OrigImage'], dtype='float64')
image_name = input_args['ImageName']
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
# Matlab '-v7.3' files are HDF5 files
stats = h5py.File(stats_path, 'r')
stats = stats['stat_values']
# Matlab apparently doesn't transpose arrays before saving them to HDF5
mean_image = np.array(stats['mean'][()], dtype='float64').conj().T
std_image = np.array(stats['std'][()], dtype='float64').conj().T

### correct intensity image for illumination artifact
orig_image[orig_image == 0] = 1
corr_image = (np.log10(orig_image) - mean_image) / std_image
corr_image = (corr_image * np.mean(std_image)) + np.mean(mean_image)
corr_image = 10 ** corr_image

### fix "bad" pixels with non numeric values (NaN or Inf)
ix_bad = np.logical_not(np.isfinite(corr_image))
if ix_bad.sum() > 0:
    print('IllumCorr: identified %d bad pixels' % ix_bad.sum())
    med_filt_image = ndi.filters.median_filter(corr_image, 3)
    corr_image[ix_bad] = med_filt_image[ix_bad]
    corr_image[ix_bad] = med_filt_image[ix_bad]


#####################
## display results ##
#####################

if doPlot:

    # Using 'PyPlot'
    orig_vmin = np.percentile(orig_image, 0.1)
    orig_vmax = np.percentile(orig_image, 99.9)

    corr_vmin = np.percentile(corr_image, 0.1)
    corr_vmax = np.percentile(corr_image, 99.9)

    fig = plt.figure(figsize=(12, 12))
    ax1 = fig.add_subplot(2, 3, 1)
    ax2 = fig.add_subplot(2, 3, 2)
    ax3 = fig.add_subplot(2, 3, 3)
    ax4 = fig.add_subplot(2, 3, 4)
    ax5 = fig.add_subplot(2, 3, 5)
    ax6 = fig.add_subplot(2, 3, 6)

    im1 = ax1.imshow(orig_image, cmap='gray', vmin=orig_vmin, vmax=orig_vmax)
    ax1.set_title('Original image', size=20)

    im2 = ax2.imshow(corr_image, cmap='gray', vmin=corr_vmin, vmax=corr_vmax)
    ax2.set_title('Corrected image', size=20)

    h1 = ax4.hist(orig_image.flatten(), bins=100,
                  range=(orig_vmin, orig_vmax),
                  histtype='stepfilled')
    ax4.set_title('Original histogram', size=20)

    h2 = ax5.hist(corr_image.flatten(), bins=100,
                  range=(corr_vmin, corr_vmax),
                  histtype='stepfilled')
    ax5.set_title('Corrected histogram', size=20)

    im3 = ax3.imshow(mean_image, cmap='jet')
    ax3.set_title('Illumination mean', size=20)

    im4 = ax6.imshow(std_image, cmap='jet')
    ax6.set_title('Illumination std', size=20)

    mousepos = mpld3.plugins.MousePosition(fontsize=20)
    mpld3.plugins.connect(fig, mousepos)

    fid = h5py.File(handles['hdf5_filename'], 'r')
    jobid = fid['jobid'][()]
    fid.close()

    figure_name = os.path.abspath('figures/%s_%s_%05d.html'
                                  % (mfilename, image_name, jobid))

    mpld3.save_html(fig, figure_name)
    # html = mpld3.fig_to_html(fig, template_type='simple')
    # with open(figure_name, 'w') as f:
    #     f.write(html)

    figure2browser(figure_name)


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
