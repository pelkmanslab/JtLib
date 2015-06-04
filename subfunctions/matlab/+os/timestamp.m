function varargout = timestamp(time)
%TIMESTAMP   UNIX timestamp
%   Returns the UNIX timepstamp, ie, the time is seconds since
%   00:00:00 January 1, 1970, UTC.
%
%   Syntax:
%      T = TIMESTAMP(TIME)
%
%   Input:
%      TIME   Same input as matlab datenum
%
%   Output:
%      time in seconds between 1970-1-1 00:00:00 and TIME
%
%   Examples:
%      timestamp([1970,1,1,0,0,0])
%      timestamp(now)
%
%   MMA 29-7-2005, martinho@fis.ua.pt

%   Department of Physics
%   University of Aveiro, Portugal

t = (datenum(time) - datenum(1970,1,1,0,0,0)) * 86400;
if nargout == 0
   fprintf(1,'\nUNIX timestamp of %s = %10.0f\n\n',datestr(datenum(time)),t);
else
  varargout = {t};
end
