importall jtapi
using MAT
using HDF5
using PyPlot
using PyCall
@pyimport mpld3
@pyimport scipy.ndimage as ndi
@pyimport numpy as np


mfilename = match(r"([^/]+)\.jl$", @__FILE__()).captures[1]

###############################################################################
## jterator input

@printf("jt - %s:\n", mfilename)

### read YAML from standard input
handles_stream = readall(STDIN)

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

orig_image = input_args["OrigImage"]
image_name = input_args["ImageName"]

stats_directory = input_args["StatsDirectory"]
stats_filename = input_args["StatsFilename"]

doPlot = input_args["doPlot"]


################
## processing ##
################

### helper function for the actual illumination correction step
function correct(orig_image, mean_image, std_image)
    orig_image[orig_image .== 0] = 1 
    corr_image = (log10(orig_image) - mean_image) ./ std_image
    corr_image = (corr_image .* mean(std_image)) + mean(mean_image)
    corr_image = 10 .^ corr_image
end

### build absolute path to illumination correction file
stats_path = joinpath(stats_directory, stats_filename)
if ~isabspath(stats_path)
    stats_path = joinpath(pwd(), stats_path)
end

### load illumination correction file
stats = matread(stats_path)

### extract pre-calculated statistics
mean_image = float64(stats["stat_values"]["mean"])
std_image = float64(stats["stat_values"]["std"])

### correct intensity image for illumination artifact
corr_image = correct(orig_image, mean_image, std_image)

### fix "bad" pixels
ix_bad = ~(isfinite(corr_image))
# med_filt_image = ndi.filters[:median_filter](corr_image, 3)
med_filt_image = ndi.filters[:generic_filter](corr_image, np.nanmedian, size=3)
corr_image[ix_bad] = med_filt_image[ix_bad]
corr_image[ix_bad] = med_filt_image[ix_bad]



#####################
## display results ##
#####################

if doPlot=="Yes"

    # Using 'PyPlot'
    orig_vmin = quantile(orig_image[:],0.001)
    orig_vmax = quantile(orig_image[:],0.999)

    corr_vmin = quantile(corr_image[:],0.001)
    corr_vmax = quantile(corr_image[:],0.999)

    figure

    subplot(221)
    imshow(orig_image', cmap="gray", vmin=orig_vmin, vmax=orig_vmax)
    title("Original image")

    subplot(222)
    imshow(corr_image', cmap="gray", vmin=corr_vmin, vmax=corr_vmax)
    title("Corrected image")

    subplot(223)
    plt.hist(orig_image[:], bins=1000, range=(orig_vmin, orig_vmax), histtype="stepfilled")
    title("Original histogram")

    subplot(224)
    plt.hist(corr_image[:], bins=1000, range=(corr_vmin, corr_vmax), histtype="stepfilled")
    title("Corrected histogram")

    fig = gcf()

    jobid = h5read(handles["hdf5_filename"], "jobid")

    mousepos = mpld3.plugins[:MousePosition](fontsize=14)
    mpld3.plugins[:connect](fig, mousepos)

    figure_name = @sprintf("figures/%s_%s_%05d.html", mfilename, image_name, jobid)
    mpld3.save_html(fig, figure_name)
    figure2browser(abspath(figure_name))

end


####################
## prepare output ##
####################

output_args = Dict()
output_args["CorrImage"] = corr_image

data = Dict()


###############################################################################
## jterator output

### write measurement data to HDF5
writedata(handles, data)

### write temporary pipeline data to HDF5
writeoutputargs(handles, output_args)

###############################################################################
