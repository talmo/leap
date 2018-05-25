function [pts, confvals] = confmaps2pts(C)
%CONFMAPS2PTS Convert a set of confidence maps into a set of points.
% Usage:
%   [pts, confvals] = confmaps2pts(C)
%
% See also: pts2confmaps

numChannels = size(C,3);
pts = zeros(numChannels,2,'single');
confvals = zeros(numChannels,1,'like',C);
for i = 1:numChannels
    [confvals(i), ind] = max(vert(C(:,:,i)));
    [r,c] = ind2sub(size(C(:,:,i)),ind);
    pts(i,:) = [c r];
end

end

