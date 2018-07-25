% Clean start!
clear all, clc

%% Parameters
% Path to input file
videoPath = '..\..\leap\data\examples\072212_163153.clip.mp4';

% Path to output file
% savePath = '..\..\leap\data\examples\072212_163153.clip.h5';
savePath = 'C:\tmp\072212_163153.clip.h5';

% Frames to convert at a time (lower this if your memory is limited)
chunkSize = 1000;

% Convert frames to single channel grayscale images (instead of 3 channel RGB)
grayscale = true;

%% Initialize
% Open video for reading
vr = VideoReader(videoPath);

% Check size from first frame
I0 = vr.readFrame();
if grayscale; I0 = rgb2gray(I0); end
frameSize = size(I0);
if numel(frameSize) == 2; frameSize = [frameSize 1]; end

% Reset VideoReader
delete(vr);
vr = VideoReader(videoPath);

% Check if file already exists
if exist(savePath,'file') > 0
    warning(['Overwriting existing HDF5 file: ' savePath])
    delete(savePath)
end

% Create HDF5 file with infinite number of frames and GZIP compression
h5create(savePath,'/box',[frameSize inf],'ChunkSize',[frameSize 1],'Deflate',1)

%% Save
buffer = cell(chunkSize,1);
done = false;
framesRead = 0;
framesWritten = 0;
t0 = tic;
while ~done
    % Read next frame
    I = vr.readFrame();
    if grayscale; I = rgb2gray(I); end
    
    % Check if there are any frames left
    done = ~vr.hasFrame();
    
    % Increment frames read counter and add to the write buffer
    framesRead = framesRead + 1;
    buffer{mod(framesRead-1, chunkSize)+1} = I;
    
    % Have we filled the buffer or are there no frames left?
    if mod(framesRead, chunkSize) == 0 || done
        % Concatenate the buffer into an array
        chunk = cat(4, buffer{:});
        
        % Extend the dataset and save to disk
        h5write(savePath, '/box', chunk, [1 1 1 framesWritten+1], size(chunk))
        
        % Increment frames written counter
        framesWritten = framesWritten + size(chunk,4);
    end
end
elapsed = toc(t0);
fprintf('Finished writing %d frames in %.2f mins.\n', framesWritten, elapsed/60)

h5disp(savePath)