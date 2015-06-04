function [ fullpath ] = join(names, filepathsep)
%JOIN os.path.join(filesep, 'some', 'path')
if nargin < 2
    filepathsep = filesep
end

f = names{1};
for iName=2:numel(names)
   part = names{iName};
   if isempty(f) || isempty(part)
      f = [f part]; %#ok<AGROW>
   else      
      if (f(end)==filepathsep) && (part(1)==filepathsep),
         f = [f part(2:end)]; %#ok<AGROW>
      elseif (f(end)==filepathsep) || (part(1)==filepathsep)
         f = [f part]; %#ok<AGROW>
      else
         f = [f filepathsep part]; %#ok<AGROW>
      end
   end
end

f = strrep(f, '/', filepathsep);
fullpath = strrep(f, '\', filepathsep);

end