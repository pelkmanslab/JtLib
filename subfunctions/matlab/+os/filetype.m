function s = filetype(fname)
%FILETYPE   Determine file type
%   Uses machine command file to get file description
%
%   Syntax:
%      STR = FILETYPE(FNAME)
%
%   Input:
%      FNAME   File name on a *NIX system
%
%   Output:
%      STR   FNAME type description
%
%   Example:
%      filetype('/home/user/file.pdf') % returns 'PDF document, version 1.3'
%
%   MMA 24-07-2008, mma@odyle.net
%   Dep. Earth Physics, UFBA, Salvador, Bahia, Brasil

s='';
if  strmatch('GLNX',computer)
  [status,desc] = unix(['file -b ' fname]);
  if status==0
    s=desc(1:end-1);
  end
end
