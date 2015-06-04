function emacs(file)
%VI   Run UNIX emacs
%   Runs EMACS on UNIX and the matlab edit on PCWIN
%
%   Syntax:
%      EMACS(FILE)
%
%   Input:
%      FILE   file to open [<none> <abc*def*.*>]
%
%   MMA 12-03-2009, mma@odyle.net
%   CESAM, Portugal
%
%   See Also VI, GV

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
  eval(['! emacs -nw ',file]);
end
