function [PrimaryLabelMatrixImage, CutMask, SelectedObjects, Objects, PerimeterProps] = PrimarySegmentation(OrigImage, ...
                                                                                                               CuttingPasses, ...
                                                                                                               smoothingDiskSize, WindowSize, PerimSegEqSegment, PerimSegEqRadius, ...
                                                                                                               SolidityThres, FormFactorThres, LowerSizeThres, UpperSizeThres, LowerSizeCutThres, ...
                                                                                                               ThresholdCorrection, MinimumThreshold, MaximumThreshold, ...
                                                                                                               DebugMode)
    import jtlib.PerimeterWatershedSegmentation;
    import jtlib.ImageThreshold;
    import jtlib.SelectObjectsForCutting;
    import jtlib.RemoveSmallObjects;


    %%% Threshold intensity image
    ThresholdMethod = 'Otsu Global';
    pObject = 10;
%     OrigImage(OrigImage > quantile(OrigImage(:), 0.999)) = quantile(OrigImage(:), 0.999);
    OrigThreshold = ImageThreshold(ThresholdMethod, ...
                                   pObject, ...
                                   MinimumThreshold, ...
                                   MaximumThreshold, ...
                                   ThresholdCorrection, ...
                                   OrigImage, ...
                                   []);

    ThreshImage = zeros(size(OrigImage), 'double');
    ThreshImage(OrigImage > OrigThreshold) = 1;

    %%% Fill holes in objects
    imInputObjects = imfill(double(ThreshImage), 'holes');


    if ~isempty(imInputObjects)
        
        %--------------------------------------------------------
        % Select clumped objects for further processing (cutting)
        %--------------------------------------------------------
        
        Objects = zeros([size(imInputObjects),CuttingPasses]);
        SelectedObjects = zeros([size(imInputObjects),CuttingPasses]);
        CutMask = zeros([size(imInputObjects),CuttingPasses]);
        ObjectsCut = zeros([size(imInputObjects),CuttingPasses]);
        ObjectsNotCut = zeros([size(imInputObjects),CuttingPasses]);
        PerimeterProps = cell(CuttingPasses,1);
        
        for i = 1:CuttingPasses
            
            if i==1
                Objects(:,:,i) = imInputObjects;
            else
                Objects(:,:,i) = ObjectsCut(:,:,i-1);
            end
            
            % Features used for object selection
            [SelectedObjects(:,:,i), imObj2Cut, ObjectsNotCut(:,:,i)] = SelectObjectsForCutting(Objects(:,:,i), ...
                                                                                            SolidityThres, ...
                                                                                            FormFactorThres, ...
                                                                                            UpperSizeThres, LowerSizeThres);
            
            %---------------------
            % Cut selected objects
            %---------------------
            
            % Smooth image
            SmoothDisk = getnhood(strel('disk', smoothingDiskSize, 0));%minimum that has to be done to avoid problems with bwtraceboundary
            imObj2Cut = bwlabel(imdilate(imerode(imObj2Cut, SmoothDisk), SmoothDisk));
            
            % In rare cases the above smoothing approach creates new, small
            % objects that cause problems. Let's remove them.
            imObj2Cut = RemoveSmallObjects(imObj2Cut, LowerSizeThres);
            
            % Separate clumped objects along watershed lines
            
            % Note: PerimeterAnalysis cannot handle holes in objects (we may
            % want to implement this in case of big clumps of many objects).
            % Sliding window size is linked to object size. Small object sizes
            % (e.g. in case of images acquired with low magnification) limits
            % maximal size of the sliding window and thus sensitivity of the
            % perimeter analysis.
            
            % Perform perimeter analysis
            PerimeterProps{i} = PerimeterAnalysis(imObj2Cut,WindowSize);
            
            % This parameter limits the number of allowed concave regions.
            % It can serve as a safety measure to prevent runtime problems for
            % very complex objects.
            % This could become an input argument in the future!?
            numRegionTheshold = 30;
            
            % Perform the actual segmentation
            if strcmp(DebugMode, 'On')
                CutMask(:,:,i) = PerimeterWatershedSegmentation(imObj2Cut,OrigImage,PerimeterProps{i},PerimSegEqRadius,PerimSegEqSegment,LowerSizeCutThres, numRegionTheshold, 'debugON');
            else
                CutMask(:,:,i) = PerimeterWatershedSegmentation(imObj2Cut,OrigImage,PerimeterProps{i},PerimSegEqRadius,PerimSegEqSegment,LowerSizeCutThres, numRegionTheshold);
            end
            ObjectsCut(:,:,i) = bwlabel(imObj2Cut.*~CutMask(:,:,i));

        end
        
        %-----------------------------------------------
        % Combine objects from different cutting passes
        %-----------------------------------------------
        
        AllCut = logical(ObjectsCut(:,:,CuttingPasses) + sum(ObjectsNotCut(:,:,2:end), 3));
    
        % Retrieve objects that were not cut (or already cut)
        AllNotCut = logical(sum(ObjectsNotCut, 3));
        PrimaryLabelMatrixImage = bwlabel(logical(ObjectsCut(:,:,end) + AllNotCut));
        
    else
        
        PerimeterProps = {};
        PrimaryLabelMatrixImage = zeros(size(imInputObjects));
        Objects = zeros([size(imInputObjects),CuttingPasses]);
        SelectedObjects = zeros([size(imInputObjects),CuttingPasses]);
        CutMask = zeros([size(imInputObjects),CuttingPasses]);
        ObjectsCut = zeros([size(imInputObjects),CuttingPasses]);
        ObjectsNotCut = zeros([size(imInputObjects),CuttingPasses]);
        PerimeterProps = cell(CuttingPasses,1);
        
    end

end
