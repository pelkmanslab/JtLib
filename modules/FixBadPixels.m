import jterator.*;
import subfunctions.*;

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

InputImage = input_args.InputImage;


%%%%%%%%%%%%%%%%
%% processing %%
%%%%%%%%%%%%%%%%

% Predefined Constants
minimalBlur = 30;
maxSigmaBlur = 5;

% Find bad pixels
bwBadPixels = isinf(InputImage) | isnan(InputImage);

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
    numRows = size(InputImage,1);
    numColumns = size(InputImage,2);
    SmoothingSigma = min([maxSigmaBlur round(SmoothingSize./2)]);
    
    % Expand bad pixels (in a quick way by boxing): only process these
    % regions in later steps
    ExpandedObjects = false(size(InputImage));
    
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
    SmoothenedImage = zeros(size(InputImage));
    
    for j=1:size(CoordinatesOfBounding,1)
        N = floor(CoordinatesOfBounding(j,2));
        S = ceil(CoordinatesOfBounding(j,2)+CoordinatesOfBounding(j,4));
        W = floor(CoordinatesOfBounding(j,1));
        E = ceil(CoordinatesOfBounding(j,1)+CoordinatesOfBounding(j,3));
        
        N = max([1 N]);
        S = min([numRows S]);
        W = max([1 W]);
        E = min([numColumns E]);
        
        CurrCropImage = InputImage(N:S,W:E);
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

FixedImage(bwBadPixels) = SmoothenedImage(bwBadPixels);


%%%%%%%%%%%%%%%%%%%%
%% prepare output %%
%%%%%%%%%%%%%%%%%%%%

%%% Structure output arguments for later storage in the .HDF5 file
data = struct();

output_args = struct();
output_args.OutputImage = FixedImage;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% jterator output

%%% write measurement data to HDF5
writedata(handles, data);

%%% write temporary pipeline data to HDF5
writeoutputargs(handles, output_args);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
