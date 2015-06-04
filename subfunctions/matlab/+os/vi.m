function vi(file)
%VI   Run UNIX vi
%   Runs VI on UNIX and the matlab edit on PCWIN
%
%   Syntax:
%      VI(FILE)
%
%   Input:
%      FILE   file to open [<none> <abc*def*.*>]
%
%   MMA 4-5-2005, martinho@fis.ua.pt
%
%   See Also GV, DSP

%   Department of Physics
%   University of Aveiro, Portugal

if nargin == 0, file = '*'; end
if any(file == '*') | isempty(file)
  [filename, pathname] = uigetfile(file, 'select the file');
  if isequal(filename,0) | isequal(pathname,0)
    return
  else
    file = fullfile(pathname, filename);
  end
else
  file=which(file);
end

if exist(file,'file')~=2, disp(['## file ',file,' not found']); return, end
if isequal(computer,'PCWIN')
  edit(file)
else
  eval(['! vim ',file]);
end
