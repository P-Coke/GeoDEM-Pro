function uri = localPngDataUri(pathValue)
%LOCALPNGDATURI Encode a local PNG as a data URI for R2019b uihtml.

pathValue = char(pathValue);
pathKey = lower(pathValue);
persistent cache
if isempty(cache)
    cache = containers.Map('KeyType', 'char', 'ValueType', 'char');
elseif isKey(cache, pathKey)
    uri = cache(pathKey);
    return;
end

uri = "";
fid = fopen(pathValue, 'rb');
if fid < 0
    return;
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
bytes = fread(fid, Inf, '*uint8')';
if isempty(bytes)
    return;
end
uri = ['data:image/png;base64,' char(matlab.net.base64encode(bytes))];
cache(pathKey) = uri;
end
