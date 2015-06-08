import sys
import numpy as np
import os
import pylab as plt
import mpld3
from jtapi import *
from jtlib import illumcorr


##############
# read input #
##############

# jterator api
handles_stream = sys.stdin
handles = gethandles(handles_stream)
input_args = readinputargs(handles)
input_args = checkinputargs(input_args)

input_im = np.array(input_args['OriginalImage'], dtype='float64')
reference_filename = input_args['ReferenceFilename']
stats_directory = input_args['StatsDirectory']
stats_filename_pattern = input_args['StatsFilenamePattern']
do_smooth = input_args['Smooth']


##############
# processing #
##############

# load illumination statistics
if not os.path.isabs(stats_directory):
    stats_directory = os.path.join(handles['project_path'], stats_directory)
(mean_im, std_im) = illumcorr.load_statistics(stats_directory,
                                              stats_filename_pattern,
                                              reference_filename)

if do_smooth:
    (mean_im, std_im) = illumcorr.smooth_statistics(mean_im, std_im,
                                                    filter_size)

# correct intensity image for illumination artifact
corr_im = illumcorr.apply_statistics(input_im, mean_im, std_im)

# fix "bad" pixels
corr_im = illumcorr.fix_bad_pixels(corr_im)


###################
# display results #
###################

if handles['plot']:

    fig = plt.figure(figsize=(10, 10))

    rescale_lower = np.percentile(input_im, 0.1)
    rescale_upper = np.percentile(input_im, 99.9)

    ax1 = fig.add_subplot(2, 3, 1)
    im1 = ax1.imshow(input_im, cmap='gray',
                     vmin=rescale_lower,
                     vmax=rescale_upper)
    ax1.set_title('Original image', size=20)

    ax2 = fig.add_subplot(2, 3, 2)
    im2 = ax2.imshow(corr_im, cmap='gray',
                     vmin=rescale_lower,
                     vmax=rescale_upper)
    ax2.set_title('Corrected image', size=20)

    ax3 = fig.add_subplot(2, 3, 3)
    im3 = ax3.imshow(mean_im, cmap='jet',
                     vmin=np.percentile(mean_im, 0.1),
                     vmax=np.percentile(mean_im, 99.9))
    ax3.set_title('Illumination mean', size=20)

    ax4 = fig.add_subplot(2, 3, 4)
    h1 = ax4.hist(input_im.flatten(), bins=100,
                  range=(rescale_lower, rescale_upper),
                  histtype='stepfilled')
    ax4.set_title('Original histogram', size=20)

    ax5 = fig.add_subplot(2, 3, 5)
    h2 = ax5.hist(corr_im.flatten(), bins=100,
                  range=(rescale_lower, rescale_upper),
                  histtype='stepfilled')
    ax5.set_title('Corrected histogram', size=20)

    ax6 = fig.add_subplot(2, 3, 6)
    im4 = ax6.imshow(std_im, cmap='jet',
                     vmin=np.percentile(std_im, 0.1),
                     vmax=np.percentile(std_im, 99.9))
    ax6.set_title('Illumination std', size=20)

    mousepos = mpld3.plugins.MousePosition(fontsize=20)
    mpld3.plugins.connect(fig, mousepos)

    figure_name = '%s.html' % handles['figure_filename']
    mpld3.save_html(fig, figure_name)


################
# write output #
################

output_args = dict()
output_args['CorrectedImage'] = corr_im

data = dict()

# jterator api
writedata(handles, data)
writeoutputargs(handles, output_args)
