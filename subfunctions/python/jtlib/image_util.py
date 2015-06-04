import numpy as np


def crop_image(im, bbox):
    '''
    Crop image according to bounding box coordinates.
    Also pad the resulting image with one line of zeros along each dimension.

    Arguments:
        :im:        image (numpy array)
        :bbox:      list of 4 integers (bounding box coordinates
                    as returned by skimage.measure.regionprops or mahotas)

    Returns:
        numpy array
    '''
    im = im[bbox[0]:bbox[2], bbox[1]:bbox[3]]
    # pad image with zeros
    im = np.lib.pad(im, (1, 1), 'constant', constant_values=(0))
    return im


def downsample_image(im, bins):
    '''
    Murphy et al. 2002
    "Robust Numerical Features for Description and Classification of
    Subcellular Location Patterns in Fluorescence Microscope Images"

    Arguments:
        :im:        gray-scale image (numpy array)
        :bins:      integer

    Returns:
        numpy array
    '''
    if bins != 256:
        min_val = im.min()
        max_val = im.max()
        ptp = max_val - min_val
        if ptp:
            return np.array((im-min_val).astype(float) * bins/ptp,
                            dtype=np.uint8)
        else:
            return np.array(im.astype(float), dtype=np.uint8)
