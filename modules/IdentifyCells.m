import jtapi.*;
import plot2svg.*;
import plia.segment.segmentSecondary;
import plia.smoothImage;
import plia.calculateThresholdLevel;
import plia.determineObjectBoundary;
import plia.determineBorderObjects;
import plia.relateObjects;


%%%%%%%%%%%%%%
% read input %
%%%%%%%%%%%%%%

% jterator api
handles = gethandles(STDIN);
inputArgs = readinputargs(handles);
inputArgs = checkinputargs(inputArgs);

InputImage = inputArgs.IntensityImage;
Nuclei = inputArgs.SeedImage;

% Input arguments for object smoothing by median filtering
doSmooth = inputArgs.Smooth;
SmoothingFilterSize = inputArgs.SmoothingFilterSize;

% Input arguments for identifying objects by iterative intensity thresholding
ThresholdCorrection = inputArgs.ThresholdCorrection;
MinimumThreshold = inputArgs.MinimumThreshold;

% Input arguments for saving segmented images
do_SaveSegmentedImage = inputArgs.SaveSegmentedImage;
InputImageFilename = inputArgs.InputImageFilename;
SegmentationPath = inputArgs.SegmentationPath;


%%%%%%%%%%%%%%
% processing %
%%%%%%%%%%%%%%

InputImage = InputImage ./ 2^16;
MinimumThreshold = MinimumThreshold / 2^16;
MaximumThreshold = 1;

%% Smooth image
if doSmooth
    SmoothedImage = smoothImage(InputImage, SmoothingFilterSize);
else
    SmoothedImage = InputImage;
end

%% Perform segmentation

IdentifiedCells = segmentSecondary(SmoothedImage, ...
                                    Nuclei, Nuclei, ...
                                    ThresholdCorrection, ...
                                    MinimumThreshold, ...
                                    MaximumThreshold);                             

%% Make some default measurements

% Calculate object counts
CellCount = max(unique(IdentifiedCells));

% Relate 'nuclei' to 'cells'
[NucleiParentIds, ChildrenCount] = relateObjects(IdentifiedCells, Nuclei);

% Calculate cell centroids
tmp = regionprops(logical(IdentifiedCells),'Centroid');
CellCentroid = cat(1, tmp.Centroid);
if isempty(CellCentroid)
    CellCentroid = [0 0];   % follow CP's convention to save 0s if no object
end

% Calculate cell boundary
CellBoundary = determineObjectBoundary(IdentifiedCells);

% Get indices of cells at the border of images
[BorderIds, BorderIx] = determineBorderObjects(IdentifiedCells);


%%%%%%%%%%%%%%%%%%%
% display results %
%%%%%%%%%%%%%%%%%%%

if handles.plot

    B = bwboundaries(IdentifiedCells, 'holes');
    LabeledCells = label2rgb(bwlabel(IdentifiedCells),'jet','k','shuffle');
    
    fig = figure;

    subplot(2,1,1), imagesc(InputImage, [quantile(InputImage(:),0.001) quantile(InputImage(:),0.999)]),
    colormap(gray)
    title('Outlines of identified cells');
    hold on
    for k = 1:length(B)
        boundary = B{k};
        plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 1)
    end
    hold off
    freezeColors

    subplot(2,1,2), imagesc(LabeledCells),
    title('Identified cells');
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
                                  '.png', '_segmentedCells.png');
    SegmentationPath = fullfile(handles.project_path, SegmentationPath);
    SegmentationFilename = fullfile(SegmentationPath, SegmentationFilename);
    if ~isdir(SegmentationPath)
        mkdir(SegmentationPath)
    end
    imwrite(uint16(IdentifiedCells), SegmentationFilename);
    fprintf('%s: Segmented ''cells'' were saved to file: "%s"\n', ...
            mfilename, SegmentationFilename)
end

        
%%%%%%%%%%%%%%%%
% write output %
%%%%%%%%%%%%%%%%

data = struct();
data.Cells_Count = CellCount;
data.Cells_Centroids = CellCentroid;
data.Cells_Boundary = CellBoundary;
data.Cells_BorderIds = BorderIds;
data.Cells_BorderIx = BorderIx;
data.Nuclei_ParentIds = NucleiParentIds;
% Cells - Nuclei relationship hard-coded for now

output_args = struct();
output_args.Cells = IdentifiedCells;

% jterator api
writedata(handles, data);
writeoutputargs(handles, output_args);
