function gray_mean_frame = calculateMeanFrameBatch(numberOfFramesToAverage, firstFrameAverage, lastFrameAverage)
close all;
%Import movie object and get basic data from movie
aviMovies = dir('*.avi');
movMovies = dir('*.mov');
mp4Movies = dir('*.MP4');

% if exist('convertedMovie.avi', 'file') ~= 0
%     movieFile = 'convertedMovie.avi';
% elseif exist('convertedMovie.avi', 'file') == 0 && isempty(aviMovies) == 0
%     movieFile = aviMovies.name;
% elseif exist('convertedMovie.avi', 'file') == 0 && isempty(aviMovies) == 1 && isempty(movMovies) == 0
%     movieFile = movMovies.name;
% end

readerobj = VideoReader(movieFile);
nFramesAverage = numberOfFramesToAverage;
demoFrame = read(readerobj, 1);

%Calculate frames to be pulled in
FramesToPullIn = firstFrameAverage:round((lastFrameAverage-firstFrameAverage)/numberOfFramesToAverage):lastFrameAverage;

%Begin loading in frames
h = waitbar(0,'Calculating Mean Frame. BE PATIENT!');

gray_mean_frame = uint8(zeros(size(demoFrame,1),size(demoFrame,2))); % Initialize accumulator for color frames.

for fr = 2 : nFramesAverage
    
    if size(demoFrame, 3) == 1;
        
        thisFrame = uint8(read(readerobj,FramesToPullIn(fr))); % Initialize accumulator for color frames.
        
        stackedGhostFrame(:, :, 1) = gray_mean_frame;
        stackedGhostFrame(:, :, 2) = thisFrame;
        
        [~,I] = min(stackedGhostFrame, [], 3);
        
        gray_mean_frame((I ==1)) = thisFrame((I ==1));
        gray_mean_frame((I ==2)) = gray_mean_frame((I ==2));
        
        waitbar(fr/nFramesAverage, h);
        
    elseif size(demoFrame, 3) == 3;
        
        thisFrame = uint8(rgb2gray(read(readerobj, FramesToPullIn(fr))));
        
        stackedGhostFrame(:, :, 1) = gray_mean_frame;
        stackedGhostFrame(:, :, 2) = thisFrame;
        
        [~,I] = min(stackedGhostFrame, [], 3);
        
        gray_mean_frame((I ==1)) = thisFrame((I ==1));
        gray_mean_frame((I ==2)) = gray_mean_frame((I ==2));
        
        waitbar(fr/nFramesAverage, h);
    end
    
end

close(h);

save('gray_mean_frame.mat', 'gray_mean_frame', 'numberOfFramesToAverage', ...
    'firstFrameAverage', 'lastFrameAverage');

clear readerobj;