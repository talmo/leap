function map = redblue(N, dark)
%REDBLUE Red and blue colormap going from blue to white to red.
% Usage:
%   map = redblue(N)
% 
% Args:
%   N: number of samples in the colormap (default: 64)
%
% Returns:
%   map: N x 3 matrix of RGB colors
%
% Example:
%   imagesc(repmat(linspace(-1,1,200),100,1)),colorbar,colormap redblue
% 
% See also: colormap, parula

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      N = size(get(groot,'DefaultFigureColormap'),1);
   else
      N = size(f.Colormap,1);
   end
end

if nargin < 2 || isempty(dark); dark = false; end

% basis = [
%     0 0 1 % blue
%     1 1 1 % white
%     1 0 0 % red
%     ];

mid_col = [1 1 1];
if dark; mid_col = [0 0 0]; end

% similar to redbluecmap (bioinformatics toolbox)
basis = [
    0.0196078431372549         0.188235294117647         0.380392156862745 % blue
    mid_col
    0.403921568627451                         0          0.12156862745098 % red
    ];


P = size(basis,1);
map = interp1(1:size(basis,1), basis, linspace(1,P,N), 'linear');

end
