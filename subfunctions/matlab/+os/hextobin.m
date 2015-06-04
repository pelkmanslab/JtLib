function bin=hextobin(s)
%HEXTOBIN  Convert hexadecimal string to binary
%
%   Syntax:
%      BIN=HEXTOBIN(STR)
%
%   Input:
%      STR   Hexadecimal string
%
%   Output:
%      BIN   Hex converted to bin
%
%   MMA 5-3-2007, martinho@fis.ua.pt
%
%   See also HEXFREAD, HEXDISP

%   Department of Physics
%   University of Aveiro, Portugal

c = zeros(1, 256);
c(abs('0'):abs('9')) = 0:9;
c(abs('a'):abs('f')) = 10:15;
hex = double(s);
bin = 16*c(hex(1:2:end)) + c(hex(2:2:end));
