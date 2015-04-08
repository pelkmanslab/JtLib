import jtapi.*;
import plot2svg.*;
import jtsubfunctions.*;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% jterator input

fprintf(sprintf('jt - %s:\n', mfilename));

%%% read standard input
handles_stream = input_stream;

%%% change current working directory
cd(currentDirectory)

%%% retrieve handles from .YAML files
handles = gethandles(handles_stream);

%%% read input arguments from .HDF5 files
input_args = readinputargs(handles);

%%% check whether input arguments are valid
input_args = checkinputargs(input_args);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%
%% input handling %%
%%%%%%%%%%%%%%%%%%%%

Nuclei = input_args.NucleiImage;
InputImage = input_args.CorrImage;

%%% Input arguments for object smoothing by median filtering
doSmooth = input_args.doSmooth;
SmoothingFilterSize = input_args.SmoothingFilterSize;

%%% Input arguments for identifying objects by iterative intensity thresholding
ThresholdCorrection = input_args.ThresholdCorrection;
MinimumThreshold = input_args.MinimumThreshold;
pObject = input_args.pObject;

%%% Input arguments for plotting segmentation results
doPlot = input_args.doPlot;

%%% Input arguments for saving segmented images
doSaveSegmentedImage = input_args.doSaveSegmentedImage;
OrigImageFilename = input_args.OrigImageFilename;
SegmentationPath = input_args.SegmentationPath;


%%%%%%%%%%%%%%%%
%% processing %%
%%%%%%%%%%%%%%%%

%%% Stick to CellProfiler rescaling
MinimumThreshold = MinimumThreshold / 2^16;
MaximumThreshold = 1;
InputImage = InputImage ./ 2^16;

%%% Smooth image
if doSmooth
    SmoothedImage = SmoothImage(InputImage, SmoothingFilterSize);
else
    SmoothedImage = InputImage;
end

ThresholdMethod = 'Otsu Global';

numThresholdsToTest = length(ThresholdCorrection);
ThresholdArray = cell(numThresholdsToTest,1);

%%% Obtain first threshold
% [TS] force to use minimal threshold value of 0 and maximum of 1, to ensure
% equal thresholding for all tested thresholds
ThresholdArray{1} = ImageThreshold(ThresholdMethod, ...
                                   pObject, 0, 1, ...
                                   ThresholdCorrection(1), ...
                                   SmoothedImage, ...
                                   []);

%%%% [TS] start modification for obtaining multiple thresholds %%%%%%%%%%%%%%%%%
if numThresholdsToTest>1
   for k=2:numThresholdsToTest
       %%% STEP 1a: Marks at least some of the background
       refThreshold = ThresholdArray{1};
       ThresholdArray{k} = refThreshold .* ThresholdCorrection(k) ./ThresholdCorrection(1);
   end
end

% now fix thresholds outside of range. Could be made nicer by directly
% calling a function for fixing thresholds for CP standard case (k=1) and
% [TS] modification for k>=2
for k=1:numThresholdsToTest
   % note that CP addresses the threshold in such a way that it could be
   % either a number or a matrix.-> the internally generated threshold
   % might be either of it. The following lines should support both.
   reconstituteThresholdImage = ThresholdArray{k};
   bnSomethingOutsidRange = false;

   f = reconstituteThresholdImage(:) < MinimumThreshold;
   if any(f)
       reconstituteThresholdImage(f) = MinimumThreshold;
       bnSomethingOutsidRange = true;
   end

   f = reconstituteThresholdImage(:) > MaximumThreshold;
   if any(f)
       reconstituteThresholdImage(f) = MaximumThreshold;
       bnSomethingOutsidRange = true;
   end

   if bnSomethingOutsidRange == true
       ThresholdArray{k} = reconstituteThresholdImage;
   end
end

%%%% [TS] end modification for obtaining multiple thresholds %%%%%%%%%%%%%%%%%


%%%% [TS] Start modification> DISMISS only border %%%%%%%%%%%%%%%%%%%%%%
%%% Preliminary objects, which were not identified as object proper, still
%%% serve as seeds for allocating pixels to secondary object. While this
%%% makes sense for nuclei, which were discared in the primary module due to
%%% their location at the image border (and have a surrounding cytoplasm),
%%% it can lead to wrong segmenations, if a false positive nucleus, that was
%%% filtered away , eg. by the DiscardSinglePixel... module , was present

%%% corrsponds to one line from STEP 10, moved up. Allows proper
%%% initialzing for reconstitution
%%% Converts the EditedPrimaryBinaryImage to binary.
EditedPrimaryBinaryImage = im2bw(Nuclei,.5);

% Replace the way the mask PrelimPrimaryBinaryImage is generated
%%% Use a shared line from STEP 0. This will allow proper initializing for reconstitution.
%%% Converts the Nuclei to binary.
%%% OLD> PrelimPrimaryBinaryImage = im2bw(Nuclei,.5);

%%% Get IDs of objects at image border
R= Nuclei([1 end],:);
C= Nuclei(:,[1 end]);
BoderObjIDs = unique([R C']);
while any(BoderObjIDs==0)
   BoderObjIDs = BoderObjIDs(2:end);
end
clear R; clear C;

PrelimPrimaryBinaryImage = false(size(EditedPrimaryBinaryImage));

f = ismember(Nuclei,BoderObjIDs) | ... % objects at border
    EditedPrimaryBinaryImage;            % proper objects

PrelimPrimaryBinaryImage(f) = true;


%%%% [TS] End modification> DISMISS only border %%%%%%%%%%%%%%%%%%%%%




%%%% [TS] %%%%%%%%%%%%% Start of SHARED code for precalculations %%%%%%%%%%%
% note that fragments of original function were replaced by TS to prevent
% redundant calculations


%%% Creates the structuring element that will be used for dilation.
StructuringElement = strel('square',3);
%%% Dilates the Primary Binary Image by one pixel (8 neighborhood).
DilatedPrimaryBinaryImage = imdilate(PrelimPrimaryBinaryImage, StructuringElement);
%%% Subtracts the PrelimPrimaryBinaryImage from the DilatedPrimaryBinaryImage,
%%% which leaves the PrimaryObjectOutlines.
PrimaryObjectOutlines = DilatedPrimaryBinaryImage - PrelimPrimaryBinaryImage;


%%% Calculate the sobel image, which reflects gradients, which will
%%% be used for the watershedding function.
%%% Calculates the 2 sobel filters.  The sobel filter is directional, so it
%%% is used in both the horizontal & vertical directions and then the
%%% results are combined.
filter1 = fspecial('sobel');
filter2 = filter1';
%%% Applies each of the sobel filters to the original image.
I1 = imfilter(SmoothedImage, filter1);
I2 = imfilter(SmoothedImage, filter2);
%%% Adds the two images.
%%% The sobel operator results in negative values, so the absolute values
%%% are calculated to prevent errors in future steps.
AbsSobeledImage = abs(I1) + abs(I2);
clear I1; clear I2;              

%%%% [TS] %%%%%%%%%%%%% End of SHARED code for precalculations %%%%%%%%%%%



%%%%%% [TS] %%%%%%%%%%%%%%%  ITERATION CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize output
cellFinalLabelMatrixImage = cell(numThresholdsToTest,1);


for k=1:numThresholdsToTest

   % STEP 0
   %%% Thresholds the original image.
   ThresholdedOrigImage = SmoothedImage > ThresholdArray{k};

   %%% STEP 1: Marks at least some of the background

   %%% Inverts the image.
   InvertedThresholdedOrigImage = imcomplement(ThresholdedOrigImage);
   clear ThresholdedOrigImage;      

   %%% STEP 2: Produce the marker image which will be used for the first
   %%% watershed.
  
   %%% Combines the foreground markers and the background markers.
   BinaryMarkerImagePre = PrelimPrimaryBinaryImage | InvertedThresholdedOrigImage;
   %%% Overlays the PrimaryObjectOutlines to maintain distinctions between each
   %%% primary object and the background.
   BinaryMarkerImage = BinaryMarkerImagePre;
   clear BinaryMarkerImagePre;      
   BinaryMarkerImage(PrimaryObjectOutlines == 1) = 0;


   %%% STEP 3: Perform the first watershed.
  
   %%% Overlays the foreground and background markers
   Overlaid = imimposemin(AbsSobeledImage, BinaryMarkerImage);
   clear BinaryMarkerImage;  %%% [NB] hack. save memory.

   %%% Perform the watershed on the marked absolute-value Sobel Image.
   BlackWatershedLinesPre = watershed(Overlaid);
   clear Overlaid;          

   %%% Bug workaround (see step 9).
   %%% [NB, WATERSHED BUG IN VERSION 2011A (Windows only) OR HIGHER HAS BEEN FIXED. SO CHECK VERSION FIRST]
   if verLessThan('matlab', '7.12.0') && ispc()
       BlackWatershedLinesPre2 = im2bw(BlackWatershedLinesPre,.5);
       BlackWatershedLines = bwlabel(BlackWatershedLinesPre2);

       clear BlackWatershedLinesPre2 BlackWatershedLinesPre;
   else
       %%% [BS, QUICK AND DIRTY HACK FROM PEKLMANS]
       BlackWatershedLines = double(BlackWatershedLinesPre);

       clear BlackWatershedLinesPre;
       %%% END OF BS-HACK BUGFIX FOR VERSION 2011 AND LATER?
   end

   %%% STEP 4: Identify and extract the secondary objects, using the watershed
   %%% lines.
  
   %%% The BlackWatershedLines image is a label matrix where the watershed
   %%% lines = 0 and each distinct object is assigned a number starting at 1.
   %%% This image is converted to a binary image where all the objects = 1.
   SecondaryObjects1 = im2bw(BlackWatershedLines,.5);
   clear BlackWatershedLines;
   %%% Identifies objects in the binary image using bwlabel.
   %%% Note: Matlab suggests that in some circumstances bwlabeln is faster
   %%% than bwlabel, even for 2D images.  I found that in this case it is
   %%% about 10 times slower.
   LabelMatrixImage1 = bwlabel(SecondaryObjects1,4);
   clear SecondaryObjects1;
  

   %%% STEP 5: Discarding background "objects".  The first watershed function
   %%% simply divides up the image into regions.  Most of these regions
   %%% correspond to actual objects, but there are big blocks of background
   %%% that are recognized as objects. These can be distinguished from actual
   %%% objects because they do not overlap a primary object.

   %%% The following changes all the labels in LabelMatrixImage1 to match the
   %%% centers they enclose (from PrelimPrimaryBinaryImage), and marks as background
   %%% any labeled regions that don't overlap a center. This function assumes
   %%% that every center is entirely contained in one labeled area.  The
   %%% results if otherwise may not be well-defined. The non-background labels
   %%% will be renumbered according to the center they enclose.

   %%% Finds the locations and labels for different regions.
   area_locations = find(LabelMatrixImage1);
   area_labels = LabelMatrixImage1(area_locations);
   %%% Creates a sparse matrix with column as label and row as location,
   %%% with the value of the center at (I,J) if location I has label J.
   %%% Taking the maximum of this matrix gives the largest valued center
   %%% overlapping a particular label.  Tacking on a zero and pushing
   %%% labels through the resulting map removes any background regions.
   map = [0 full(max(sparse(area_locations, area_labels, PrelimPrimaryBinaryImage(area_locations))))];

   ActualObjectsBinaryImage = map(LabelMatrixImage1 + 1);
   clear area_labels area_locations map;       


   %%% STEP 6: Produce the marker image which will be used for the second
   %%% watershed.
  
   %%% The module has now produced a binary image of actual secondary
   %%% objects.  The gradient (Sobel) image was used for watershedding, which
   %%% produces very nice divisions between objects that are clumped, but it
   %%% is too stringent at the edges of objects that are isolated, and at the
   %%% edges of clumps of objects. Therefore, the stringently identified
   %%% secondary objects are used as markers for a second round of
   %%% watershedding, this time based on the original (intensity) image rather
   %%% than the gradient image.

   %%% Creates the structuring element that will be used for dilation.
   StructuringElement = strel('square',3);
   %%% Dilates the Primary Binary Image by one pixel (8 neighborhood).
   DilatedActualObjectsBinaryImage = imdilate(ActualObjectsBinaryImage, StructuringElement);
   %%% Subtracts the PrelimPrimaryBinaryImage from the DilatedPrimaryBinaryImage,
   %%% which leaves the PrimaryObjectOutlines.
   ActualObjectOutlines = DilatedActualObjectsBinaryImage - ActualObjectsBinaryImage;
   clear DilatedActualObjectsBinaryImage;
   %%% Produces the marker image which will be used for the watershed. The
   %%% foreground markers are taken from the ActualObjectsBinaryImage; the
   %%% background markers are taken from the same image as used in the first
   %%% round of watershedding: InvertedThresholdedOrigImage.
   BinaryMarkerImagePre2 = ActualObjectsBinaryImage | InvertedThresholdedOrigImage;
   clear InvertedThresholdedOrigImage ActualObjectsBinaryImage;
   %%% Overlays the ActualObjectOutlines to maintain distinctions between each
   %%% secondary object and the background.
   BinaryMarkerImage2 = BinaryMarkerImagePre2;
   clear BinaryMarkerImagePre2;

   BinaryMarkerImage2(ActualObjectOutlines == 1) = 0;

   %%% STEP 7: Perform the second watershed.
   %%% As described above, the second watershed is performed on the original
   %%% intensity image rather than on a gradient (Sobel) image.
  
   %%% Inverts the original image.
   InvertedOrigImage = imcomplement(SmoothedImage);
   %%% Overlays the foreground and background markers onto the
   %%% InvertedOrigImage, so there are black secondary object markers on top
   %%% of each dark secondary object, with black background.
   MarkedInvertedOrigImage = imimposemin(InvertedOrigImage, BinaryMarkerImage2);
   clear BinaryMarkerImage2 BinaryMarkerImage2;

   %%% Performs the watershed on the MarkedInvertedOrigImage.
   SecondWatershedPre = watershed(MarkedInvertedOrigImage);
   clear MarkedInvertedOrigImage;
   %%% BUG WORKAROUND:
   %%% There is a bug in the watershed function of Matlab that often results in
   %%% the label matrix result having two objects labeled with the same label.
   %%% I am not sure whether it is a bug in how the watershed image is
   %%% produced (it seems so: the resulting objects often are nowhere near the
   %%% regional minima) or whether it is simply a problem in the final label
   %%% matrix calculation. Matlab has been informed of this issue and has
   %%% confirmed that it is a bug (February 2004). I think that it is a
   %%% reasonable fix to convert the result of the watershed to binary and
   %%% remake the label matrix so that each label is used only once. In later
   %%% steps, inappropriate regions are weeded out anyway.

   %%% [NB, WATERSHED BUG IN VERSION 2011A (Windows only) OR HIGHER HAS BEEN FIXED. SO CHECK VERSION FIRST]
   if verLessThan('matlab', '7.12.0') && ispc()
       SecondWatershedPre2 = im2bw(SecondWatershedPre,.5);
       SecondWatershed = bwlabel(SecondWatershedPre2);
       clear SecondWatershedPre2;
   else
       %%% [BS, QUICK AND DIRTY HACK FROM PEKLMANS]
       SecondWatershed = double(SecondWatershedPre);
       %%% END OF BS-HACK BUGFIX FOR VERSION 2011 AND LATER?
   end
   clear SecondWatershedPre;
  

   %%% STEP 8: As in step 7, remove objects that are actually background
   %%% objects.  See step 7 for description. This time, the edited primary object image is
   %%% used rather than the preliminary one, so that objects whose nuclei are
   %%% on the edge of the image and who are larger or smaller than the
   %%% specified size are discarded.

   %%% Finds the locations and labels for different regions.
   area_locations2 = find(SecondWatershed);
   area_labels2 = SecondWatershed(area_locations2);
   %%% Creates a sparse matrix with column as label and row as location,
   %%% with the value of the center at (I,J) if location I has label J.
   %%% Taking the maximum of this matrix gives the largest valued center
   %%% overlapping a particular label.  Tacking on a zero and pushing
   %%% labels through the resulting map removes any background regions.
   map2 = [0 full(max(sparse(area_locations2, area_labels2, EditedPrimaryBinaryImage(area_locations2))))];
   FinalBinaryImagePre = map2(SecondWatershed + 1);
   clear SecondWatershed area_labels2 map2;

   %%% Fills holes in the FinalBinaryPre image.
   FinalBinaryImage = imfill(FinalBinaryImagePre, 'holes');
   clear FinalBinaryImagePre;
   %%% Converts the image to label matrix format. Even if the above step
   %%% is excluded (filling holes), it is still necessary to do this in order
   %%% to "compact" the label matrix: this way, each number corresponds to an
   %%% object, with no numbers skipped.
   ActualObjectsLabelMatrixImage3 = bwlabel(FinalBinaryImage);
   clear FinalBinaryImage;
   %%% The final objects are relabeled so that their numbers
   %%% correspond to the numbers used for nuclei.
   %%% For each object, one label and one label location is acquired and
   %%% stored.
   [LabelsUsed,LabelLocations] = unique(Nuclei);
   %%% The +1 increment accounts for the fact that there are zeros in the
   %%% image, while the LabelsUsed starts at 1.
   LabelsUsed(ActualObjectsLabelMatrixImage3(LabelLocations(2:end))+1) = Nuclei(LabelLocations(2:end));
   FinalLabelMatrixImagePre = LabelsUsed(ActualObjectsLabelMatrixImage3+1);
   clear FinalBinaryImage LabelsUsed LabelLocations;
   %%% The following is a workaround for what seems to be a bug in the
   %%% watershed function: very very rarely two nuclei end up sharing one
   %%% "cell" object, so that one of the nuclei ends up without a
   %%% corresponding cell.  I am trying to determine why this happens exactly.
   %%% When the cell is measured, the area (and other
   %%% measurements) are recorded as [], which causes problems when dependent
   %%% measurements (e.g. perimeter/area) are attempted.  It results in divide
   %%% by zero errors and the mean area = NaN and so on.  So, the Primary
   %%% label matrix image (where it is nonzero) is written onto the Final cell
   %%% label matrix image pre so that every primary object has at least some
   %%% pixels of secondary object.
   IdentifiedCells = FinalLabelMatrixImagePre;
   clear FinalLabelMatrixImagePre;
   IdentifiedCells(Nuclei ~= 0) = Nuclei(Nuclei ~= 0);

   %[TS] insert to allow easy collecition of segmentations at all
   %different thresholds
   if max(IdentifiedCells(:))<intmax('uint16')
       cellFinalLabelMatrixImage{k} = uint16(IdentifiedCells); % if used for cells, few objects, reduce memory load
   else
       cellFinalLabelMatrixImage{k} = IdentifiedCells;
   end

   clear IdentifiedCells; % memory==low

end
%%%% [TS] %%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of iteration %%%%%%%%%%%

clear AbsSobeledImage;
clear PrelimPrimaryBinaryImage;



%%%% [TS] %%%%%%%%%% ABSOLUTE SEGEMENTATION  Start  %%%%%%%%%%%

% this code combines knowledge of about the segementation at individual
% thresholds to one common segmentation, which will be superior and
% combines the advantage of high threshold (less/no false allocation to
% wrong cell) with the advantage of low thresholds (inclusion of cell
% boundaries)


% A) Reverse projection
IdentifiedCells  = zeros(size(cellFinalLabelMatrixImage{1}),'double');
for k=numThresholdsToTest:-1:1
   f = cellFinalLabelMatrixImage{k} ~=0;
   IdentifiedCells(f) = cellFinalLabelMatrixImage{k}(f);
end


% B) Make sure objects are separated

% Dilate segmentation by one pixel and reassign IDs. This is necessary
% because edge detection is done in next step to create 0 intensity pixels
% between IDa-IDb. However, without dilation to background, background-IDa
% boundaries would become extended in next step

% use code from spot quality control showSpotsInControl.m
DistanceToDilate = 1;
%%% Creates the structuring element using the user-specified size.
StructuringElementMini = strel('disk', DistanceToDilate);
%%% Dilates the preliminary label matrix image (edited for small only).
DilatedPrelimSecObjectLabelMatrixImageMini = imdilate(IdentifiedCells, StructuringElementMini);
%%% Converts to binary.
DilatedPrelimSecObjectBinaryImageMini = im2bw(DilatedPrelimSecObjectLabelMatrixImageMini,.5);
%%% Computes nearest neighbor image of nuclei centers so that the dividing
%%% line between secondary objects is halfway between them rather than
%%% favoring the primary object with the greater label number.
[~, Labels] = bwdist(full(IdentifiedCells>0)); % We want to ignore MLint error checking for this line.
%%% Remaps labels in Labels to labels in IdentifiedCells.
if max(Labels(:)) == 0,
   Labels = ones(size(Labels));
end
ExpandedRelabeledDilatedPrelimSecObjectImageMini = IdentifiedCells(Labels);
RelabeledDilatedPrelimSecObjectImageMini = zeros(size(ExpandedRelabeledDilatedPrelimSecObjectImageMini));
RelabeledDilatedPrelimSecObjectImageMini(DilatedPrelimSecObjectBinaryImageMini) = ExpandedRelabeledDilatedPrelimSecObjectImageMini(DilatedPrelimSecObjectBinaryImageMini);
% Stop using code from showSpotsInControl.m
clear ExpandedRelabeledDilatedPrelimSecObjectImageMini;
% Create Boundaries

I1 = imfilter(RelabeledDilatedPrelimSecObjectImageMini, filter1); % [TS] reuse sobel filters from above
I2 = imfilter(RelabeledDilatedPrelimSecObjectImageMini, filter2);
AbsSobeledImage = abs(I1) + abs(I2);
clear I1; clear I2;              
edgeImage = AbsSobeledImage>0;    % detect edges
IdentifiedCells = RelabeledDilatedPrelimSecObjectImageMini .* ~edgeImage;   % set edges in Labelmatrix to zero
clear Labels; clear ExpandedRelabeledDilatedPrelimSecObjectImageMini;
clear edgeImage;

if max(IdentifiedCells(:)) ~= 0       % check if an object is present Empty Image Handling

   % C) Remove regions no longer connected to the primary object
   % Take code from Neighbor module
   distanceToObjectMax = 3;
   loadedImage = IdentifiedCells;
   props = regionprops(loadedImage,'BoundingBox');
   BoxPerObj = cat(1,props.BoundingBox);

   N = floor(BoxPerObj(:,2)-distanceToObjectMax-1);                    f = N < 1;                      N(f) = 1;
   S = ceil(BoxPerObj(:,2)+BoxPerObj(:,4)+distanceToObjectMax+1);      f = S > size(loadedImage,1);    S(f) = size(loadedImage,1);
   W = floor(BoxPerObj(:,1)-distanceToObjectMax-1);                    f = W < 1;                      W(f) = 1;
   E = ceil(BoxPerObj(:,1)+BoxPerObj(:,3)+distanceToObjectMax+1);      f = E > size(loadedImage,2);    E(f) = size(loadedImage,2);

   % create empty output
   FinalLabelMatrixImage2  = zeros(size(IdentifiedCells));
   numObjects = size(BoxPerObj,1);
   if numObjects>=1  % if objects present
       patchForPrimaryObject = false(1,numObjects);
       for k=1: numObjects  % loop through individual objects to safe computation
           miniImage = IdentifiedCells(N(k):S(k),W(k):E(k));
           bwminiImage = miniImage>0;
           labelmini = bwlabel(bwminiImage);

           miniImageNuclei = Nuclei(N(k):S(k),W(k):E(k));
           bwParentOfInterest = miniImageNuclei == k;

           % now find the most frequent value. note that preobject will not be
           % completely within child at border of image

           NewChildID = labelmini(bwParentOfInterest);

           if isequal(NewChildID,0) % [TS 150120: only compute if an object is found, see other comments marked by TS 150120 for explanation]
               patchForPrimaryObject(k) = true;
           else
               NewChildID = NewChildID(NewChildID>0);
               WithParentIX = mode(NewChildID); % [TS 150120: note that MODE gives different behavior on 0 input in new MATLAB versions]
               bwOutCellBody = labelmini == WithParentIX;

               % now map back the linear indices
               [r, c] = find(bwOutCellBody);

               % get indices for final image (note that mini image might have
               % permitted regions of other cells).
               r = r-1+N(k);
               c = c-1+W(k);
               w = sub2ind(size(FinalLabelMatrixImage2),r,c);

               % Update Working copy of Final Segmentation image based on linear indices.
               FinalLabelMatrixImage2(w) = k;
           end
       end

   end
   % Now mimik standard outupt of calculations of standard module
   IdentifiedCells = FinalLabelMatrixImage2;

else

   % To prevent to break the code in case no objects are present.
   numObjects = [];

end

% duplicate penultimate row and column. Thus pixels at border will carry
% an object ID (and are detected by iBrain function to discard border cells);
IdentifiedCells(:,1)= IdentifiedCells(:,2);
IdentifiedCells(:,end)= IdentifiedCells(:,(end-1));
IdentifiedCells(1,:)= IdentifiedCells(2,:);
IdentifiedCells(end,:)= IdentifiedCells((end-1),:);


% [TS 150120: ensure that every primary object has a secondary object:
% in case that no secondary object could be found (which is related to
% CP's behavior of using rim of primary object as seed), use the primary
% segmentation of the missing objects as the secondary object]
% Note: this fix is after extending the pixels at the border since
% sometimes small 1 -pixel objects, which are lost, are sitting at the
% border of an image (and thus would be overwritten)

if numObjects >= 1
    if any(patchForPrimaryObject)
        % [TS]: note the conservative behavior to track individual missing
        % objects; this is intended for backward compatibility, while a simple
        % query for missing IDs would be faster, it would be more general and
        % thus potentially conflict with the segementation results of prior
        % pipelines (in other regions than the objects lost by prior / default
        % behavior of segmentation modules)
        IDsOfObjectsToPatch = find(patchForPrimaryObject);
        needsToIncludePrimary = ismember(SmoothedImage,IDsOfObjectsToPatch);
        FinalLabelMatrixImage(needsToIncludePrimary) =  SmoothedImage(needsToIncludePrimary);
    end
end

%%%% [TS] %%%%%%%%%% ABSOLUTE SEGEMENTATION  End  %%%%%%%%%%%



%% Make some default measurements

%%% Calculate object counts
CellCount = max(unique(IdentifiedCells));

%%% Relate 'nuclei' to 'cells'
[Parents, Children] = RelateObjects(IdentifiedCells, Nuclei);

%%% Calculate cell centroids
tmp = regionprops(logical(IdentifiedCells),'Centroid');
CellCentroid = cat(1, tmp.Centroid);
if isempty(CellCentroid)
    CellCentroid = [0 0];   % follow CP's convention to save 0s if no object
end

%%% Calculate cell boundary
CellBorderPixel = bwboundaries(IdentifiedCells);
if ~isempty(CellBorderPixel)
  CellBorderPixel = CellBorderPixel{1}(1:end-1, :);
  P = CellBorderPixel(CellBorderPixel(:,1) == min(CellBorderPixel(:,1)), :);
  P = P(1,:);
  CellBoundary = bwtraceboundary(IdentifiedCells, P, 'SW'); % anticlockwise
  CellBoundary = fliplr(CellBoundary(1:end-1,:)); % not closed
else
  CellBoundary = [0,0];
end


%%%%%%%%%%%%%%%%%%%%%
%% display results %%
%%%%%%%%%%%%%%%%%%%%%

if doPlot

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

    %%% Save figure as pdf
    jobid = h5varget(handles.hdf5_filename, 'jobid');
    figure_filename = sprintf('figures/%s_%.5d.pdf', mfilename, jobid);
    set(fig, 'PaperPosition', [0 0 7 7], 'PaperSize', [7 7]);
    saveas(fig, figure_filename);

    %%% Save Matlab figure
    savefig(fig, strrep(figure_filename, '.pdf', '.fig'));

end

%%%%%%%%%%%%%%%%%%
%% save results %%
%%%%%%%%%%%%%%%%%%

if doSaveSegmentedImage
    SegmentationFilename = strrep(os.path.basename(OrigImageFilename), ...
                                  '.png', '_segmentedCells.png');
    SegmentationFilename = fullfile(SegmentationPath, SegmentationFilename);
    if ~isdir(SegmentationPath)
        mkdir(SegmentationPath)
    end
    imwrite(uint16(IdentifiedCells), SegmentationFilename);
    fprintf('%s: Segmented ''cells'' were saved to file: "%s"\n', ...
            mfilename, SegmentationFilename)
end

        


%%%%%%%%%%%%%%%%%%%%
%% prepare output %%
%%%%%%%%%%%%%%%%%%%%

%%% Structure output arguments for later storage in the .HDF5 file
data = struct();
data.Cells_Children = Children;
data.Cells_Count = CellCount;
data.Cells_Centroids = CellCentroid;
data.Cells_Boundary = CellBoundary;

output_args = struct();
output_args.Cells = IdentifiedCells;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% jterator output

%%% write measurement data to HDF5
writedata(handles, data);

%%% write temporary pipeline data to HDF5
writeoutputargs(handles, output_args);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
