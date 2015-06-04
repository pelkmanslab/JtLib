function output = dirname(theFile)
%DIRNAME   Directory name component of path
%   Returns the absolute path of a file or folder. In the case of
%   using the path to a file, only the file's folder path is returned.
%
%   Syntax:
%      OUT = DIRNAME(THEPATH)
%
%   Input:
%      THEPATH   Path to a file or folder, which should exist
%
%   Output:
%      OUTPUT   The absolute folder pathname or [] if THEPATH does
%               not exist
%
%   Example:
%      realpath('../myfile.txt'); % returns /home/user/whatever
%
%   MMA 18-09-2005, martinho@fis.ua.pt
%
%   See also REALPATH, BASENAME

%   Department of Physics
%   University of Aveiro, Portugal

if strcmp(theFile(end),'/') || strcmp(theFile(end),'\')
    theFile = theFile(1:end-1);
end
[path,name,ext]=fileparts(theFile);
output = path;
