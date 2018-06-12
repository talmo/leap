function install_leap()
%INSTALL_LEAP Installs the Python package and adds MATLAB scripts to path.
% Usage:
%   install_leap
% 
% See also: uninstall_leap, test_leap

% Find base repository path (where this file is contained)
basePath = fileparts(which('install_leap'));

% Add to MATLAB path
addpath(genpath(fullfile(basePath,'leap')));

% Check if Python package is importable
canImportPython = test_leap();
if ~canImportPython
    [status,msg] = system(['pip install -e "' basePath '"']);
    disp(msg)
end

% Check again
test_leap;
end
