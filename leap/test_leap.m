function works = test_leap()
%TEST_LEAP Checks whether LEAP is properly installed.
% Usage:
%   test_leap
%   works = test_leap % returns true/false
% 
% See also: install_leap

works = true;

% Check if we can import the LEAP package from anywhere
cdCmd = ['cd "' matlabroot '"'];
if ispc(); cdCmd = ['cd /D "' matlabroot '"']; end
[status,msg] = system([cdCmd ' && python -c "import leap"']);

if status ~= 0
    works = false;
end

if nargout == 0
    if works
        printf('Test LEAP successful!')
    else
        disp('Unable to import LEAP python package. Make sure LEAP and its dependencies are installed.')
        disp('Go to the base LEAP directory containing setup.py and run from MATLAB:')
        disp('    !pip install -e .')
        disp('Or try the MATLAB installer:')
        disp('    install_leap')
    end
    clear works
end

end
