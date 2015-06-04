function dsp(file)
%DSP   Run UNIX display
%   Runs display (ImageMagic) on UNIX and default image viewer
%   on PCWIN.
%
%   Syntax:
%      DSP(FILE)
%
%   Input:
%      FILE   file to open [<none> <abc*def*.*>]
%
%   MMA 4-5-2005, martinho@fis.ua.pt
%
%   See also VI, GV

%   Department of Physics
%   University of Aveiro, Portugal

%   27-9-2005 - Corrected for PCWIN

if nargin == 0, file = '*'; end
if any(file == '*') | isempty(file)
  [filename, pathname] = uigetfile({'*.tif;*.gif;*.jpg;*.png'}, 'select the file');
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
  eval(['! display ',file],'');
end
