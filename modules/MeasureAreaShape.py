import sys
import numpy as np
from skimage import measure
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
measurement_names.append('morphology')  # measure by default
if input_args['Zernike']:
    measurement_names.append('zernike')


##############
# processing #
##############

data = dict()
for i, obj_image in enumerate(objects):

    obj_name = object_names[i]  # is this actually the correct one?

    # Get coordinates of region containing individual objects
    regions = measure.regionprops(obj_image)

    # Calculate threshold across the whole image
    RADIUS = 100

    measurements = dict()
    for m in measurement_names:
        measurements[m] = list()
    for j, r in enumerate(regions):

        # Crop images to region of current object
        mask = image_util.crop_image(obj_image, bbox=r.bbox)
        mask = mask == (j+1)  # only current object
        # plt.imshow(mask)
        # plt.show()

        # Morphology
        feats = features.measure_morphology(r)
        measurements['morphology'].append(feats)

        # Zernike moments
        if 'zernike' in measurement_names:
            feats = features.measure_zernike(mask, radius=RADIUS)
            measurements['zernike'].append(feats)

    for m in measurement_names:
        feature_names = measurements[m][0].keys()
        for f in feature_names:
            feats = [item[f] for item in measurements[m]]
            data['%s_AreaShape_%s' % (obj_name, f)] = feats

output_args = dict()

# jterator api
writedata(handles, data)
writeoutputargs(handles, output_args)
