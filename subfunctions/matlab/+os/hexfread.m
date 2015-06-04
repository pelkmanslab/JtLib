function [hex,theSize] = hexfread(theFile,nChars)
%HEXFREAD   Read binary files as hexadecimal
%   Returns the file elements converted to hexadecimal and in a
%   matrice with a desired number of columns.
%
%   Syntax:
%      [HEX,SIZE] = HEXFREAD(FILE,COLS)
%
%   Inputs:
%      FILE
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
%   Example:
%      [hex,s] = hexfread('file.txt');
%
%   MMA 18-09-2005, martinho@fis.ua.pt
%
%   See also HEXDISP

%   Department of Physics
%   University of Aveiro, Portugal

hex     = [];
theSize = [];

if nargin < 2
  nChars = 70;
end

f = fopen(theFile);
if f==-1
  return
end
c = fread(f);
theSize=prod(size((c)));
c=sprintf('%02x\n',c);
c(3:3:end)='';
m=floor(length(c)/nChars);
hex='';
hex=reshape(c(1:m*nChars),nChars,m)';
if mod(length(c),nChars)
 hex=strvcat(hex,c(m*nChars+1:end));
end
