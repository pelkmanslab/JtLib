function str = hexdisp(hexStr)
%HEXDISP   Convert hexadecimal matrice to char
%   Displays as char the output HEX of HEXFREAD
%
%   Syntax:
%      STR = HEXDISP(HEX)
%
%   Input:
%      HEX   Output of HEXFREAD
%
%   Output:
%      STR   HEX converted to char
%
%   MMA 18-09-2005, martinho@fis.ua.pt
%
%   See also HEXFREAD, HEXTOBIN

%   Department of Physics
%   University of Aveiro, Portugal

%   31-03-2007 - Conversion to bin done by HEXTOBIN

hexStr=strtok(hexStr);
bin=hextobin(hexStr);
str = char(bin);
if nargout == 0
  disp(str);
end
