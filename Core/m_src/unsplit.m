function st = unsplit(c)
% unsplit convert a cell c of string into a unique string with comma
% separated elements from c

st= c{1};
for ic = 2:numel(c)
    st = [st ',' c{ic}];
end

end