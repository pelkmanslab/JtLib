function BorderIds = GetBorderObjects(LabelImage)
% BorderIds = GetBorderObjects(LabelImage)
%
% Get the unique IDs of objects at the border of an image.
%
% Input:
%   LabelImage      A labeled image as produced by bwlabel().
%
% Author:
%   Markus Herrmann
    
    % get unique ids of pixels along all four dimensions of the image
    BorderIds = unique(cat(1, unique(LabelImage(:, 1)), ...
                              unique(LabelImage(:, end)), ...
                              unique(LabelImage(1, :))', ...
                              unique(LabelImage(end, :))'));

    % remove 0 background pixels
    BorderIds = BorderIds(BorderIds > 0);

end
