function gv(file)
%GV   Run UNIX gv
%   Runs GV on UNIX and default ps viewer on PCWIN.
%
%   Syntax:
%      GV(FILE)
%
%   Input:
%      FILE   file to open [<none> <abc*def*.*>]
%
%   MMA 4-5-2005, martinho@fis.ua.pt
%
%   See Also VI, DSP

%   Department of Physics
%   University of Aveiro, Portugal

%   27-09-2005 - Corrected for PCWIN
%   17-10-2005 - Small simplification in uigetfile

if nargin == 0, file = '*'; end
if any(file == '*') | isempty(file)
  [filename, pathname] = uigetfile({'*.ps;*.eps;*.pdf', 'Postscript Files'; '*.*',  'All Files'}, 'select the file');
  if isequal(filename,0) | isequal(pathname,0)
    return
  else
    file = fullfile(pathname, filename);
  end
end
if exist(file,'file')~=2, disp(['## file ',file,' not found']); return, end
if isequal(computer,'PCWIN')
  eval(['! ',file]);
else
  eval(['! gv ',file],'');
end
