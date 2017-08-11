% ----------------------------------------------------------------------- %
% Script for defining the diving threshold and classification of behavior
% input files : trackingData.mat (multiple files can be indexed with numbers, eg. trackingData1.mat, trackingData2.mat ...
               % possilbe to select multiple files.
               % After generation of the output file, trackingDataAll.mat once, do not select it as an input file, in case you want to run this script again.
% output file -------------------------------------------------------------
% trackingDataAll.mat : merged all tracking data files, if there are multiple tracking data files, with annotation of behavior (if the annotation option is selected)
% Annotation of behaviral modes:
% 1: diving
% 2: digging
% 3: surfacing
% 4: escaping
% pdf.jpg : display of probability density fuction of larval centroid with indication of the diving treshold
% annotation.jpg : display of annotation of behavior
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

%% Import data files
% get data file positions -------------------------------------------------
display('Select the data files to import (multiple files can be selected).')
[dataFile,dataDir] = uigetfile('*.mat','Select the data files to import (multiple files can be selected).','MultiSelect', 'on');

if ischar(dataFile)
   scan = 1;
else
   scan = length(dataFile);
end

% importing data files ----------------------------------------------------
% set variable
comLarvaeHorizontalAll = [];
comLarvaeVerticalAll = [];

% load and pool all the data
for i = 1:scan
   
    if (scan > 1)
        load(strcat(dataDir,dataFile{i}));
        dataFile{i}
    else
        load(strcat(dataDir,dataFile));
        dataFile
    end
    
    numLarvae = length(trackingData); % get number of larvae in each data file
    
    % pool all the tracking data
    for j = 1:numLarvae
    comLarvaeHorizontalAll = cat(1,comLarvaeHorizontalAll,trackingData{j}.horizontalCOM);
    comLarvaeVerticalAll = cat(1,comLarvaeVerticalAll,trackingData{j}.verticalCOM);
    % merge all tracking data
    trackingDataAll{6*(i-1)+j} = trackingData{j};
    end
end

%% Define threshold for diving
% set parameters
bin = 0.05; % bin size of vertical position of larval depth in mm
% calculate probability density fuction of vertical position of larval COM
depthAll = reshape(comLarvaeVerticalAll,1,[]);
depthRange = round(min(depthAll)):bin:round(max(depthAll)); % range of values
depthPDF = histc(depthAll,depthRange)/length(depthAll)/bin; % probability density function of the vertical COM
depthEstimate = ksdensity(depthAll,depthRange); % estimated PDF

% obtain the threshold by calculating the first local minimum of the estimated PDF
slope = diff(depthEstimate);
[minslope,idxminslope] = findpeaks(3.05-depthEstimate,'MINPEAKDISTANCE',1);

% visualize the PDF to select the diving threshold value
figure(1)
subplot(1,3,1)
plot(depthPDF,depthRange,'-k');
hold on
plot(depthEstimate,depthRange,'-r');
plot(depthEstimate(idxminslope),depthRange(idxminslope),'ob');
ylabel('Depth (mm)','Fontsize',12);
xlabel('Probability density','Fontsize',12);
xlim([0 1])
ylim([-12 4])
legend('Experimental PDF','Estimated PDF','local minimum','Location','NorthEast');

depthRange(idxminslope) % list locations of local minima
display('Diving theshold value is considered as location of the first minimum')
display('below the head of the estimated PDF.')
thDiveIndex = input('Enter the index of threshold for diving in the above list of values: ');
thDive = depthRange(idxminslope(thDiveIndex))  % threshold for diving / digging
thDig = 0   % threshold for digging / surfacing
thEscape = 2.5  % threshold for escaping mode, 2.5 mm above the agarose level

line([0 0.45],[thDive thDive],'color','green','linestyle',':');
line([0 0.45],[thDig thDig],'color','blue','linestyle',':');

flag = input('Do you want to classify the behavior with these thresholds? (Y/N): ', 's'); 
if (flag == 'Y' ) || (flag == 'y')
    scan = length(trackingDataAll);
    for i = 1:scan
        depth = trackingDataAll{i}.verticalCOM;
        anotMode = 4*ones(1,size(depth,2)); % anotation of each mode
        idxDive = find(depth <= thDive); % index in diving mode
        idxDig = find(depth <= thDig & depth > thDive);  % index in digging mode
        idxSurf = find(depth <= thEscape & depth > thDig ); % index in surfacing mode
        anotMode(idxDive) = 1; % anotation of diving mode as '1'
        anotMode(idxDig) = 2; % anotation of digging mode as '2'
        anotMode(idxSurf) = 3; % anotation of surfacing mode as '3' / '4' is escaping mode
        trackingDataAll{i}.annotation = anotMode; % add annotation data to the existing tracking data
    end
end

fps = 1;
times = (1:length(depth))*(1/fps); % in sec
timesMin = times/60; % in min

figure(2)
for i = 1:scan
subplot(6,4,i)
plot(timesMin,trackingDataAll{i}.annotation,'LineWidth',0.5)
xlabel('Time (min)')
ylabel('Mode')
xlim([0 15])
ylim([0 5])
end

%% save data
save (strcat(dataDir,'trackingDataAll.mat'),'trackingDataAll')
print('-f1','-djpeg',strcat(dataDir,'pdf.jpeg'));
print('-f2','-djpeg',strcat(dataDir,'annotation.jpeg'));

%%