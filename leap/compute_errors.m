function err = compute_errors(pos_pred, pos_gt)
%COMPUTE_ERRORS Computes error rates given predicted and ground truth positions.
% Usage:
%   err = compute_errors(pos_pred, pos_gt)
% 
% Args:
%   pos_pred: predicted positions    (J x 2 x N)
%   pos_gt: ground truth predictions (J x 2 x N)
%
% Returns:
%   err: struct with error metrics
% 
% See also: 

if isstruct(pos_pred)
    pos_pred =  pos_pred.positions_pred;
end
if isstruct(pos_gt)
    pos_gt = pos_gt.positions_pred;
end

% Find the difference between predicted and ground truth
delta = pos_pred - pos_gt;

% Find Euclidean distance between each pair of points
euclidean = squeeze(sqrt(sum(delta .^ 2, 2)))';

% Compute metrics overall
mae_all = mean(abs(delta(:)));
mse_all = mean(delta(:) .^ 2);
rmse_all = sqrt(mse_all);

% Compute metrics per joint
delta_rows = reshape(permute(delta,[2 3 1]),[],size(delta,1));
mae = mean(abs(delta_rows));
mse = mean(delta_rows .^ 2);
rmse = sqrt(mse);

% Return everything
err = varstruct(delta, euclidean, ...
    mae_all, mse_all, rmse_all, ...
    delta_rows, mae, mse, rmse);

end
