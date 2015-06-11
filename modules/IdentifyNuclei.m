import jtapi.*;
import os.*;
import jtlib.PrimarySegmentation;
import jtlib.SmoothImage;
import jtlib.GetObjectBoundary;
import jtlib.RemoveSmallObjects;
import jtlib.GetBorderObjects;


%%%%%%%%%%%%%%
% read input %
%%%%%%%%%%%%%%

% jterator api
handles = gethandles(STDIN);
input_args = readinputargs(handles);
input_args = checkinputargs(input_args);

InputImage = input_args.IntensityImage;

% Parameters for object smoothing by median filtering
doSmooth = input_args.Smooth;
SmoothingFilterSize = input_args.SmoothingFilterSize;

% Parameters for identifying objects by intensity threshold
ThresholdCorrection = input_args.ThresholdCorrection;
MinimumThreshold = input_args.MininumThreshold;

% Parameters for cutting clumped objects
CuttingPasses = input_args.CuttingPasses;
FilterSize = input_args.FilterSize;
SlidingWindow = input_args.SlidingWindow;
CircularSegment = input_args.CircularSegment;
MaxConcaveRadius = input_args.MaxConcaveRadius;
MaxArea = input_args.MaxArea;
MaxSolidity = input_args.MaxSolidity;
MinArea = input_args.MinArea;
MinCutArea = input_args.MinCutArea;
MinFormFactor = input_args.MinFormFactor;

% Input arguments for saving segmented images
do_SaveSegmentedImage = input_args.SaveSegmentedImage;
InputImageFilename = input_args.IntensityImageFilename;
SegmentationPath = input_args.SegmentationPath;


%%%%%%%%%%%%%%
% processing %
%%%%%%%%%%%%%%

%% Smooth image
if doSmooth
    SmoothedImage = SmoothImage(InputImage, SmoothingFilterSize);
else
    SmoothedImage = InputImage;
end

MaximumThreshold = 2^16;  % assume 16-bit image
CircularSegment = degtorad(CircularSegment);

%% Segment objects
[IdentifiedNuclei, CutLines, SelectedObjects, ~, ~] = PrimarySegmentation(SmoothedImage, ...
                                                                         CuttingPasses, ...
                                                                         FilterSize, SlidingWindow, CircularSegment, MaxConcaveRadius, ...
                                                                         MaxSolidity, MinFormFactor, MinArea, MaxArea, MinCutArea, ...
                                                                         ThresholdCorrection, MinimumThreshold, MaximumThreshold, 'Off');


%% Remove small objects that fall below area threshold
IdentifiedNuclei = RemoveSmallObjects(IdentifiedNuclei, MinCutArea);


%% Make some default measurements

% Calculate object counts
NucleiCount = max(unique(IdentifiedNuclei));

% Calculate cell centroids
tmp = regionprops(logical(IdentifiedNuclei), 'Centroid');
NucleiCentroid = cat(1, tmp.Centroid);
if isempty(NucleiCentroid)
    NucleiCentroid = [0 0];   % follow CP's convention to save 0s if no object
end

% Calculate cell boundary
NucleiBoundary = GetObjectBoundary(IdentifiedNuclei);

% Get indices of nuclei at the border of images
[BorderIds, BorderIx] = GetBorderObjects(IdentifiedNuclei);


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
data.Nuclei_Count = NucleiCount;
data.Nuclei_Centroids = NucleiCentroid;
data.Nuclei_Boundary = NucleiBoundary;
data.Nuclei_BorderIds = BorderIds;
data.Nuclei_BorderIx = BorderIx;

output_args = struct();
output_args.Nuclei = IdentifiedNuclei;

% jterator api
writedata(handles, data);
writeoutputargs(handles, output_args);
