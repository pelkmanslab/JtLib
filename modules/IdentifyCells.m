import jtapi.*;
import plot2svg.*;
import jtlib.*;

%%%%%%%%%%%%%%
% read input %
%%%%%%%%%%%%%%

% jterator api
handles = gethandles(STDIN);
input_args = readinputargs(handles);
input_args = checkinputargs(input_args);

InputImage = input_args.IntensityImage;
Nuclei = input_args.SeedImage;

% Input arguments for object smoothing by median filtering
doSmooth = input_args.Smooth;
SmoothingFilterSize = input_args.SmoothingFilterSize;

% Input arguments for identifying objects by iterative intensity thresholding
ThresholdCorrection = input_args.ThresholdCorrection;
MinimumThreshold = input_args.MinimumThreshold;

% Input arguments for saving segmented images
do_SaveSegmentedImage = input_args.SaveSegmentedImage;
InputImageFilename = input_args.InputImageFilename;
SegmentationPath = input_args.SegmentationPath;


%%%%%%%%%%%%%%
% processing %
%%%%%%%%%%%%%%

% Stick to CellProfiler rescaling
MinimumThreshold = MinimumThreshold / 2^16;
MaximumThreshold = 1;
InputImage = InputImage ./ 2^16;

%% Smooth image
if doSmooth
    SmoothedImage = SmoothImage(InputImage, SmoothingFilterSize);
else
    SmoothedImage = InputImage;
end

%% Perform segmentation

% IdentifiedCells = IterativeWatershedSegmentation(SmoothedImage, ...
%                                                  Nuclei, ...
%                                                  ThresholdCorrection, ...
%                                                  MinimumThreshold)

IdentifiedCells = CPIterativeWatershedSegmentation(SmoothedImage, ...
                                                   Nuclei, Nuclei, ...
                                                   ThresholdCorrection, ...
                                                   MinimumThreshold)                              

%% Make some default measurements

% Calculate object counts
CellCount = max(unique(IdentifiedCells));

% Relate 'nuclei' to 'cells'
[Parents, Children] = RelateObjects(IdentifiedCells, Nuclei);

% Calculate cell centroids
tmp = regionprops(logical(IdentifiedCells),'Centroid');
CellCentroid = cat(1, tmp.Centroid);
if isempty(CellCentroid)
    CellCentroid = [0 0];   % follow CP's convention to save 0s if no object
end

% Calculate cell boundary
CellBoundary = GetObjectBoundary(IdentifiedCells);

% Get indices of cells at the border of images
[BorderIds, BorderIx] = GetBorderObjects(IdentifiedCells);


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
data.Cells_Children = Children;
data.Cells_Count = CellCount;
data.Cells_Centroids = CellCentroid;
data.Cells_Boundary = CellBoundary;
data.Cells_BorderIds = BorderIds;
data.Cells_BorderIx = BorderIx;
data.Cells_Parents = Parents;
data.Cells_Children = Children;

output_args = struct();
output_args.Cells = IdentifiedCells;

% jterator api
writedata(handles, data);
writeoutputargs(handles, output_args);
