function paf = graph2paf(nodes, edges, sz, channelsOnly, sigma)
%GRAPH2PAF Converts a set of edges into part affinity fields.
% Usage:
%   graph2paf(nodes, edges, sz, sigma)
% 
% Args:
%   nodes: set of points (N x 2)
%   edges: indices into nodes defining directed edges (E x 2)
%   sz: grid/image size (1 x 2)
%   channelsOnly: stack all PAFs along channels (dim 3) instead of dim 4 (default: true)
%   sigma: maximum distance from edge to keep (default: 5)
% 
% Returns:
%   paf: part affinity fields (sz(1) x sz(2) x 2E) or (sz(1) x sz(2) x 2 x E)
% 
% See also: pts2confmaps

if nargin < 4 || isempty(channelsOnly); channelsOnly = true; end
if nargin < 5 || isempty(sigma); sigma = 5; end

% Create image coordinate grid
[XX,YY] = meshgrid(1:sz(2), 1:sz(1));

% Create PAFs for each edge
E = size(edges,1);
paf = cell(E,1);
for i = 1:E
    % Pull out edge points
    p1 = nodes(edges(i,1),:);
    p2 = nodes(edges(i,2),:);
    
    % Edge length
    L = norm(p2 - p1, 2);

    % Unit vectors
    V = (p2 - p1) ./ L; % pointing along edge
    Vp = [-V(:,2), V(:,1)]; % perpendicular

    % Signed distance along edge
    D1 = sum(V .* ([XX(:) YY(:)] - p1),2);

    % Absolute distance orthogonal to edge
    D2 = abs(sum(Vp .* ([XX(:) YY(:)] - p1),2));

    % Vector field mask
    paf_mask = reshape(D1 >= 0 & D1 <= L & D2 <= sigma, sz);

    % Create vector field along channels (X and Y)
    paf{i} = paf_mask .* permute(V, [1 3 2]);
end

% Merge all edge PAFs
if channelsOnly
    paf = cat(3, paf{:});
else
    paf = cat(4, paf{:});
end

end
