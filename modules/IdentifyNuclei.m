import jtapi.*;
import jtlib.*;
import os.*;


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
MininumThreshold = input_args.MininumThreshold;

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

% Parameters for plotting segmentation results
doPlot = input_args.Plot;
% doTestModePerimeter = input_args.doTestModePerimeter;
% doTestModeShape = input_args.doTestModeShape;

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

%% Threshold image
ThresholdMethod = 'Otsu Global';
MaximumThreshold = 2^16;
pObject = 10;

% Calculate threshold
threshhold = ImageThreshold(ThresholdMethod, ...
                            pObject, ...
                            MininumThreshold, ...
                            MaximumThreshold, ...
                            ThresholdCorrection, ...
                            SmoothedImage, ...
                            []);

% Threshold intensity image to detect objects
ThreshImage = zeros(size(SmoothedImage), 'double');
ThreshImage(SmoothedImage > threshhold) = 1;

% Fill holes in objects
FillImage = imfill(double(ThreshImage),'holes');


%% Cut clumped objects:
if ~isempty(FillImage)
    
    %------------------------------------------
    % Select objects in input image for cutting
    %------------------------------------------
    
    ObjectsCut = zeros([size(FillImage),CuttingPasses]);
    ObjectsNotCut = zeros([size(FillImage),CuttingPasses]);
    SelectedObjects = zeros([size(FillImage),CuttingPasses]);
    CutMask = zeros([size(FillImage),CuttingPasses]);
        
    for i = 1:CuttingPasses
        
        if i==1
            Objects = FillImage;
        else
            Objects = ObjectsCut(:,:,i-1);
        end
        
        % Select objects for cutting
        thresholds = struct();
        thresholds.Solidity = MaxSolidity;
        thresholds.FormFactor = MinFormFactor;
        thresholds.UpperSize = MaxArea;
        thresholds.LowerSize = MinArea;
        [SelectedObjects(:,:,i), Objects2Cut, ObjectsNotCut(:,:,i)] = SelectObjects(Objects, thresholds);
        
        
        %------------
        % Cut objects
        %------------
        
        % Smooth image to avoid problems with bwtraceboundary.m
        SmoothDisk = getnhood(strel('disk', FilterSize, 0));
        Objects2Cut = bwlabel(imdilate(imerode(Objects2Cut, SmoothDisk), SmoothDisk));

        % In rare cases, the above smoothing approach creates new, small
        % objects that cause problems. Let's remove them.
        props = regionprops(logical(Objects2Cut), 'Area');
        objArea2 = cat(1, props.Area);
        obj2remove = find(objArea2 < MinArea);
        for j = 1:length(obj2remove)
            Objects2Cut(Objects2Cut == obj2remove(j)) = 0;
        end
        Objects2Cut = bwlabel(Objects2Cut);
        
        % Separate clumped objects along watershed lines

        % PerimeterAnalysis currently cannot handle holes in objects (we may
        % want to implement this in case of big clumps of many objects).
        % Sliding window size is linked to object size. Small object sizes
        % (e.g. in case of images acquired with low magnification) limits
        % maximal size of the sliding window and thus sensitivity of the
        % perimeter analysis.
                
        % Perform perimeter analysis
        PerimeterProps = PerimeterAnalysis(Objects2Cut, SlidingWindow);

        % In rare cases, there may be a unreasonable large number of concave
        % regions, which may cause runtime problems. Let's limit the number of
        % maximally allowed regions.
        AllowedRegions = 30;
        
        % Perform the actual segmentation        
        CutMask(:,:,i) = PerimeterWatershedSegmentation(Objects2Cut, ...
                                                        SmoothedImage, ...
                                                        PerimeterProps, ...
                                                        MaxConcaveRadius, ...
                                                        degtorad(CircularSegment), ...
                                                        MinCutArea, ...
                                                        AllowedRegions);
        ObjectsCut(:,:,i) = bwlabel(Objects2Cut .* ~CutMask(:,:,i));
        
    end
    
    %----------------------------------------------
    % Combine objects from different cutting passes
    %----------------------------------------------

    AllCut = logical(ObjectsCut(:,:,end) + sum(ObjectsNotCut(:,:,2:end), 3));
    
    % Retrieve objects that were not cut (or already cut)
    AllNotCut = logical(sum(ObjectsNotCut, 3));
    IdentifiedNuclei = bwlabel(logical(ObjectsCut(:,:,end) + AllNotCut));

else

    IdentifiedNuclei = bwlabel(zeros(size(FillImage)));
     
end

%% Remove small objects that fall below area threshold
area = regionprops(logical(IdentifiedNuclei), 'Area');
area = cat(1, area.Area);
for i = 1:length(area)
    if area(i) < MinCutArea
        IdentifiedNuclei(IdentifiedNuclei == i) = 0;
    end
end

%% Re-label objects
IdentifiedNuclei = bwlabel(logical(IdentifiedNuclei));


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
if NucleiCount > 0
    NucleiBorderPixel = bwboundaries(IdentifiedNuclei);
    NucleiBorderPixel = NucleiBorderPixel{1}(1:end-1, :);
    P = NucleiBorderPixel(NucleiBorderPixel(:,1) == min(NucleiBorderPixel(:,1)), :);
    P = P(1,:);
    NucleiBoundary = bwtraceboundary(IdentifiedNuclei, P, 'SW'); % anticlockwise
    NucleiBoundary = fliplr(NucleiBoundary(1:end-1,:)); % not closed
else
   NucleiBoundary = [0 0]; 
end

% Get indices of nuclei at the border of images
[BorderIds, BorderIx] = GetBorderObjects(IdentifiedNuclei);


%%%%%%%%%%%%%%%%%%%
% display results %
%%%%%%%%%%%%%%%%%%%
       
if doPlot

    B = bwboundaries(AllCut, 'holes');
    imCutShapeObjectsLabel = label2rgb(bwlabel(AllCut),'jet','k','shuffle');
    AllSelected = SelectedObjects(:,:,1);

    fig = figure;

    subplot(2,2,2), imagesc(logical(AllSelected==1)),
    title('Cut lines on selected original objects');
    hold on
    redOutline = cat(3, ones(size(AllSelected)), zeros(size(AllSelected)), zeros(size(AllSelected)));
    h = imagesc(redOutline);
    set(h, 'AlphaData', imdilate(logical(sum(CutMask, 3)), strel('disk', 12)))
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
