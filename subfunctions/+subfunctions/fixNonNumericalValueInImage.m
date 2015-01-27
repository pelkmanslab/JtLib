function matImage = fixNonNumericalValueInImage(matImage)
% replaces NaN and Inf within matIMAGE by an estimate of the local
% intensities (derived from smoothing the surrounding);


% Predefined Constants
minimalBlur = 30;
maxSigmaBlur = 5;

% Find bad pixels
bwBadPixels = isinf(matImage) | isnan(matImage);

if ~any(bwBadPixels(:)) % no bad pixel
    return
elseif ~any(~bwBadPixels) % all bad pixels
    fprintf('%s: no pixel has a numerical value \n',mfilename)
    return
else % some bad pixels
    
    % Estimate size of artifacts
    CoordinatesOfBounding = cell2mat(struct2cell(regionprops(bwBadPixels,'BoundingBox')));
    MaxmialObjectDiameterOfArtifact = ceil(max([max(CoordinatesOfBounding(:,2)) max(CoordinatesOfBounding(:,4))]));
    SmoothingSize = max([minimalBlur 2*MaxmialObjectDiameterOfArtifact]);
    numRows = size(matImage,1);
    numColumns = size(matImage,2);
    SmoothingSigma = min([maxSigmaBlur round(SmoothingSize./2)]);
    
    % Expand bad pixels (in a quick way by boxing): only process these
    % regions in later steps
    ExpandedObjects = false(size(matImage));
    
    for j=1:size(CoordinatesOfBounding,1)
        N = floor(CoordinatesOfBounding(j,2) - SmoothingSize);
        S = ceil(CoordinatesOfBounding(j,2)+CoordinatesOfBounding(j,4) + SmoothingSize);
        W = floor(CoordinatesOfBounding(j,1) - SmoothingSize);
        E = ceil(CoordinatesOfBounding(j,1)+CoordinatesOfBounding(j,3) + SmoothingSize);
        
        N = max([1 N]);
        S = min([numRows S]);
        W = max([1 W]);
        E = min([numColumns E]);
        
        ExpandedObjects(N:S,W:E) = true;
    end
    
    % Smoothen image (only within boxed regions)
    CoordinatesOfBounding = cell2mat(struct2cell(regionprops(ExpandedObjects,'BoundingBox')));
    SmoothenedImage = zeros(size(matImage));
    
    for j=1:size(CoordinatesOfBounding,1)
        N = floor(CoordinatesOfBounding(j,2));
        S = ceil(CoordinatesOfBounding(j,2)+CoordinatesOfBounding(j,4));
        W = floor(CoordinatesOfBounding(j,1));
        E = ceil(CoordinatesOfBounding(j,1)+CoordinatesOfBounding(j,3));
        
        N = max([1 N]);
        S = min([numRows S]);
        W = max([1 W]);
        E = min([numColumns E]);
        
        CurrCropImage = matImage(N:S,W:E);
        CurrBwBadPixels = bwBadPixels(N:S,W:E);
        
        % 1st round: Replace by Local median
        LocalIntensities = CurrCropImage(:);
        hasNoNumericalValue = isinf(LocalIntensities) | isnan(LocalIntensities);
        LocalIntensities = LocalIntensities(~hasNoNumericalValue);
        if any(LocalIntensities)
            CurrCropImage(CurrBwBadPixels) = median(LocalIntensities);
        else
            CurrCropImage(CurrBwBadPixels) = 0;
        end
        
        % 2nd round: Smooth locally
        H = fspecial('gaussian',[SmoothingSize SmoothingSize],SmoothingSize./SmoothingSigma);
        SmoothenedImage(N:S,W:E) = imfilter(CurrCropImage,H,'symmetric');
    end
end

matImage(bwBadPixels) = SmoothenedImage(bwBadPixels);

end
