function confmaps = pts2confmaps(pts, sz, sigma, normalize)
%PTS2CONFMAPS Generate confidence maps centered at specified points.
% Usage:
%   confmaps = pts2confmaps(pts, sz, sigma)
%
% Args:
%   pts: N x 2
%   sz: [rows cols]
%   sigma: filter size (default: 5)
%   normalize: outputs maps in [0, 1] rather than PDF (default: true)
%
% See also: label_joints

if nargin < 3 || isempty(sigma); sigma = 5; end
if nargin < 4 || isempty(normalize); normalize = true; end

confmaps = NaN(sz(1), sz(2), size(pts,1));
xv = 1:sz(2); yv = 1:sz(1);
[XX,YY] = meshgrid(xv,yv);

for i = 1:size(pts,1)
    pt = pts(i,:);
    confmaps(:,:,i) = exp(-((YY-pt(2)).^2 + (XX-pt(1)).^2)./(2*sigma^2));
end

if ~normalize
    confmaps = confmaps ./ (sigma * sqrt(2*pi));
end

end
