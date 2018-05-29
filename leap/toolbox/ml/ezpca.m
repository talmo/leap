function pcs = ezpca(X, varargin)
%EZPCA PCA -- quick and easy!
% Usage:
%   pcs = ezpca(X)
% 
% Args:
%   X: N x D data
%
% Notes:
%       Project: (X - pcs.mu) * pcs.coeff
%   Reconstruct: (pcs.score * pcs.coeff') + pcs.mu
% 
% See also: pca

[coeff, score, latent, tsquared, explained, mu] = pca(X, varargin{:});

if nargout < 1
    figure, figclosekey
    subplot(1,2,1)
    imgsc(coeff) % columns = pcs
    xlabel('PCs'), ylabel('Dimensions')
    
    subplot(1,2,2)
    ax = plotExplainedVar(explained);
    hold(ax(2),'on')
    
    hline(ax(2), 95, 'r-')
    hline(ax(2), 99.5, 'g-')
    
    cum_explained = cumsum(explained);
    i95 = find(cum_explained >= 95, 1);
    i995 = find(cum_explained >= 99.5, 1);
    
    plot(ax(2), i95, cum_explained(i95), 'r.', 'MarkerSize',15)
    plot(ax(2), i995, cum_explained(i995), 'g.', 'MarkerSize',15)
    
    figsize(1200,400)
    
    return
end

pcs = varstruct(coeff, score, latent, tsquared, explained, mu);


end
