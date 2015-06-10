function OutputImage = RemoveSmallObjects(LabelImage, AreaThreshold)
    % OutputImage = RemoveSmallObjects(LabelImage, AreaThreshold)
    %
    % Remove objects smaller than a given area threshold from a labeled image.
    %
    % Input:
    %   LabelImage      A labeled image as produced by bwlabel() for example.
    %   AreaThreshold   An integer.
    %
    % Output:
    %   OutputImage     A labeled image.
    %
    % Author:
    %   Markus Herrmann

    props = regionprops(logical(LabelImage), 'Area');
    objArea2 = cat(1, props.Area);
    obj2remove = find(objArea2 < MinArea);
    for j = 1:length(obj2remove)
        LabelImage(LabelImage == obj2remove(j)) = 0;
    end
    OutputImage = bwlabel(logical(LabelImage));

end
