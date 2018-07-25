function confmaps = pts2confmaps(pts, sz, sigma, normalize)
%PTS2CONFMAPS Generate confidence maps centered at specified points.
% Usage:
%   confmaps = pts2confmaps(pts, sz, sigma)
%
% Args:
%   pts: N x 2 or cell array of {N1 x 2, N2 x 2, ...}, where each cell will
%       correspond to a single channel to create multipoint confidence maps
%   sz: [rows cols]
%   sigma: filter size (default: 5)
%   normalize: outputs maps in [0, 1] rather than PDF (default: true)
%
% See also: label_joints

if ~iscell(pts); pts = arr2cell(pts,1); end
if nargin < 3 || isempty(sigma); sigma = 5; end
if nargin < 4 || isempty(normalize); normalize = true; end

confmaps = NaN(sz(1), sz(2), numel(pts));
xv = 1:sz(2); yv = 1:sz(1);
[XX,YY] = meshgrid(xv,yv);

for i = 1:numel(pts)
    x = permute(pts{i}(:,1),[2 3 1]);
    y = permute(pts{i}(:,2),[2 3 1]);
%     confmaps(:,:,i) = sum(exp(-((YY-y).^2 + (XX-x).^2)./(2*sigma^2)),3);
    confmaps(:,:,i) = max(exp(-((YY-y).^2 + (XX-x).^2)./(2*sigma^2)),[],3);
end

if ~normalize
    confmaps = confmaps ./ (sigma * sqrt(2*pi));
end

end
