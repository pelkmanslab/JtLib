import numpy as np
import glob
import os
import h5py
import scipy.ndimage as ndi
from jtlib import file_util


def load_statistics(stats_directory, stats_filename_pattern,
                    reference_filename):
    '''
    Load pre-calculated illumination statistics from file.
    '''
    # determine channel number from reference filename
    (microscope, pattern) = file_util.get_microscope_type(reference_filename)
    channel = file_util.get_image_channel(reference_filename, microscope)
    # build absolute path to illumination correction file
    # determine dynamically from stats_filename_pattern
    glob_pattern = stats_filename_pattern % channel
    stats_filename = glob.glob(os.path.join(stats_directory, glob_pattern))
    if len(stats_filename) > 1:
        raise Exception('More than one statistics file matches the pattern.')
    elif len(stats_filename) == 0:
        raise Exception('No statistics file matches globbing pattern %s.'
                        % stats_filename)
    else:
        stats_filename = stats_filename[0]
    # load illumination correction file and extract statistics
    # Matlab's '-v7.3' files are actually HDF5 files!
    stats = h5py.File(stats_filename, 'r')
    stats = stats['stat_values']
    # Matlab transposes arrays, so we have to revert that
    mean_im = np.array(stats['mean'][()], dtype='float64').conj().T
    std_im = np.array(stats['std'][()], dtype='float64').conj().T
    return (mean_im, std_im)


def smooth_statistics(mean_im, std_im, filter_size):
    '''
    Smooth illumination correction masks of pre-calculated statistics
    with a gaussian filter.
    '''
    mean_im = ndi.gaussian_filter(mean_im, sigma=filter_size)
    std_im = ndi.gaussian_filter(std_im, sigma=filter_size)
    return (mean_im, std_im)


def apply_statistics(im, mean_im, std_im):
    '''
    Apply illumination correction to an image using pre-calculated statistics.
    '''
    im[im == 0] = 1
    # Z-score log-transformed pixel values
    corr_im = (np.log10(im) - mean_im) / std_im
    corr_im = (corr_im * np.mean(std_im)) + np.mean(mean_im)
    corr_im = 10 ** corr_im
    return corr_im


def fix_bad_pixels(im):
    '''
    Fix "bad" (non-finite and extremely high) pixel values.
    '''
    # Fix non-finite pixels (Inf or Nan)
    ix_bad = np.logical_not(np.isfinite(im))
    if ix_bad.sum() > 0:
        print('fix_bad_pixels: identified %d bad pixels' % ix_bad.sum())
        med_filt_image = ndi.filters.median_filter(im, 3)
        im[ix_bad] = med_filt_image[ix_bad]
        im[ix_bad] = med_filt_image[ix_bad]
    # Fix extreme pixels
    percent = 99.9999
    thresh = np.percentile(im, percent)
    print('fix_bad_pixels: %d extreme pixel values (above %f percentile)\
           were set to %d' % (np.sum(im > thresh), percent, thresh))
    im[im > thresh] = thresh
    return im
