import jtapi.*;
import os.*;
import plia.segment.segmentPrimary;
import plia.smoothImage;
import plia.determineObjectBoundary;
import plia.removeSmallObjects;
import plia.determineBorderObjects;


%%%%%%%%%%%%%%
% read input %
%%%%%%%%%%%%%%

% jterator api
handles = jtapi.gethandles(STDIN);
inputArgs = jtapi.readinputargs(handles);
inputArgs = jtapi.checkinputargs(inputArgs);

InputImage = inputArgs.IntensityImage;

% Parameters for object smoothing by median filtering
doSmooth = inputArgs.Smooth;
SmoothingFilterSize = inputArgs.SmoothingFilterSize;

% Parameters for identifying objects by intensity threshold
ThresholdCorrection = inputArgs.ThresholdCorrection;
MinimumThreshold = inputArgs.MininumThreshold;
MaximumThreshold = inputArgs.MaximumThreshold;

% Parameters for cutting clumped objects
CuttingPasses = inputArgs.CuttingPasses;
FilterSize = inputArgs.FilterSize;
SlidingWindow = inputArgs.SlidingWindow;
CircularSegment = inputArgs.CircularSegment;
MaxConcaveRadius = inputArgs.MaxConcaveRadius;
MaxArea = inputArgs.MaxArea;
MaxSolidity = inputArgs.MaxSolidity;
MinArea = inputArgs.MinArea;
MinCutArea = inputArgs.MinCutArea;
MinFormFactor = inputArgs.MinFormFactor;

% Input arguments for saving segmented images
do_SaveSegmentedImage = inputArgs.SaveSegmentedImage;
InputImageFilename = inputArgs.IntensityImageFilename;
SegmentationPath = inputArgs.SegmentationPath;


%%%%%%%%%%%%%%
% processing %
%%%%%%%%%%%%%%

InputImage = InputImage ./ 2^16;
MinimumThreshold = MinimumThreshold / 2^16;
MaximumThreshold = MaximumThreshold / 2^16;

% %debugging
% MinimumThreshold = 0.0019;
% MaximumThreshold = 0.02;

%% Smooth image
if doSmooth
    SmoothedImage = smoothImage(InputImage, SmoothingFilterSize);
else
    SmoothedImage = InputImage;
end

CircularSegment = degtorad(CircularSegment);

%% Segment objects
[IdentifiedNuclei, CutLines, SelectedObjects, ~, ~] = segmentPrimary(SmoothedImage, ...
                                                                     CuttingPasses, ...
                                                                     FilterSize, SlidingWindow, CircularSegment, MaxConcaveRadius, ...
                                                                     MaxSolidity, MinFormFactor, MinArea, MaxArea, MinCutArea, ...
                                                                     ThresholdCorrection, MinimumThreshold, MaximumThreshold, 'Off');


%% Remove small objects that fall below area threshold
IdentifiedNuclei = removeSmallObjects(IdentifiedNuclei, MinCutArea);


%% Make some default measurements

% Calculate object counts
ObjectIds = unique(IdentifiedNuclei(IdentifiedNuclei > 0));

% Calculate cell centroids
tmp = regionprops(logical(IdentifiedNuclei), 'Centroid');
NucleiCentroid = cat(1, tmp.Centroid);
if isempty(NucleiCentroid)
    NucleiCentroid = [0 0];   % follow CP's convention to save 0s if no object
end

% Calculate cell boundary
NucleiBoundary = determineObjectBoundary(IdentifiedNuclei);

% Get indices of nuclei at the border of images
[BorderIds, BorderIx] = determineBorderObjects(IdentifiedNuclei);


%%%%%%%%%%%%%%%%%%%
% display results %
%%%%%%%%%%%%%%%%%%%
       
if handles.plot

    B = bwboundaries(IdentifiedNuclei, 'holes');
    imCutShapeObjectsLabel = label2rgb(bwlabel(IdentifiedNuclei),'jet','k','shuffle');
    AllSelected = SelectedObjects(:,:,1);

    fig = figure;

    subplot(2,2,2), imagesc(logical(AllSelected==1)),
    title('Cut lines on selected original objects');
    hold on
    redOutline = cat(3, ones(size(AllSelected)), zeros(size(AllSelected)), zeros(size(AllSelected)));
    h = imagesc(redOutline);
    set(h, 'AlphaData', imdilate(logical(sum(CutLines, 3)), strel('disk', 12)))
    hold off
    freezeColors

    subplot(2,2,1), imagesc(AllSelected), colormap('jet'),
    title('Selected original objects');
    freezeColors

    subplot(2,2,3), imagesc(InputImage, [quantile(InputImage(:),0.001) quantile(InputImage(:),0.999)]),
    colormap(gray)
    title('Outlines of separated objects');
    hold on
    for k = 1:length(B)
        boundary = B{k};
        plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 1)
    end
    hold off
    freezeColors

    subplot(2,2,4), imagesc(imCutShapeObjectsLabel),
    title('Separated objects');
    freezeColors

    % Save figure as pdf
    figure_filename = sprintf('%s.png', handles.figure_filename);
    set(fig, 'PaperPosition', [0 0 5 5], 'PaperSize', [5 5]);
    saveas(fig, figure_filename);

end


%%%%%%%%%%%%%%%%
% save results %
%%%%%%%%%%%%%%%%

if do_SaveSegmentedImage
    SegmentationFilename = strrep(os.path.basename(InputImageFilename), ...
                                  '.png', '_segmentedNuclei.png');
    SegmentationPath = fullfile(handles.project_path, SegmentationPath);
    SegmentationFilename = fullfile(SegmentationPath, SegmentationFilename);
    if ~isdir(SegmentationPath)
        mkdir(SegmentationPath)
    end
    imwrite(uint16(IdentifiedNuclei), SegmentationFilename);
    fprintf('%s: Segmented ''nuclei'' were saved to file: "%s"\n', ...
            mfilename, SegmentationFilename)
end


%%%%%%%%%%%%%%%%
% write output %
%%%%%%%%%%%%%%%%

data = struct();
data.Nuclei_Centroids = NucleiCentroid;
data.Nuclei_Boundary = NucleiBoundary;
data.Nuclei_BorderIds = BorderIds;
data.Nuclei_BorderIx = BorderIx;
data.Nuclei_OriginalObjectIds = ObjectIds;

output_args = struct();
output_args.Nuclei = IdentifiedNuclei;

jtapi.writedata(handles, data);
jtapi.writeoutputargs(handles, output_args);
