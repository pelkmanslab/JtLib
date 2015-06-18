import sys
import numpy as np
from scipy import misc
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable
import mpld3
import jtapi


##############
# read input #
##############

handles_stream = sys.stdin
handles = jtapi.gethandles(handles_stream)
input_args = jtapi.readinputargs(handles)
input_args = jtapi.checkinputargs(input_args)

image_filenames = list()
for i in range(1, 5):
    key = 'ImageFilename%d' % i
    if key in input_args:
        image_filenames.append(input_args[key])


##############
# processing #
##############

images = list()
for f in image_filenames:
    if f is None:
        images.append(None)
        continue
    images.append(np.array(misc.imread(f), dtype='float64'))


###################
# display results #
###################

if handles['plot']:

    fig = plt.figure(figsize=(10, 10))

    for i in xrange(len(images)):
        ax = fig.add_subplot(2, 2, i+1)

        rescale_lower = np.percentile(images[i], 0.1)
        rescale_upper = np.percentile(images[i], 99.9)

        im = ax.imshow(images[i], cmap='gray',
                       vmin=rescale_lower,
                       vmax=rescale_upper)
        image_name = handles['input'][i]['value']
        ax.set_title(image_name, size=20)

        divider = make_axes_locatable(ax)
        cax = divider.append_axes("right", size="5%", pad=0.05)
        fig.colorbar(im, cax=cax)

    fig.tight_layout()

    # Save figure as html file and open it in the browser
    figure_name = handles['figure_filename'] + '.html'
    mpld3.save_html(fig, figure_name)


################
# write output #
################

output_args = dict()
for i, image in enumerate(images):
    if image is None:
        continue
    output_args['LoadedImage%d' % (i+1)] = image

data = dict()

jtapi.writedata(handles, data)
jtapi.writeoutputargs(handles, output_args)
