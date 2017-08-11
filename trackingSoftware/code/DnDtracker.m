% ----------------------------------------------------------------------- %
% Script for tracking larvae in 6 DnD chambers with annotation of behavioral modes
% Linked function -------------------------------------------------------
% tracking.m : tracking algorithm of horizontal and vertical positions of larval centroid
% -----------------------------------------------------------------------
% input files : sequences of images
% -----------------------------------------------------------------------
% output files ----------------------------------------------------------
% trackingData.mat : contains horizontal and vertical positions of larval centroid(COM) in mm with respect to the left edge of the chamber and the agarose level
% backgroud.jpg : averaged background image
% calibration.jpg : one sequence of images overlaid with lines used in the calibration process
% traj.jpg : one sequence of image overlaid with trajectories of larvae
% depthOverTime.jpg : displaying time series of local vertical position of larvae
% ----------------------------------------------------------------------- %
% Code written by Daeyeon Kim, Louis lab
% Code published as part of the following publication:
% Kim, D., Alvarez, M., Lechuga, L., and Louis, M. (2017). 
% Species-specific modulation of food-search behavior by respiration and chemosensation in Drosophila larvae.
% eLife: 10.7554/eLife.27057  
% Please direct comments and questions to: mlouis_at_lifesci.ucsb.edu 
% ----------------------------------------------------------------------- %

%% clean all
clear
close all

%% setting tracking folders and files

display('Select the data folder to track larvae.')
inputFolder = uigat(inputFolder,'/');
display('Select the folder to save the tracked images and data.')
outputFolder = uigetdir(inputFolder, 'Select the folder to save the tracked images and data.');
outputFolder = strcat(outputFolder,'/');

mkdir(outputFolder) % making output directory

% assigning array of files
filesArray = dir(strcat(inputFolder,'*.jpg'));

%% setting parameters

fps = 1;  % frames per second
tAnal = 15;   % total time for tracking larave in min
nLarvae = 6; % number of larvae to be tracked
larvalMinSize = 0.2; % threshold value for detecting minimum size larva in mm^2
larvalMaxSize = 5;  % threshold value for detecting maximum size larva in mm^2
maxFile = 60*fps*tAnal;  % total frames to be analyzed 

if length(filesArray) > maxFile
    maxFile = maxFile;
else
    maxFile = length(filesArray);
end

%% tracking start
% obtaining the background by averaging all images-------------------------

fileName = filesArray(1).name;
iFirst = imread(strcat(inputFolder,fileName));
ibg = double(iFirst(:,:,1));    % background image

% average all images
for file = 2:maxFile
    file/maxFile*100    % display % of the process done
    fileName = filesArray(file).name;
    iTemp = imread(strcat(inputFolder,fileName));   % temporary image
    iTemp = double(iTemp(:,:,1));
    ibg = ibg + iTemp(:,:,1);
end

ibg = floor(ibg/maxFile);
ibg = uint8(ibg);

% maksing the area interfering with detection of larva
figure('units','normalized','position',[0 0 1 1]), imshow(ibg);
title('Draw the area to get intensity for masking.');
h = imrect;
roi0 = getPosition(h);  % [xmin ymin width height]
title('Draw one area in each chamber for defining masking area.');
% draw darker area than the background in the chamber

% masking the selected areas with average intensities of them
for i = 1:nLarvae
    h = imrect;
    roi = round(getPosition(h));   
    ibg(roi(2):roi(2)+roi(4),roi(1):roi(1)+roi(3))= round(mean(mean(ibg(roi0(2):roi0(2)+roi0(4),roi0(1):roi0(1)+roi0(3)))));
end

close all

% save the background image
figure('units','normalized','position',[0 0 1 1]), imshow(ibg)
axis equal
print('-f1','-djpeg',strcat(outputFolder,'background.jpeg'));
pause(0.5)
close all
% -------------------------------------------------------------------------

% defining tracking areas and calibration ---------------------------------
% define both edges of the chamber
figure('units','normalized','position',[0 0 1 1]), imshow(iFirst)
hold on
title('CALIBRATION: Mark each side of one of chambers by clicking.')
set(gca,'xtick',[],'ytick',[])

[x,y] = ginput(1);
xSideLeft = x;
line([xSideLeft xSideLeft],[0 200])   % display the left edge of the chamber

[x,y] = ginput(1);
xSideRight = x;
line([xSideRight xSideRight],[0 200])   % display the right edge of the chamber
wd = abs(xSideRight-xSideLeft); % width of chamber in pixel
scale = 5/wd;   % 5 mm width of chamber   
iwd = size(ibg,2);  % width of the image in pixel

pause(0.5)
close all

% define the top and bottom of the chamber
figure('units','normalized','position',[0 0 1 1]), imshow(iFirst)
hold on
title('Mark the top of the chamber by clicking.')
set(gca,'xtick',[],'ytick',[])
[x,y] = ginput(1);
yTop = y;
line([0 iwd],[yTop yTop])   % display the top line of the chamber

title('Mark the bottom of the chamber by clicking.')
set(gca,'xtick',[],'ytick',[])
[x,y] = ginput(1);
yBottom = y;
iht = size(ibg,1);  % height of the image in pixel
ht = iht-yBottom; % height of the chamber in pixel 
line([0 iwd],[iht-ht iht-ht]) % display the bottom line of the chamber

% define the left edges of all chambers
edgeL = []; % x-poisition of left edges of chambers
for i = 1:nLarvae
title(sprintf('Mark the left edge of chamber #%i by clicking.',i))
set(gca,'xtick',[],'ytick',[])
[x,y] = ginput(1);
edgeL(i) = x;
line([x x],[0 iht]) % display the line
end

edgeR = edgeL + wd; % x-poisition of right edges of chambers
% calculate tracking area in each chamber
cham = cat(2,edgeL',yTop*ones(1,nLarvae)',wd*ones(1,nLarvae)',(iht-yTop-ht)*ones(1,nLarvae)');

% -------------------------------------------------------------------
% define the agarose levels
agarLevel = []; % y-position of agarose gel
for i = 1:nLarvae
title(sprintf('Mark the level of agarose #%i by clicking.',i))
set(gca,'xtick',[],'ytick',[])
[x,y] = ginput(1);
agarLevel(i) = y;
line([edgeL(i) edgeR(i)],[y y],'color','red') % display the line
end

% -------------------------------------------------------------------
% display all the lines to check
close all
figure,imshow(iFirst)
hold on
for i = 1:nLarvae
line([edgeL(i) edgeR(i)],[agarLevel(i) agarLevel(i)],'color','red') % agar line
line([0 iwd],[yTop yTop]) % top line
line([0 iwd],[iht-ht iht-ht]) % bottom line
line([edgeL(i) edgeL(i)],[0 iht]) % left edge line
line([edgeR(i) edgeR(i)],[0 iht]) % right edge line
end

% save the image
print('-f1','-djpeg',strcat(outputFolder,'calibration.jpeg'));

% -------------------------------------------------------------------
% image processing to get larval centroids --------------------------
tic
% set variables
centroids = []; % col: time, odd rows/even rows: x/z-position of larval centroids in pixel

% calculate min and max larval size to detect the right object in pixel^2
larvalMinSize = round(larvalMinSize/scale^2);
larvalMaxSize = round(larvalMaxSize/scale^2);
% get centroids
for i = 1:nLarvae
COM = tracking(inputFolder,filesArray,maxFile,larvalMinSize,larvalMaxSize,i,cham(i,:),ibg);
COMLocal = scale*[COM(1,:)-edgeL(i) ; agarLevel(i)-COM(2,:)];
centroids = cat(1,centroids,COM);
trackingData{i}.horizontalCOM = COMLocal(1,:);
trackingData{i}.verticalCOM = COMLocal(2,:);
sprintf('The tracking is %0.2f percent completed.',(i/nLarvae)*100)
end

% save tracking data
save (strcat(outputFolder,'trackingData.mat'),'trackingData')
toc

display('The tracking is completed.')
close all
% ------------------------------------------------------------------------

%% plot tracking data 
cc = hsv(6);    % generate a color map
figure(1);
imshow(iFirst)
hold on
for i = 1:nLarvae
plot(centroids(2*i-1,:),centroids(2*i,:),'-','Color',cc(i,:),'LineWidth',0.2)
plot(centroids(2*i-1,:),centroids(2*i,:),'.','Color',cc(i,:),'LineWidth',0.2)
end
print('-f1','-djpeg',strcat(outputFolder,'traj.jpeg'));

% plot depth of larvae over time
times = (1:maxFile)*(1/fps); % in sec
timesMin = times/60; % in min

figure(2);
for i = 1:nLarvae
subplot(2,3,i)
depthLarva = trackingData{i}.verticalCOM;
plot(timesMin,depthLarva,'LineWidth',0.5)
xlabel('Time (min)')
ylabel('Depth (mm)')
xlim([0 15])
ylim([-12 2])
end
print('-f2','-djpeg',strcat(outputFolder,'depthOverTime.jpeg'));


%%


