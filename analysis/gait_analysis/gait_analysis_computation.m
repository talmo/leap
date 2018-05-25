clear all;
%% Pathing
% addpath(genpath('deps'));
joints_dir = 'Z:\data\JointTracker\2018-02_FlyAging_boxes\expts\preds\talmo-labels\FlyAging-DiegoCNN_v1.0_filters=64_rot=15_lrfactor=0.1_lrmindelta=1e-05_03';
data_dir = 'Z:\data\Fly_Aging\male_data';

% Get the paths from the directories
data_fns = dir([data_dir,'/*_*']);
exptnames = {data_fns(:).name};

joint_fns = dir(strcat(joints_dir,'\*.h5'));
joint_exptnames = {joint_fns(:).name};
joint_exptnames = cf(@(x) x(1:end-3),joint_exptnames);

joint_expt_2_data = zeros(size(joint_exptnames));
for i = 1:numel(joint_exptnames)
    for j = 1:numel(exptnames)
        if strcmp(exptnames{j},joint_exptnames{i})
           joint_expt_2_data(i) = j;
        end
    end
end

joint_paths = cell(size(joint_fns));
for i = 1:numel(joint_fns)
    joint_paths{i} = fullfile(joint_fns(i).folder,joint_fns(i).name);
end

data_paths = cell(size(data_fns));
for i = 1:numel(data_fns)
    data_paths{i} = [fullfile(data_fns(i).folder,data_fns(i).name),'/Positions.dat'];
end

%% Get all of the positions for all of the videos. 
pos = cell(size(joint_paths));
% Loads the joint positions and adds the thorax back in to the fifth
% feature as all zeros.
parfor i = 1:numel(joint_paths)
    joints = h5read(joint_paths{i},'/positions_pred');
    joints = joints - joints(5,:,:);
    joints = reshape(joints,[],size(joints,3));
    pos{i} = joints;
end
pos = cat(2,pos{:});

%% Get the ids of all of the walking bouts according to the speed of centroids
moving_forward = cell(size(data_paths));
forward_velocity = cell(size(data_paths));
speed = cell(size(data_paths));
smoothing_window = 5;

% Velocity thresholds 
reconversion_constant = (1/(24.40/1088))./35; % This corrects a previous measurement error
conversion_to_mm = 31.0857/1088;
forward_motion_thresh = .02; % 2 mm/s

% For each video, get all velocity and speed stats;
for i = 1:numel(data_paths)
    % Load centers from ellipse data and smooth
    frames = h5read(['Z:\data\JointTracker\2018-02_FlyAging_boxes\expts\' exptnames{i} '.h5'],'/framesIdx');
%     ell = h5read(data_paths{i},'/ell');
    [X,Y,numLines] = positionReader(data_paths{i});
    X = X.*reconversion_constant;
    Y = Y.*reconversion_constant;% reconversion constants.
    ctr = [X(frames),Y(frames)];
    ctr = smoothdata(ctr,1,'movmean',smoothing_window);
    ell = h5read(['Z:\data\JointTracker\2018-02_FlyAging_boxes\expts\' exptnames{i} '.h5'],'/ell');
    
    % Get the velocity, direction of motion, and orientation of the fly
    vel_ctr = diffpad(ctr);
%     vel_ctr = smoothdata(vel_ctr,1,'movmean',smoothing_window*10);

    direction_of_motion = smoothdata(mod(unwrap(atan2(vel_ctr(:,2),vel_ctr(:,1))),2*pi),'movmean',smoothing_window);
    orientation = mod(unwrap((ell(frames,5)*2*pi/360)),2*pi);
    difference_dir = abs(direction_of_motion-orientation);
 
    % Get the component of the velocity in the forward direction
    speed_ctr = sqrt(sum(vel_ctr.^2,2));
    speed{i} = speed_ctr;
    forward_velocity{i} = cos(difference_dir).*speed{i};
    moving_forward{i} = forward_velocity{i} > forward_motion_thresh; 
end
lengths = cellfun(@(x) numel(x),moving_forward);
speed = cat(1,speed{:});
moving_forward = cat(1,moving_forward{:});
forward_velocity = cat(1,forward_velocity{:});
fv = forward_velocity;

%% Get rasters of when legs are moving in the forward direction
% This is meant to replicate "Quantification of 
% gait parameters in freely walking wild type and sensory deprived 
% Drosophila melanogaster" Figure 4
Fs = 100;

% We want to look at only the leg tips 
tips = [22 26 30 10 14 18]; % (The order matches the paper)
pos_tips = reshape(pos,[],2,size(pos,2));
pos_tips = pos_tips(tips,:,:);
dim = 1; % Only look in the x direction 
traj = squeeze(pos_tips(:,dim,:));

% Get the velocity relative to the center of the fly (egocentric vel) 
vel = diffpad(traj,2);
vel = smoothdata(vel,2,'gauss',smoothing_window);

% Define stance to be when the legs move in the negative x direction. 
stance = vel<0;

%% Get the contiguous bouts that will be used for HMM fitting
seq = sum(stance)+1;
TRGuess = rand(3);
EMITGuess = rand(3,7);
mf = find(moving_forward);

% Get the frames of contiguous bouts
endFrames = cumsum(lengths);
startFrames = [1 endFrames(1:end-1)'+1];
samples = cell1(numel(lengths));
samples_per_video = 3000;
duration_thresh = 50;
for i = 1:numel(lengths)
    bw = bwconncomp(moving_forward(startFrames(i):endFrames(i)));
    duration = cellfun(@(x) numel(x),bw.PixelIdxList);
    bw.PixelIdxList(duration < duration_thresh) = [];
    ids = cat(1,bw.PixelIdxList{:});
    ids = ids(1:(min(samples_per_video,numel(ids))));
    samples{i} = startFrames(i) + ids - 1;
end
num_samples = cellfun(@(x) numel(x),samples);
samples = cat(1,samples{num_samples>1});

%% Train HMM and get most likely sequence
tic;[ESTTR,ESTEMIT] = hmmtrain(seq(samples),TRGuess,EMITGuess);toc
mls = hmmviterbi(seq,ESTTR,ESTEMIT);

%% Here you should look at the emission probabilities
figure;
imagesc(ESTEMIT);

%% Reorder the labels to 3 = tripod, 4 = tetrapod, 5 = non-canonical
% Note: this can be automated, but since initialization is random
% and it doesn't take that long to train, I prefer checking manually. 
mls(mls == 3) = 4;
mls(mls == 2) = 5;
mls(mls == 1) = 3;

%% Save results into a structure
hmm.TRGUESS = TRGuess;
hmm.EMITGUESS = EMITGuess;
hmm.TrainingSamples = uint8(seq(samples));
hmm.ESTTR = ESTTR;
hmm.ESTEMIT = ESTEMIT;
hmm.most_likely_seq = uint8(mls);

% Saving
% save_path = 'GaitVector3';
% save(save_path,'hmm');

%% Look at particular section
% Limit the window to a particular region
% Tripod = 17230751;
% Tetrapod = 4781582;
% Tetrapod = 8472800
start = 8472800;
ids = start:start+100;

% Save example gait vectors
example_vel = vel(:,ids);
example_stance = stance(:,ids);
example_fv = fv(ids);

% Saving
% save_path = 'TripodExample';
% save_path = 'TetrapodExample';
% save(save_path,'example_vel','example_stance','example_fv','Fs');

%% Calculate the distribution of speeds for each hidden state and save
mls = hmm.most_likely_seq;
speed_lim = [2 35]; % mm/s
tri_ids = moving_forward & (mls == 3)' & (fv.*Fs < speed_lim(2)) & (fv.*Fs > speed_lim(1));
tetra_ids = moving_forward & (mls == 4)' & (fv.*Fs < speed_lim(2)) & (fv.*Fs > speed_lim(1));
NC_ids = moving_forward & (mls == 5)' & (fv.*Fs < speed_lim(2)) & (fv.*Fs > speed_lim(1));


[N1,edges1] = histcounts(fv(tri_ids).*Fs,166);
[N2,edges2] = histcounts(fv(tetra_ids).*Fs,166);
[N3,edges3] = histcounts(fv(NC_ids).*Fs,166);

% Saving
% save_path = 'Gait_Speed_Distributions';
% save(save_path,'N1','N2','N3','edges1','edges2','edges3','speed_lim')

%% Look at the Velocity statistics per Tsne locomotor state
density_path = 'Z:\code\2018-05-05_joints_tsne_FlyAging_talmo-labels\viz\FlyAging-DiegoCNN_v1.0_filters=64_rot=15_lrfactor=0.1_lrmindelta=1e-05_03\density.mat';
density = load(density_path);
embedding_ordered_locomotor_states = [7 11 13 10 8 9];
num_states = numel(embedding_ordered_locomotor_states);

%% Calculate the velocity distributions.
speed_ids = fv > 0 & fv < .4;
h = cell1(num_states);
N = cell1(num_states);
edges = cell1(num_states);
for i = 1:num_states
    state_ids = density.YL == embedding_ordered_locomotor_states(i);
    [N{i},edges{i}] = histcounts(fv(state_ids & speed_ids)*100,'Normalization','pdf');
end

% Saving
% save_path = 'Cluster_Velocity_Distributions';
% save(save_path,'N','edges','num_states');

%% Calculate the velocity of legs during swing as you bin velocities differently
win = -1:5;
speed_levels = [2 5:5:45];
leg_vel_at_speed = zeros(numel(speed_levels)-1,numel(win));
leg_vel_std_at_speed = zeros(numel(speed_levels)-1,numel(win));

% For each body speed level get the velocity of the swings over the window
for s = 1:numel(speed_levels)-1
    swings = cell([size(vel,1) 1]);
    inSpeed = (speed'*Fs >= speed_levels(s) & speed'*Fs < speed_levels(s+1));
    % Get the swings in which the fly was at the speed level and moving
    % forward.
    parfor i = 1:size(vel,1)
        % First get the swing starts
        bw = bwconncomp(~stance(i,:));
        ids = cell2mat(cf(@(x) x(1),bw.PixelIdxList));
        swing_start = false(size(stance(i,:)));
        swing_start(ids) = true;
        % Then get the swing starts where the fly is moving forward within
        % the speed threshold. 
        bw = bwconncomp(swing_start  & inSpeed);
        ids = cell2mat(cf(@(x) x(1),bw.PixelIdxList));
        ids = ids' + win;
        vel_i = vel(i,:);
        swings{i} = indpad(vel_i,ids);
    end
    swings = cat(1,swings{:});
    leg_vel_at_speed(s,:) = nanmean(swings,1);
    leg_vel_std_at_speed(s,:) = nanstd(swings,1);
end

% Saving
% save_path = 'Swing_Velocity_Over_Time';
% save(save_path,'leg_vel_at_speed','leg_vel_std_at_speed','speed_levels','win');

%% Stance / Swing Duration
swing_durations = cell([1,size(stance,1)]);
stance_durations = cell([1,size(stance,1)]);
swing_body_velocities = cell([1,size(stance,1)]);
stance_body_velocities = cell([1,size(stance,1)]);
period = cell([1,size(stance,1)]);
period_velocities = cell([1,size(stance,1)]);

% Get the swing, stance, and period duration and velocities
parfor i = 1:size(stance,1)
    % Swing
    bw = bwconncomp(~stance(i,:));
    swing_durations{i} = cellfun(@(x) numel(x),bw.PixelIdxList);
    swing_body_velocities{i} = cellfun(@(x) mean(fv(x)),bw.PixelIdxList);
    
    % Stance
    bw = bwconncomp(stance(i,:));
    stance_durations{i} = cellfun(@(x) numel(x),bw.PixelIdxList);
    stance_body_velocities{i} = cellfun(@(x) mean(fv(x)),bw.PixelIdxList);
    
    % Period
%     bw = bwconncomp(stance(i,:));
    period{i} = cellfun(@(x,y) numel(x(1):y(end)),{bw.PixelIdxList{1:end-1}},{bw.PixelIdxList{2:end}});
    period_velocities{i} = cellfun(@(x,y) mean(fv(x(1):y(end))),{bw.PixelIdxList{1:end-1}},{bw.PixelIdxList{2:end}});
end

swing_durations = cat(2,swing_durations{:});
stance_durations = cat(2,stance_durations{:});
swing_body_velocities = cat(2,swing_body_velocities{:});
stance_body_velocities = cat(2,stance_body_velocities{:});
period = cat(2,period{:});
period_velocities = cat(2,period_velocities{:});

%% Plot as a line plot
stance_vel_thresh = 7.2; % This number is taken from Mendes et al

ids = stance_body_velocities*Fs > stance_vel_thresh;
xranges = [stance_vel_thresh  50];
yranges = [0 prctile(stance_durations(ids),99)];
stance_edges = xranges(1):1:xranges(2);

% Stance Duration vs Velocity
X1 = stance_body_velocities(ids)*Fs;
Y1 = stance_durations(ids);
[X1ids] = discretize(X1,stance_edges);
[stance_dur_mu, stance_dur_std] = grpstats(Y1, categorical(X1ids),{'mean','std'});

swing_vel_thresh = 7.2; % This number is taken from Mendes et al
ids = swing_body_velocities*Fs > swing_vel_thresh;
xranges = [swing_vel_thresh  50];
swing_edges = xranges(1):1:xranges(2);

% Stance Duration vs Velocity
X2 = swing_body_velocities(ids)*Fs;
Y2 = swing_durations(ids);
[X2ids] = discretize(X2,swing_edges);
[swing_dur_mu, swing_dur_std] = grpstats(Y2, categorical(X2ids),{'mean','std'});

% Saving
% save_path = 'Swing_and_Stance_versus_Velocity';
% save(save_path,'stance_dur_mu','swing_dur_mu','stance_dur_std','swing_dur_std','stance_edges','swing_edges')
