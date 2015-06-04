function output = basename(theFile)
%BASENAME   Filename component of path
%   If the input is a folder, the last subfolder is returned
%
%   Syntax:
%      OUT = BASENAME(FILEPATH)
%
%   Input:
%      FILEPATH   Path to file or folder
%
%   Output:
%      Filename component of path if using the path to a file or the
%      last subfolder when using the path to a folder
%
%   Example:
%      basename('../myfolder')                    % returns myfolder
%      basename('/home/user/myfolder')            % returns myfolder
%      basename('/home/user/myfolder/myfile.txt') % returns myfile.txt
%
%   MMA 18-09-2005, martinho@fis.ua.pt
%
%   See also DIRNAME, REALPATH

%   Department of Physics
%   University of Aveiro, Portugal

if strcmp(theFile(end),'/') || strcmp(theFile(end),'\')
    theFile = theFile(1:end-1);
end
[path,name,ext]=fileparts(theFile);
output = [name,ext];

