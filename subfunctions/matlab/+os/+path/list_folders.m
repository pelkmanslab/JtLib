function [folders,n] = list_folders(folders,sub)
%LIST_FOLDERS   List subfolders of a desired folder
%   Returns all the directories inside the first one, or only the
%   direct subfolders.
%
%   Syntax:
%      [FOLDERS,N] = LIST_FOLDERS(BASEDIR,ALL)
%
%   Inputs:
%      BASEDIR   The folder to explore
%      ALL       Condition to search only inside BASEDIR or in all
%                the subfolders [ 0 | {1} ]
%
%   Outputs:
%      FOLDERS   All the directories inside BASEDIR (ALL=1) or only
%                the direct  subfolders (ALL=0), cell array
%      N         Length(FOLDERS)
%
%   Comments:
%      Subfolders of a folders without +r permission are not included.
%      If ALL=1, the BASEDIR if the first element of FOLDERS.
%      Without output arguments, the result is listed.
%
%   MMA 17-09-2005, martinho@fis.ua.pt
%
%   See also LIST_FILES

%   Department of Physics
%   University of Aveiro, Portugal

import os.path.list_folders;


if nargin < 2
  sub = 1;
end

if iscell(folders)
  current = folders{end};
else
  current = folders;
  if sub
    folders = {current};
  else
    folders = {};
  end
  if isequal(current(end),filesep)
    current=current(1:end-1);
  end
  if ~(exist(current,'dir') & ~isempty(dir(current)))
    folders={};
    return
  end
  initFolder = current;
end

d=dir(current);
n=length(folders);

for i=1:length(d)
  cdir=d(i);
  if cdir.isdir==1 & ~isequal(cdir.name,'..') & ~isequal(cdir.name,'.')
    n=n+1;
    folders{n}=[current,filesep,cdir.name];
    if sub
      [folders,n]=list_folders(folders,sub);
    end
  end
end

if nargout ~= 0
  return
end

fprintf(1,'\n');
if sub
  fprintf(1,':: All subfolders of : %s\n',initFolder);
else
  fprintf(1,':: Subfolders of : %s\n',initFolder);
end

for i=1:length(folders)
  fprintf(1,'   %s\n',folders{i});
end
fprintf(1,'\n');
