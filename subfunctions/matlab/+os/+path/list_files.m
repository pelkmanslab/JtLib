function [files,n] = list_files(folder,ext,sub,needle)
%LIST_FILES   List files of a desired folder
%   Returns all the files inside the folder and subfolders, or only
%   inside the folder.
%
%   Syntax:
%      [FILES,N] = LIST_FILES(FOLDER,EXT,ALL,NEEDLE)
%
%   Inputs:
%      FOLDER   The folder to explore
%      EXT      Files extension, optional
%      ALL      Condition to search only inside FOLDER or also in all
%               the subfolders [ {0} | 1 ]
%      NEEDLE   If set, only filenames with NEEDLE will be listed
%
%   Outputs:
%      FILES   All the files inside FOLDER and all subfolders (ALL=1)
%              or only inside FOLDER (ALL=0)
%      N       Length(FILES)
%
%   Comments:
%      Subfolders without +r permission are not used.
%      Without output arguments, the result is listed.
%
%   Example:
%      list_files('/home/user','*',1,'image_') % returns all files in
%      % user's home starting by 'image_' with any extension
%
%   MMA 17-09-2005, martinho@fis.ua.pt
%
%   See also LIST_FOLDERS

%   Department of Physics
%   University of Aveiro, Portugal

%   02-07-2008 - Added needle input argument (UFBA, Salvador, Brasil)

files = {};

if nargin <4
  needle=0;
end

if nargin < 3
  sub = 0;
end

if nargin < 2
  ext = '*';
elseif ~isequal(ext,'*')
  ext = ['*.',ext];
end

if isequal(folder(end),filesep)
  folder=folder(1:end-1);
end

if sub
  folders = list_folders(folder,1);
else
  folders = {folder};
end

n=0;
for i=1:length(folders)
  theFolder = folders{i};
  theFiles = [theFolder,filesep,ext];
  d = dir(theFiles);
  for nf=1:length(d)
    if ~d(nf).isdir
      fname=d(nf).name;
      if needle
        if strfind(fname,needle)
          n=n+1;
          files(n) = {[theFolder,filesep,fname]};
        end
      else
        n=n+1;
        files(n) = {[theFolder,filesep,d(nf).name]};
      end
    end
  end
end

try
  files = sort(files);
end

if nargout ~= 0
  return
end

fprintf(1,'\n');
if sub
  fprintf(1,':: All files (%s) inside : %s\n',ext,folder);
else
  fprintf(1,':: Files (%s) inside : %s\n',ext,folder);
end

for i=1:length(files)
  fprintf(1,'   %s\n',files{i});
end
fprintf(1,'\n');
