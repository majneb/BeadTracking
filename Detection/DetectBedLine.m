function bedLine = DetectBedLine(image,bottomLine,waterLine,thresh)
%Detect the bed line using bottomline
%
%INPUT ARGUMENTS:
%image          : source image already filtered by gaussian filter
%bottomLine     : vector of the bottom line
%
%OUTPUT ARGUMENTS:
%bedLine: vector of the estimated bed line
%
%EDIT 04/22 B.Dedieu, fix dilema of second argument in bwareaopen function.
%prod(imSize)/5 allows to remove waterline whatever the image size, ie works for
%both cropped images (at least from 197x133) up to normal images (1024x500)

imSize=size(image);

image2=image<thresh;
image2(end,:)=1;
image3=imfill(image2,'holes');
%image4=bwareaopen(image3,(prod(imSize)/20),4);
image4=bwareaopen(image3,double(uint32(prod(imSize)/5)),4);
%image4=bwareaopen(image3,6388,4);

[gm,~]=imgradient(image4);
%[~,gy]=imgradientxy(image2);

imWS=zeros(imSize);
imWS(sub2ind(imSize,waterLine,1:imSize(2)))=1;
imWS(sub2ind(imSize,bottomLine,1:imSize(2)))=1;
imBedLine=watershed(imimposemin(gm,imWS))==0;
%imBedLine=watershed(imimposemin(imcomplement(gy),imWS))==0;
imBedLine=bwmorph(imBedLine,'thin',Inf);
[row,col]=find(imBedLine);
[~,icol,~]=unique(col,'last');
bedLine=row(icol)';

if length(bedLine)<length(waterLine)%copy last value if some missing at the end
    lastVal=bedLine(end);
    bedLine(end+1:end+(length(waterLine)-length(bedLine)))=lastVal;
end

end
