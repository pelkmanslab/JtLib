function Boundary = GetObjectBoundary(LabelImage)
    % Boundary = GetObjectBoundary(LabelImage)
    %
    % Get the border pixels of objects in a labeled image.
    %
    % Input:
    %   LabelImage      A labeled image as produced by bwlabel() for example.
    %
    % Output:
    %   Boundary        ???
    %
    % Author:
    %   Markus Herrmann

    ObjectCount = max(unique(LabelImage));

    if ObjectCount > 0
        BorderPixel = bwboundaries(LabelImage);
        BorderPixel = BorderPixel{1}(1:end-1, :);
        P = BorderPixel(BorderPixel(:,1) == min(BorderPixel(:,1)), :);
        P = P(1,:);
        Boundary = bwtraceboundary(LabelImage, P, 'SW'); % anticlockwise
        Boundary = fliplr(Boundary(1:end-1,:)); % not closed
    else
       Boundary = [0 0];  % follow CP's convention to save 0s if no object
    end

end
