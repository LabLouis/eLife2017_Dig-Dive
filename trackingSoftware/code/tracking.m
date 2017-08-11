% function for tracking centroid of larva ---------------------------------
% ----------------------------------------------------------------------- %
% Code written by Daeyeon Kim, Louis lab
% Code published as part of the following publication:
% Kim, D., Alvarez, M., Lechuga, L., and Louis, M. (2017). 
% Species-specific modulation of food-search behavior by respiration and chemosensation in Drosophila larvae.
% eLife: 10.7554/eLife.27057  
% Please direct comments and questions to: mlouis_at_lifesci.ucsb.edu 
% ----------------------------------------------------------------------- %

function comLarvae = tracking(dataFolder,filesArray,maxFile,larvalMinSize,larvalMaxSize,numLarvae,chamTemp,ibg)
 comLarvae = nan(2,maxFile); % initialization of variable
 for file = 1:maxFile
    
    fileName = filesArray(file).name;
    iTemp = imread(strcat(dataFolder,fileName));   % temporary image
    iTemp = iTemp(:,:,1);   % read only one channel of the image
    h = fspecial('gaussian',5, 0.7);  % creating a Gaussian filter
    iSub = ibg - iTemp; % background substraction    
    iFiltTemp = imfilter(iSub,h,'replicate');  % applying the filter
    iFilt = im2bw(iFiltTemp,graythresh(iFiltTemp)); % convert image to binary image by automatic thresholding 
    iCrop = imcrop(iFilt,chamTemp); % crop the image with size of each chamber
    iCrop = bwareaopen(iCrop,larvalMinSize); % eliminate the smaller objects than mininum size of larva

    L = bwlabel(iCrop,8);
    infoL = regionprops(L,'Centroid','Area'); % get the information of centroid and area for the objects
    
    if (isempty(infoL) == 1)
       % mark the centroid of larva in case of no object-detection
       figure, imshow(iTemp)
       hold on
       title(sprintf('Mark the centroid of #%i animal manually by clicking.',numLarvae))
       comTemp = ginput(1)';
       plot(comTemp(1),comTemp(2),'+r')
       pause(0.5)
       close all
    else       
    % for normal object detection, find the largest object
    areas = cat(1,infoL.Area);
    coms = cat(1,infoL.Centroid);
    idxMaxArea = find(areas == max(areas),1);
    comTemp = coms(idxMaxArea,:)';   % local x-z coordinates of the centroid
    % indicate the centroid manually if the object is too large
    if (areas(idxMaxArea)>larvalMaxSize)
       figure, imshow(iTemp)
       hold on
       title(sprintf('Mark the centroid of #%i animal manually by clicking.',numLarvae))
       comTemp = ginput(1)';
       plot(comTemp(1),comTemp(2),'+r')
       pause(0.5)
       close all
    else
       % global x-z coordinates of the position of the centroid
       comLarvae(1,file) = chamTemp(1) + comTemp(1);  
       comLarvae(2,file) = chamTemp(2) + comTemp(2);
    end
    end
end
end