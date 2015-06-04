function [BorderIds, BorderIx] = GetBorderObjects(LabelImage)
% [BorderIds, BorderIx] = GetBorderObjects(LabelImage)
%
% Get unique IDs and indexes of objects at the border of an image.
%
% Input:
%   LabelImage      A labeled image as produced by bwlabel() for example.
%
% Output:
%   BorderIds       Array with unique IDs of the border objects.
%   BorderIx        Logical array with unique indexes of the border objects.
%
% Author:
%   Markus Herrmann
    
    % get unique ids of pixels along all four dimensions of the image
    BorderIds = unique(cat(1, unique(LabelImage(:, 1)), ...
                              unique(LabelImage(:, end)), ...
                              unique(LabelImage(1, :))', ...
                              unique(LabelImage(end, :))'));

    % remove 0 background
    BorderIds = BorderIds(BorderIds > 0);

    BorderIx = zeros((length(unique(LabelImage))-1), 1); % without 0 background
    BorderIx(BorderIds) = 1;


end
