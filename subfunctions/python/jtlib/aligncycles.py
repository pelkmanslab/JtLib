import re
import json
import os
from jtlib import file_util


def load_shift_descriptor(shift_descriptor_filename):
    '''
    Load JSON shift descriptor file from disk and return as python dictionary.
    '''
    if not shift_descriptor_filename:
        raise Exception('No shift descriptor filename provided.')
    if not os.path.exists(shift_descriptor_filename):
        raise Exception('Shift descriptor file "%s" does not exist.' %
                        shift_descriptor_filename)
    try:
        return json.load(open(shift_descriptor_filename))
    except ValueError as e:
        raise Exception('Loading shift descriptor "%s" failed:\n%s' %
                        (shift_descriptor_filename, e))


def get_index_from_shift_descriptor(shift_descriptor, reference_filename):
    '''
    Get the index of a file from the list of filenames stored in the JSON shift
    descriptor file.
    '''
    # get search pattern
    (microscope, pattern) = file_util.get_microscope_type(reference_filename)
    filename_match = re.search(pattern, reference_filename).group(0)
    if filename_match is None:
        raise Exception('Pattern doesn\'t match reference filename.')
    # find file that matches pattern
    i = -1
    index = list()
    for site in shift_descriptor['fileName']:
        i += 1
        if re.search(filename_match, site):
            index.append(i)
            break
    # Assert that there is only one file matching the pattern
    if len(index) == 0:
        raise Exception('No file found that matches reference pattern.')
    elif len(index) > 1:
        raise Exception('Several files found that match reference pattern.')
    else:
        index = index[0]
    return index


def shift_and_crop_image(im, shift_descriptor, index, crop_only=False):
    '''
    Shift and crop an image according to the precalculated values stored in the
    JSON shift descriptor file.
    '''
    upper = shift_descriptor['upperOverlap']
    lower = shift_descriptor['lowerOverlap']
    left = shift_descriptor['leftOverlap']
    right = shift_descriptor['rightOverlap']
    y = shift_descriptor['yShift'][index]
    x = shift_descriptor['xShift'][index]
    if crop_only:
        return im[lower:-(upper+1), right:-(left+1)]
    else:
        return im[(lower-y):-(upper+y+1), (right-x):-(left+x+1)]
