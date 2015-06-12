import sys
import numpy as np
from skimage import filters, measure
import matplotlib.pyplot as plt
import mpld3
from jtapi import *
from plia import features, image_util


##############
# read input #
##############

# jterator api
handles_stream = sys.stdin
handles = gethandles(handles_stream)
input_args = readinputargs(handles)
input_args = checkinputargs(input_args)

image = np.array(input_args['Image'], dtype='float64')
image_name = input_args['ImageName']

objects = list()
for i in range(1, 5):
    name = 'Object%d' % i
    if name in input_args:
        objects.append(np.array(input_args[name], dtype='int'))

object_names = list()
for i in range(1, 5):
    name = 'ObjectName%d' % i
    if name in input_args:
        object_names.append(input_args[name])

measurement_names = []
measurement_names.append('intensity')  # measured by default
if input_args['Hu']:
    measurement_names.append('hu')
if input_args['Haralick']:
    measurement_names.append('haralick')
if input_args['TAS']:
    measurement_names.append('tas')
# if input_args['SURF']:
#     measurement_names.append('surf')


##############
# processing #
##############

data = dict()
for i, obj_image in enumerate(objects):

    if obj_image.shape != image.shape:
        raise Exception('Size of intensity and object image must be identical')

    obj_name = object_names[i]

    # Get coordinates of region containing individual objects
    regions = measure.regionprops(obj_image, intensity_image=image)

    # Calculate threshold across the whole image
    THRESHOLD = filters.threshold_otsu(image)
    BINS = 32

    measurements = dict()
    for m in measurement_names:
        measurements[m] = list()
    for j, r in enumerate(regions):

        # Crop images to region of current object
        mask = image_util.crop_image(obj_image, bbox=r.bbox)
        mask = mask == (j+1)  # only current object

        img = image_util.crop_image(image, bbox=r.bbox)
        img[~mask] = 0
        # plt.imshow(img)
        # plt.show()

        # Intensity
        feats = features.measure_intensity(r, img)
        measurements['intensity'].append(feats)

        # Weighted hu moments
        if 'hu' in measurement_names:
            feats = features.measure_hu(r)
            measurements['hu'].append(feats)

        # Haralick texture features
        if 'haralick' in measurement_names:
            feats = features.measure_haralick(img, bins=BINS)
            measurements['haralick'].append(feats)

        # Threshold Adjacency Statistics
        if 'tas' in measurement_names:
            feats = features.measure_tas(img, threshold=THRESHOLD)
            measurements['tas'].append(feats)

        # # Speeded-Up Robust Features
        # if 'surf' in measurement_names:
        #     feats = features.measure_surf(img)
        #     measurements['surf'].append(feats)

    for m in measurement_names:
        feature_names = measurements[m][0].keys()
        for f in feature_names:
            feats = [item[f] for item in measurements[m]]
            data['%s_Texture_%s_%s' % (obj_name, image_name, f)] = feats

output_args = dict()

# jterator api
writedata(handles, data)
writeoutputargs(handles, output_args)
