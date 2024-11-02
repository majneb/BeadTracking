function CropImages(newSize, pathInit, pathResized)
%newSize = [x,y,width,height] with (x,y) the coordinates of the top corner
%of the crop starting from (0,0).

myImages = dir(fullfile(pathInit, '*.tif'));
myImages = {myImages(:).name};
nbImages = length(myImages)

mkdir(pathResized);

% Px coordinate starting from 1 in Matlab : 
newSize(1) = newSize(1)+1;
newSize(2) = newSize(2)+1;

parfor i = 1:nbImages
    img = imread(fullfile(pathInit, myImages{i})); 
    imgCrop = imcrop(img, newSize);
    imwrite(imgCrop, fullfile(pathResized, [myImages{i}]));
end
end