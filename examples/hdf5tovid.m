% Clean start!
clear all, clc

%% Parameters
% Path to input file
dataPath = '../data/examples/072212_163153.clip.h5';

% Dataset name
dset = '/box';

% Path to output file
savePath = 'C:\tmp\072212_163153.clip.mp4';

% Frames to convert at a time (lower this if your memory is limited)
chunkSize = 1000;

% Framerate for playback of the video file
fps = 25;

%% Initialize
% Get dataset info
info = h5info(dataPath, dset);
shape = info.Dataspace.Size;
numFrames = shape(end);

% Check if file already exists
if exist(savePath,'file') > 0
    warning(['Overwriting existing video file: ' savePath])
    delete(savePath)
end

% Open video for writing
writer = VideoWriter(savePath,'MPEG-4'); % use this for MP4s
% writer = VideoWriter(savePath,'Motion JPEG AVI'); % use this for AVIs

% Set compression quality (higher = bigger file, better quality)
writer.Quality = 100;

% Set playback speed in frames/second
writer.FrameRate = fps;

% Open file for writing
writer.open();

%% Save
framesWritten = 0;
done = false;
t0 = tic;
while ~done
    % Check how many frames to read
    chunkFrames = min(chunkSize, numFrames - framesWritten);
    
    % Read chunk
    chunk = h5read(dataPath,dset,[1 1 1 framesWritten+1], [inf inf inf chunkFrames]);
    
    % Check for datatype/range concordance (floats must be in [0,1])
    if isfloat(chunk) && max(chunk(:)) > 1
        chunk = chunk / 255;
    end
    
    % Write frames
    writer.writeVideo(chunk);

    % Increment frames written counter
    framesWritten = framesWritten + size(chunk,4);
    
    % Check if we're done
    done = framesWritten >= numFrames;
end

elapsed = toc(t0);
fprintf('Finished writing %d frames in %.2f mins:\n\t%s\n', framesWritten, elapsed/60, savePath)

% Close file
writer.close();
