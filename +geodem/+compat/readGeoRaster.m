function [A, R] = readGeoRaster(filePath)
%READGEORASTER Read GeoTIFF raster data across MATLAB releases.

filePath = char(filePath);
if exist('readgeoraster', 'file') == 2
    [A, R] = readgeoraster(filePath);
elseif exist('geotiffread', 'file') == 2
    [A, R] = geotiffread(filePath);
else
    error('GeoDEM:GeoTiffReaderUnavailable', ...
        '当前 MATLAB 缺少 readgeoraster/geotiffread，无法读取 GeoTIFF：%s', filePath);
end
end
