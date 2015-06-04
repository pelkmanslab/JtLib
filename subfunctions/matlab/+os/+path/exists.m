function found = exists(thePath)
%EXIST   Return true if pathname exists.
%   Resolves relative paths and extra filesep characters in the input
%   path.
%
%   Syntax:
%      FOUND = exists(THEPATH)
%
%   Input:
%      THEPATH   Path to a file or folder, which should exist
%
%   Output:
%      FOUND   True (1) if path is valid and exists or false (0) otherwise.
%
%   Example:
%      exists('/pathname/to/file')
%
%   2013, Yauhen Yakimovich <eugeny.yakimovitch@gmail.com>
%
%   See also DIRNAME, BASENAME
try
    found = fileattrib(thePath) ~= 0;
catch exception
    warning(exception.message);
    found = 0;
end
