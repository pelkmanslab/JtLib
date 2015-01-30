function SmoothedImage = SmoothImage(OrigImage, SmoothingFilterSize)

    sigma = SmoothingFilterSize/2.35;  % Convert between Full Width at Half Maximum (FWHM) to sigma
    FiltLength = min(30,max(1,ceil(2*sigma)));  % Determine filter size, min 3 pixel, max 61
    [x,y] = meshgrid(-FiltLength:FiltLength,-FiltLength:FiltLength);  % Filter kernel grid
    f = exp(-(x.^2+y.^2)/(2*sigma^2));f = f/sum(f(:));  % Gaussian filter kernel
    %%% The original image is blurred. Prior to this blurring, the
    %%% image is padded with values at the edges so that the values
    %%% around the edge of the image are not artificially low.  After
    %%% blurring, these extra padded rows and columns are removed.
    SmoothedImage = conv2(padarray(OrigImage, [FiltLength,FiltLength], 'replicate'),f,'same');
    SmoothedImage = SmoothedImage(FiltLength+1:end-FiltLength,FiltLength+1:end-FiltLength);

end
