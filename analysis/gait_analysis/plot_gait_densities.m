clear all;
%% Plot all three densities overlayed ontop of one another
load('Gait_Densities');
figure; hold on;
h = imagesc(gait_density./(max(max(max(gait_density)))));
axis equal; axis xy; axis off

%% Plot the distributions for each mode in the same scale

Locomotor_states = [7 11 13 9 10 8];
[cropped,~,crop_mask] = bwcrop(ismember(Ld,Locomotor_states));

figure; hold on; axis xy; axis equal; axis off;
cropped_density = reshape(D_tripod(crop_mask),size(cropped,1),[]);
h = imagesc(cropped_density);
c1 = colorbar;
peak = max(c1.Limits);
colormap('viridis')

figure; hold on; axis xy; axis equal; axis off;
cropped_density = reshape(D_tetrapod(crop_mask),size(cropped,1),[]);
h = imagesc(cropped_density);
% h.AlphaData = 1 .* ~reshape(density.Lbnds(crop_mask),size(cropped,1),[]);
c2 = colorbar;
colormap('viridis')
caxis([0 peak]);

figure; hold on; axis xy; axis equal; axis off;
cropped_density = reshape(D_NC(crop_mask),size(cropped,1),[]);
h = imagesc(cropped_density);
% h.AlphaData = 1 .* ~reshape(density.Lbnds(crop_mask),size(cropped,1),[]);
colormap('viridis')
c3 = colorbar;
caxis([0 peak]);
