function uninstall_leap()
%UNINSTALL_LEAP Removes LEAP code from the MATLAB path and Python environment.
% Usage:
%   uninstall_leap
% 
% See also: install_leap, test_leap

% Find base repository path (where this file is contained)
basePath = fileparts(which('uninstall_leap'));

% Check if Python package is importable
status = system('pip uninstall -y leap');

works = test_leap();
if ~works
    disp('LEAP uninstalled successfully.')
end

% Remove from MATLAB path
rmpath(genpath(fullfile(basePath,'leap')))


end
