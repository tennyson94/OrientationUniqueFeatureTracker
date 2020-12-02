clear all; close all; clc; 

load('gray_mean_frame.mat'); % this loads a background frame for the movie. It is generated by
% running calculateMeanFrameBatch.m with the necessary inputs

exp_directory = pwd;   %this just sets the directory of the movie that you will process

numOfCrays = 3;  %this is the number of crayfish to look for

%Load and Get basic video parameters
disp('Loading Movie ...');
videoFile = dir('*.avi'); %this will first look for a .avi movie
videoName = [videoFile.name];

if isempty(videoName) == 1
    videoFile = dir('*.mov'); %if no .avi is found, it will next look for a .mov
    videoName = [videoFile.name];
end

readerobj = VideoReader(videoName);
disp('Movie Loaded');
warning('off', 'all');

frame_rate = get(readerobj, 'FrameRate');
numFrames = get(readerobj, 'numberOfFrames');
desiredFrameRate = frame_rate; %final frame rate
framesToResample = frame_rate / desiredFrameRate;

startFrame = 1;    %this is the first frame that you will analyze
last_frame = numFrames;  %this is the last frame that you will analyze
movieFrame = read(readerobj, 1); %this is loading in the first frame of the movie

if size(movieFrame, 3) == 3                 %if your movie is in color, we will convert it to grayscale
    movieFrame =  rgb2gray(movieFrame);
end

% Generate ghostFrame and display
ghostFrame = gray_mean_frame - movieFrame; 
figure; 
imshow(ghostFrame); hold all;
title('First Ghost Frame');
% ghostFrame(:, 1:200) = 0;
% ghostFrame(:, 1650:1920) = 0; 

% save ghostframe as previous frame for comparing across subsequent frames
prev_ghostFrame = ghostFrame;

z = 1; 
% Frames 2-6 note this for loop starts at startFram +1 so that we can use the previous ghostFrame
for i = startFrame + 1:30:1000   
    disp(['You are on frame ' num2str(z) ' of ' num2str(ceil((last_frame - startFrame)/framesToResample)) ' frames in directory ' ...
        exp_directory(find(exp_directory == '/', 2, 'last')+1:length(exp_directory))]);
    
    % Read in current movieFrame and turn to ghostFrame
    movieFrame = read(readerobj, i);  
    
    if size(movieFrame, 3) == 3
        movieFrame =  rgb2gray(movieFrame);
    end
    
    ghostFrame = gray_mean_frame - movieFrame; %generate ghost frame
    figure; hold all;
    imshow(ghostFrame); hold all;
    title(['Ghost Frame ' num2str(z)]); 
    %ghostFrame(:, 1:200) = 0;
    %ghostFrame(:, 1650:1920) = 0; 

    movieFrame = ghostFrame;           %set the movie frame to ghostFrame
    templateFrame = prev_ghostFrame;  %set the previous ghostframe as the template that we will use to search for crayfish in the current frame
    
    

        boxPoints = detectSURFFeatures(templateFrame, 'MetricThreshold', 200, 'NumOctaves', 1, 'NumScaleLevels', 6); %Note I just kept the variable names the same as in the matlab tutorial. This finds the strongest features in the previous frame
        scenePoints = detectSURFFeatures(movieFrame, 'MetricThreshold', 200, 'NumOctaves', 1, 'NumScaleLevels', 6); %This finds the strongest features in the current frame

        %%%%%%%This will plot those features if you like%%%%%%%%%%
    %         figure;
    %         imshow(templateFrame);
    %         title('100 Strongest Feature Points from Box Image');
    %         hold on;
    %         plot(selectStrongest(boxPoints, 100));
    %     
    %         %%%%%%%%%This will plot strongest features in current frame if you like%%%%%%%%%%%%%%%%
    %     
    %         figure;
    %         imshow(movieFrame);
    %         title('300 Strongest Feature Points from Scene Image');
    %         hold on;
    %         plot(selectStrongest(scenePoints, 300));


        %These two lines of code extract certain features from those above. It will
        %use these extracted features to match between the previous and current
        %frame
        [boxFeatures, boxPoints] = extractFeatures(templateFrame, boxPoints);
        [sceneFeatures, scenePoints] = extractFeatures(movieFrame, scenePoints);

        %this line actually matches between the frame
        boxPairs = matchFeatures(boxFeatures, sceneFeatures);

        %THe points are simply being saved to these variable names.
        matchedBoxPoints = boxPoints(boxPairs(:, 1), :);
        matchedScenePoints = scenePoints(boxPairs(:, 2), :);

        %This just plots the matched points between the previous frame and the
        figure;
        showMatchedFeatures(templateFrame, movieFrame, matchedBoxPoints, ...
            matchedScenePoints, 'montage');
        title('Putatively Matched Points (Including Outliers)');

        %here we are just setting the current ghost frame to the previous one.
        %As we move through the loop, this will allow us to keep comparing
        %to the previous frame.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Centroid of current ghostFrame
BW = im2bw(ghostFrame,0.2); %next convert the image to binary
s = regionprops(BW,'basic'); %this looks for connected pixels and returns a few properties about them including their position and area

%set the blobs' areas to a variable
areas = [s.Area];  
%sort the blobs by total area
[~, area_Indices] = sort(areas, 'descend'); 
%keep only the three biggest blobs
s = s(area_Indices(1:numOfCrays));

% get centroids and save into centroids array for each frame z
centroids(z,:) = [s.Centroid];

% plot all centroids for current frame (ghostFrame)
counter = 1;
for ii = 1 : numOfCrays
    plot(centroids(z,counter),centroids(z,counter+1),'*');
    counter = counter + 2;
end
% c = centroids(z,:);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    prev_ghostFrame = ghostFrame;
    z = z + 1;

    %this pause just means that you have to hit return to see the next
    %frame. This should just make it easy to look at over many frames for
    %now.
    pause;

    
    
   
end


%This code below can be used to find crayfish in any frames. It basically
%looks for the biggets blobs in a binary image

% Set level to a value between 0 and 1, possibly 0.1
%level = graythresh(ghostFrame); %Find a threshold to binarize the image
BW = im2bw(ghostFrame,0.2); %next convert the image to binary
figure;
imshow(BW);

s = regionprops(BW,'basic'); %this looks for connected pixels and returns a few properties about them including their position and area

areas = [s.Area];    %set the blobs' areas to a variable
[~, area_Indices] = sort(areas, 'descend'); %sort the blobs by total area

s = s(area_Indices(1:numOfCrays)); %keep only the three biggest blobs

%below we are just plotting the blobs
for k = 1 : length(s)
    thisBB = s(k).BoundingBox;
    rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
        'EdgeColor','r','LineWidth',2 )
end


% Locate points inside the bounding box, and exclude outliers
% Find velocity by subtracting centroids, this gives us orientation
% compare the centroid value to all of the points generated by track in
% cluttered scene, pick out the one with the smallest distance as the one
% leading direction 
