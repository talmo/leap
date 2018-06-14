function savePath = generate_training_set(boxPath, varargin)
%GENERATE_TRAINING_SET Creates a dataset for training.
% Usage: generate_training_set(boxPath, ...)

t0_all = stic;
%% Setup
defaults = struct();
defaults.savePath = [];
defaults.scale = 1;
defaults.mirroring = true; % flip images and adjust confidence maps to augment dataset
defaults.horizontalOrientation = true; % animal is facing right/left if true (for mirroring)
defaults.sigma = 5; % kernel size for confidence maps
defaults.normalizeConfmaps = true; % scale maps to [0,1] range
defaults.postShuffle = true; % shuffle data before saving (useful for reproducible dataset order)
defaults.testFraction = 0; % separate these data from training and validation sets
defaults.compress = false; % use GZIP compression to save the outputs

params = parse_params(varargin,defaults);

% Paths
labelsPath = repext(boxPath,'labels.mat');

% Output
savePath = params.savePath;
if isempty(savePath)
    savePath = ff(fileparts(boxPath), 'training', [get_filename(boxPath,true) '.h5']);
    savePath = get_new_filename(savePath,true);
end
mkdirto(savePath)

%% Labels
labels = load(labelsPath);

% Check for complete frames
labeledIdx = find(squeeze(all(all(~isnan(labels.positions),2),1)));
numFrames = numel(labeledIdx);
printf('Found %d/%d labeled frames.', numFrames, size(labels.positions,3))

% Pull out label data
joints = labels.positions(:,:,labeledIdx);
joints = joints * params.scale;
numJoints = size(joints,1);

% Pull out other info
jointNames = labels.skeleton.nodes;
skeleton = struct();
skeleton.edges = labels.skeleton.edges;
skeleton.pos = labels.skeleton.pos;

%% Load images
stic;
box = h5readframes(boxPath,'/box',labeledIdx);
if params.scale ~= 1; box = imresize(box,params.scale); end
boxSize = size(box(:,:,:,1));
stocf('Loaded %d images', size(box,4))

% Load metadata
try exptID = h5read(boxPath, '/exptID'); exptID = exptID(labeledIdx); catch; end
try framesIdx = h5read(boxPath, '/framesIdx'); framesIdx = framesIdx(labeledIdx); catch; end
try idxs = h5read(boxPath, '/idxs'); idxs = idxs(labeledIdx); catch; end

try L = h5read(boxPath, '/L'); L = L(labeledIdx); catch; end
try box_no_seg = imresize(h5readframes(boxPath,'/box_no_seg',labeledIdx),params.scale); catch; end
try box_raw = imresize(h5readframes(boxPath,'/box_raw',labeledIdx),params.scale); catch; end
attrs = h5att2struct(boxPath);

%% Generate confidence maps
stic;
confmaps = NaN([boxSize, numJoints, numFrames],'single');
parfor i = 1:numFrames
    pts = joints(:,:,i);
    confmaps(:,:,:,i) = pts2confmaps(pts,boxSize,params.sigma,params.normalizeConfmaps);
end
stocf('Generated confidence maps') % 15 sec for 192x192x32x500
varsize(confmaps)

%% Augment by mirroring
if params.mirroring
    % Flip images
    if params.horizontalOrientation
        box_flip = flipud(box);
        try box_no_seg_flip = flipud(box_no_seg); catch; end
        try box_raw_flip = flipud(box_raw); catch; end
        confmaps_flip = flipud(confmaps);
        joints_flip = joints; joints_flip(:,2,:) = size(box,1) - joints_flip(:,2,:);
    else
        box_flip = fliplr(box);
        try box_no_seg_flip = fliplr(box_no_seg); catch; end
        try box_raw_flip = fliplr(box_raw); catch; end
        confmaps_flip = fliplr(confmaps);
        joints_flip = joints; joints_flip(:,1,:) = size(box,2) - joints_flip(:,1,:);
    end

    % Check for *L/*R naming pattern (e.g., {{'wingL','wingR'}, {'legR1','legL1'}})
    swap_names = {};
    baseNames = regexp(jointNames,'(.*)L([0-9]*)$','tokens');
    isSymmetric = ~cellfun(@isempty,baseNames);
    for i = horz(find(isSymmetric))
        nameR = [baseNames{i}{1}{1} 'R' baseNames{i}{1}{2}];
        if ismember(nameR,jointNames)
            swap_names{end+1} = {jointNames{i}, nameR};
        end
    end

    % Swap channels accordingly
    printf('Symmetric channels:')
    for i = 1:numel(swap_names)
        [~,swap_idx] = ismember(swap_names{i}, jointNames);
        if any(swap_idx == 0); continue; end
        printf('    %s (%d) <-> %s (%d)', jointNames{swap_idx(1)}, swap_idx(1), ...
            jointNames{swap_idx(2)}, swap_idx(2))

        joints_flip(swap_idx,:,:) = joints_flip(fliplr(horz(swap_idx)),:,:);
        confmaps_flip(:,:,swap_idx,:) = confmaps_flip(:,:,fliplr(horz(swap_idx)),:);
    end

    % Merge
    [box,flipped] = cellcat({box,box_flip},4);
    joints = cat(3, joints, joints_flip);
    try box_raw = cat(4,box_raw,box_raw_flip); catch; end
    try box_no_seg = cat(4,box_no_seg,box_no_seg_flip); catch; end
    confmaps = cat(4, confmaps, confmaps_flip);

    labeledIdx = [labeledIdx(:); labeledIdx(:)];
    try exptID = [exptID(:); exptID(:)]; catch; end
    try framesIdx = [framesIdx(:); framesIdx(:)]; catch; end
    try idxs = [idxs(:); idxs(:)]; catch; end
end

%% Post-shuffle
shuffleIdx = vert(1:numFrames*2);
if params.postShuffle
    shuffleIdx = randperm(numFrames*2);
    box = box(:,:,:,shuffleIdx);
    labeledIdx = labeledIdx(shuffleIdx);
    try box_no_seg = box_no_seg(:,:,:,shuffleIdx); catch; end
    try box_raw = box_raw(:,:,:,shuffleIdx); catch; end
    try exptID = exptID(shuffleIdx); catch; end
    try framesIdx = framesIdx(shuffleIdx); catch; end
    joints = joints(:,:,shuffleIdx);
    confmaps = confmaps(:,:,:,shuffleIdx);
end

%% Separate testing set
numTestFrames = round(numel(shuffleIdx) * params.testFraction);
if numTestFrames > 0
    testIdx = randperm(numel(shuffleIdx),numTestFrames);
    trainIdx = setdiff(shuffleIdx, testIdx);

    % Test set
    testing = struct();
    testing.shuffleIdx = shuffleIdx(testIdx);
    testing.box = box(:,:,:,testIdx);
    testing.labeledIdx = labeledIdx(testIdx);
    try testing.box_no_seg = box_no_seg(:,:,:,testIdx); catch; end
    try testing.box_raw = box_raw(:,:,:,testIdx); catch; end
    try testing.exptID = exptID(testIdx); catch; end
    try testing.framesIdx = framesIdx(testIdx); catch; end
    testing.joints = joints(:,:,testIdx);
    testing.confmaps = confmaps(:,:,:,testIdx);
    testing.testIdx = testIdx;

    % Training set
    shuffleIdx = shuffleIdx(trainIdx);
    box = box(:,:,:,trainIdx);
    labeledIdx = labeledIdx(trainIdx);
    try box_no_seg = box_no_seg(:,:,:,trainIdx); catch; end
    try box_raw = box_raw(:,:,:,trainIdx); catch; end
    try exptID = exptID(trainIdx); catch; end
    try framesIdx = framesIdx(trainIdx); catch; end
    joints = joints(:,:,trainIdx);
    confmaps = confmaps(:,:,:,trainIdx);
end

%% Save
% Augment metadata
attrs.createdOn = datestr(now);
attrs.boxPath = boxPath;
attrs.labelsPath = labelsPath;
attrs.scale = params.scale;
attrs.postShuffle = uint8(params.postShuffle);
attrs.horizontalOrientation = uint8(params.horizontalOrientation);

% Write
stic;
if exists(savePath); delete(savePath); end

% Training data
h5save(savePath,box,[],'compress',params.compress)
h5save(savePath,labeledIdx)
h5save(savePath,shuffleIdx)
try h5save(savePath,box_no_seg,[],'compress',params.compress); catch; end
try h5save(savePath,box_raw,[],'compress',params.compress); catch; end
try h5save(savePath,exptID); catch; end
try h5save(savePath,framesIdx); catch; end
h5save(savePath,joints,[],'compress',params.compress)
h5save(savePath,confmaps,[],'compress',params.compress)

% Testing data
if numTestFrames > 0
    h5save(savePath,trainIdx)
    h5savegroup(savePath,testing,[],'compress',params.compress)
end

% Metadata
h5writeatt(savePath,'/confmaps','sigma',params.sigma)
h5writeatt(savePath,'/confmaps','normalize',uint8(params.normalizeConfmaps))
h5struct2att(savePath,'/',attrs)
h5savegroup(savePath,skeleton)
h5writeatt(savePath,'/skeleton','jointNames',strjoin(jointNames,'\n'))

stocf('Saved:\n%s', savePath)
get_filesize(savePath)


stocf(t0_all, 'Finished generating training set.');
end