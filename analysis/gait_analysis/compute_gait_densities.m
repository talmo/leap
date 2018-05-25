%% Pathing
embed_path = 'Z:\code\2018-05-05_joints_tsne_FlyAging_talmo-labels\results\FlyAging-DiegoCNN_v1.0_filters=64_rot=15_lrfactor=0.1_lrmindelta=1e-05_03.mat';
density_path = 'Z:\code\2018-05-05_joints_tsne_FlyAging_talmo-labels\viz\FlyAging-DiegoCNN_v1.0_filters=64_rot=15_lrfactor=0.1_lrmindelta=1e-05_03\density.mat';

density = load(density_path);
embed = load(embed_path);
Y = embed.Y;
Ld = density.Ld;
gait_path = 'C:\code\murthylab\JointTracker\LabelPostProcessing\GaitVectors3.mat';
gait = load(gait_path);
%% Compute density and segment
sigma = 20/30;
numGridPoints = 500;
gridRange = [-20 20];

% Setup grid
gv = linspace(gridRange(1), gridRange(2), numGridPoints);
xv = gv; yv = gv;

D_tripod = getDensity(Y(gait.hmm.most_likely_seq == 3 & gait.moving_forward',:),sigma, numGridPoints, gridRange);
D_tetrapod = getDensity(Y(gait.hmm.most_likely_seq == 4 & gait.moving_forward',:),sigma, numGridPoints, gridRange);
D_NC = getDensity(Y(gait.hmm.most_likely_seq == 5 & gait.moving_forward',:),sigma, numGridPoints, gridRange);

gait_density = zeros([size(D_tripod),3]);
gait_density(:,:,1) = D_tripod;
gait_density(:,:,2) = D_tetrapod;
gait_density(:,:,3) = D_NC;

% Saving
save_path = 'Gait_Densities';
save(save_path,'gait_density','D_tripod','D_tetrapod','D_NC','Ld');
