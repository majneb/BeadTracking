function imBackground = ExtractBackground(images)
% Time-average the movement regions in an image sequence as the first stage of a
% trajectory-learning algorithm.
% Alexander Farley
% alexander.farley at utoronto.ca
% September 16 2011 
% Written and tested in Matlab R2011a
%------------------------------------------------------------------------------
% The purpose of this script is to average an image sequence across all images
% as a first stage of a trajectory-learning algorithm.
%
% INPUT ARGUMENTS:
%  images: list of images (as 3d-array) to average.
%
% OUTPUT ARGUMENTS:
%  imBackground: average image of the image sequence.

% First-iteration background frame
%This section calculates the mean of a downsampled sequence of images
imSize=size(images(:,:,1));
nbImages=size(images,3);
imBackground1=sum(images,3)/nnz(images(1,1,:));
%figure;imshow(uint8(imBackground1));


% Second-iteration background frame
%This section re-calculates the background frame while attempting to
%minimize the effect of moving objects in the calculation
imBackground=zeros(imSize);
pixelSampleDensity=zeros(imSize);
for im=1:nbImages
    frame=double(images(:,:,im));
    diffFrame=imabsdiff(frame,imBackground1);
    diffFrame=1-im2bw(uint8(diffFrame),.25);%0 = moving
    pixelSampleDensity=pixelSampleDensity+diffFrame;%0 = moving
    nonmoving=frame.*diffFrame;
    imBackground=imBackground+nonmoving;
end
imBackground=imBackground./pixelSampleDensity;
%figure;imshow(uint8(imageBackground2))

end