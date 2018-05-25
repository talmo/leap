clear all;
%% Look at particular section
% Pick the gait example to observe
% load('TetrapodExample');
load('TripodExample');

% Plot the velocity of the leg tips
figure('pos',[153, 427, 560, 420]); hold on; axis tight; set(gcf,'color','w'); fontsize(16)
imagesc(example_vel);
xlabel('Time (seconds)')
xticklabels(xticks/Fs);
ylabel('Leg Tip')
yticks([1:6])
yticklabels({'RF','RM','RH','LF','LM','LH'})
ax1 = gca;
caxis([-10 10]);

% Plot the rasters
figure('pos',[850, 634, 848, 334]); hold on; axis tight; set(gcf,'color','w'); fontsize(16)
imagesc(example_stance); colormap('gray');
xlabel('Time (seconds)')
xticklabels(xticks/Fs);
ylabel('Leg Tip')
yticks([1:6])
yticklabels({'LF','LM','LH','RF','RM','RH'})
ax2 = gca;

% plot the forward velocity of the fly
figure('pos',[850, 359, 854, 186]); hold on; axis tight; set(gcf,'color','w'); fontsize(16)
plot(example_fv.*Fs)
xlabel('Time (seconds)')
xticklabels(xticks/Fs);
ylabel('Forward Velocity (mm/s)')
ax3 = gca;
ylim([0 40]);

% plot the raster of tripod, tetrapod, or non-canonical
figure('pos',[849, 114, 931, 150]); hold on; axis tight; set(gcf,'color','w'); fontsize(16)
example_gait = sum(example_stance,1);
example_gait(~(example_gait == 3 | example_gait == 4)) = 5; 
imagesc(example_gait);colormap('jet');h = colorbar; 
xlabel('Time (seconds)')
xticklabels(xticks/Fs);
yticks([])
ylabel(h,'Number of legs in stance')
ax4 = gca;
linkaxes([ax1,ax2,ax3,ax4],'x')

%% Plot the emission probabilities for each hidden states
load('GaitVectors3.mat');
emissions = hmm.ESTEMIT;
temp = emissions(2,:);
emissions(2,:) = emissions(3,:);
emissions(3,:) = temp;
figure; hold on;
imagesc(emissions);
for i = 1:size(emissions,1)
    for j = 1:size(emissions,2)
        caption = sprintf('%.2f',emissions(i,j));
        text(j,i,caption,'Fontsize',10,'FontWeight','bold','HorizontalAlignment','center','Color',[0 0 0]);
    end
end
axis ij;
axis tight
xlabel('Number of Legs in Stance');
yticks([1 2 3]);
yticklabels({'Tripod','Tetrapod','Non-canonical'})
xticklabels({'0','1','2','3','4','5','6'})
fontsize(16)

figure; hold on;
plot(emissions','LineWidth',3);
xlabel('Number of Legs in Stance');
xticklabels({'0','1','2','3','4','5','6'})
legend({'Tripod','Tetrapod','Non-canonical'})
ylabel('Emission Probability')

%% Plot the distribution of speeds
load('Gait_Speed_Distributions');
figure; hold on;
plot(edges1(1:end-1),N1,'LineWidth',3)
plot(edges2(1:end-1),N2,'LineWidth',3)
plot(edges3(1:end-1),N3,'LineWidth',3)
xlabel('Forward Velocity (ms)')
ylabel('Count')
xlim(speed_lim)
legend({'Tripod','Tetrapod','Non-canonical'})
fontsize(16)

%% Plot the velocity Distributions
load('Cluster_Velocity_Distributions');
figure; hold on;
cmap = spring(num_states);
for i = 1:num_states
    plot(edges{i}(1:end-1),N{i},'Color',cmap(num_states + 1 -i,:),'LineWidth',3);
end
grid on;
xlabel('Forward Velocity')
ylabel('Probability')
axis tight;
ylim([0 .2])

%% Plotting the mean and std with bounded lines
load('Swing_Velocity_Over_Time');
cmap = parula(numel(speed_levels));
p_lines = cell1(numel(speed_levels)-1);
figure('pos',[568, 186, 1036, 798]); figclosekey; set(gcf,'color','w'); hold on;
for i = 1:size(leg_vel_at_speed,1)
    yci = zeros(2,size(leg_vel_at_speed,2));
    yci(1,:) = leg_vel_std_at_speed(i,:);
    yci(2,:) = leg_vel_std_at_speed(i,:);
    [p_lines{i},~] = boundedline(win*10,leg_vel_at_speed(i,:),yci','alpha','cmap',cmap(i,:));
    p_lines{i}.LineWidth = 3;
end

% Legend
leg = cell([1 numel(speed_levels)-1]);
for i = 1:numel(speed_levels)-1
    leg{i} = sprintf('%d - %d mm/s',speed_levels(i),speed_levels(i+1));
end
l = legend([p_lines{:}],leg);
l.Position = [0.7503 0.6488 0.1573 0.3239];
fontsize(16)
xlabel('Time from swing onset (ms)')
ylabel('Swing velocity (mm/s)')
% export_fig('figs/Swing_Velocity_vs_Time_Confidences.png','-r300')

%% Plot the Swing_and_Stance_versus_Velocity
load('Swing_and_Stance_versus_Velocity')
figure; figclosekey, hold on;

yci = zeros(2,numel(stance_dur_std));
yci(1,:) = stance_dur_std;
yci(2,:) = stance_dur_std;
[bl1,~] = boundedline(stance_edges(2:end),stance_dur_mu',yci','alpha');

yci = zeros(2,numel(swing_dur_std));
yci(1,:) = swing_dur_std;
yci(2,:) = swing_dur_std;
[bl2,~] = boundedline(swing_edges(2:end),swing_dur_mu',yci','alpha','r');

yticklabels(round(yticks*10))
ylabel('Durations (ms)');
xlabel('Average Body Speed (mm/s)');
axis tight
legend([bl1,bl2],{'Stance','Swing'})
fontsize(16);