function [hex,theSize] = hexconvert(theStr,nChars)
%HEXFREAD   Convert string to hexadecimal
%   Returns the string converted to hexadecimal and in a
%   matrice with a desired number of columns.
%
%   Syntax:
%      [HEX,SIZE] = HEXFREAD(STR,COLS)
%
%   Inputs:
%      STR
%      COLS   Number of columns of the output matrice [ 70 ]
%
%   Outputs:
%      HEX    Matrice with the FILE elements converted to hexadecimal
%      SIZE   The number of elements in FILE
%
%   Comment:
%      The size of HEX will be >= 2*SIZE, sice the last line of the matrice
%      may have spaces to fill COLS
%
%   Examples:
%      [hex,s] = hexconvert(fread('file.txt'));
%      [hex,s] = hexconvert('some string');
%
%   MMA 05-03-2007, martinho@fis.ua.pt
%
%   See also HEXFREAD, HEXDISP

%   Department of Physics
%   University of Aveiro, Portugal

hex     = [];
theSize = [];

if nargin < 2
  nChars = 70;
end

c = theStr;
theSize=prod(size((c)));
c=sprintf('%02x\n',c);
c(3:3:end)='';
m=floor(length(c)/nChars);
hex='';
hex=reshape(c(1:m*nChars),nChars,m)';
if mod(length(c),nChars)
 hex=strvcat(hex,c(m*nChars+1:end));
end
