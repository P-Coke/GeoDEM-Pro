function dem = importDemRaster(filePath, name)
%IMPORTDEMRASTER Import a DEM raster using MATLAB-native readers.

if nargin < 2 || strlength(string(name)) == 0
    [~, name] = fileparts(filePath);
end
filePath = char(filePath);
if ~isfile(filePath)
    error('GeoDEM:DemFileNotFound', 'DEM 文件不存在：%s', filePath);
end

[~, ~, ext] = fileparts(filePath);
ext = lower(ext);
switch ext
    case {'.tif', '.tiff'}
        [Z, R] = readGeoRasterNative(filePath);
        [XGrid, YGrid, resolution] = gridFromSpatialRef(R, size(Z));
        method = 'import_geotiff';
    case '.mat'
        [Z, XGrid, YGrid, resolution, method] = readMatDem(filePath);
    otherwise
        M = readmatrix(filePath);
        [Z, XGrid, YGrid, resolution] = matrixToGrid(M);
        method = 'import_matrix';
end

dem = geodem.model.DemRaster(XGrid, YGrid, Z, resolution, method, name);
end

function [Z, R] = readGeoRasterNative(filePath)
try
    [A, R] = geodem.compat.readGeoRaster(filePath);
catch ME
    error('GeoDEM:ReadGeoRasterFailed', '无法读取 GeoTIFF：%s。%s', filePath, ME.message);
end
if ndims(A) > 2
    A = A(:, :, 1);
end
Z = double(A);
Z(~isfinite(Z)) = NaN;
try
    missing = R.MissingDataIndicator;
    Z(Z == double(missing)) = NaN;
catch
end
end

function [Z, XGrid, YGrid, resolution, method] = readMatDem(filePath)
data = load(filePath);
names = fieldnames(data);
if isempty(names)
    error('GeoDEM:EmptyMatDem', 'MAT 文件中没有可导入的 DEM 变量。');
end
for i = 1:numel(names)
    value = data.(names{i});
    if isa(value, 'geodem.model.DemRaster')
        Z = value.Z;
        XGrid = value.XGrid;
        YGrid = value.YGrid;
        resolution = value.resolution;
        method = 'import_mat_dem';
        return;
    end
end
if isfield(data, 'Z')
    Z = double(data.Z);
else
    firstNumeric = "";
    for i = 1:numel(names)
        if isnumeric(data.(names{i})) && ismatrix(data.(names{i}))
            firstNumeric = names{i};
            break;
        end
    end
    if strlength(firstNumeric) == 0
        error('GeoDEM:NoNumericDemMatrix', 'MAT 文件中没有二维数值矩阵或 DemRaster。');
    end
    Z = double(data.(char(firstNumeric)));
end
if isfield(data, 'XGrid') && isfield(data, 'YGrid')
    XGrid = double(data.XGrid);
    YGrid = double(data.YGrid);
    resolution = inferResolution(XGrid, YGrid);
else
    [Z, XGrid, YGrid, resolution] = matrixToGrid(Z);
end
method = 'import_mat';
end

function [Z, XGrid, YGrid, resolution] = matrixToGrid(M)
M = double(M);
if isempty(M) || all(size(M) == 0)
    error('GeoDEM:EmptyDemMatrix', 'DEM 矩阵为空。');
end
if size(M, 2) == 3 && size(M, 1) > 3
    x = unique(M(:, 1));
    y = unique(M(:, 2));
    [XGrid, YGrid] = meshgrid(x, y);
    Z = griddata(M(:, 1), M(:, 2), M(:, 3), XGrid, YGrid, 'linear');
else
    Z = M;
    [XGrid, YGrid] = meshgrid(1:size(Z, 2), 1:size(Z, 1));
end
Z(~isfinite(Z)) = NaN;
resolution = inferResolution(XGrid, YGrid);
end

function [XGrid, YGrid, resolution] = gridFromSpatialRef(R, rasterSize)
rows = rasterSize(1);
cols = rasterSize(2);
if isnumeric(R)
    try
        [x, y] = pixcenters(R, rows, cols);
        [XGrid, YGrid] = meshgrid(double(x), double(y));
        resolution = inferResolution(XGrid, YGrid);
        return;
    catch
    end
end
try
    xlim = R.XWorldLimits;
    ylim = R.YWorldLimits;
catch
    try
        xlim = R.LongitudeLimits;
        ylim = R.LatitudeLimits;
    catch
        xlim = [1 cols];
        ylim = [1 rows];
    end
end
dx = diff(xlim) / max(cols, 1);
dy = diff(ylim) / max(rows, 1);
x = linspace(xlim(1) + dx / 2, xlim(2) - dx / 2, cols);
y = linspace(ylim(1) + dy / 2, ylim(2) - dy / 2, rows);
[XGrid, YGrid] = meshgrid(x, y);
resolution = inferResolution(XGrid, YGrid);
end

function resolution = inferResolution(XGrid, YGrid)
dx = median(abs(diff(XGrid(1, :))), 'omitnan');
dy = median(abs(diff(YGrid(:, 1))), 'omitnan');
resolution = mean([dx dy], 'omitnan');
if ~isfinite(resolution) || resolution <= 0
    resolution = 1;
end
end
