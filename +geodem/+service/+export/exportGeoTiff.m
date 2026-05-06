function filePath = exportGeoTiff(raster, spatialRef, filePath)
%EXPORTGEOTIFF Export a DEM or deformation raster as GeoTIFF.

if nargin < 2 || isempty(spatialRef)
    spatialRef = geodem.model.SpatialReference();
end
if nargin < 3 || isempty(filePath)
    filePath = fullfile(pwd, 'geodem_export.tif');
end
filePath = char(filePath);
folder = fileparts(filePath);
if ~isempty(folder) && ~exist(folder, 'dir')
    mkdir(folder);
end

[Z, XGrid, YGrid] = extractRaster(raster);
if isempty(Z)
    error('GeoDEM:EmptyRaster', 'No raster data available for GeoTIFF export.');
end

A = flipud(Z);
xLimits = [min(XGrid(:)), max(XGrid(:))];
yLimits = [min(YGrid(:)), max(YGrid(:))];
R = maprefcells(xLimits, yLimits, size(A), 'ColumnsStartFrom', 'north', 'RowsStartFrom', 'west');

if isa(spatialRef, 'geodem.model.SpatialReference') && spatialRef.hasEpsg()
    try
        geotiffwrite(filePath, A, R, 'CoordRefSysCode', round(spatialRef.epsgCode));
    catch
        geotiffwrite(filePath, A, R);
    end
else
    key.GTModelTypeGeoKey = 1;       % Projected coordinate system
    key.GTRasterTypeGeoKey = 1;      % PixelIsArea
    key.ProjectedCSTypeGeoKey = 32767; % User-defined projected CRS
    key.ProjLinearUnitsGeoKey = 9001;  % metre
    geotiffwrite(filePath, A, R, 'GeoKeyDirectoryTag', key);
end
end

function [Z, XGrid, YGrid] = extractRaster(raster)
if isa(raster, 'geodem.model.DemRaster')
    Z = raster.Z;
    XGrid = raster.XGrid;
    YGrid = raster.YGrid;
elseif isa(raster, 'geodem.model.DeformationResult')
    Z = raster.deltaZ;
    XGrid = raster.XGrid;
    YGrid = raster.YGrid;
elseif isstruct(raster) && all(isfield(raster, {'Z','XGrid','YGrid'}))
    Z = raster.Z;
    XGrid = raster.XGrid;
    YGrid = raster.YGrid;
elseif isstruct(raster) && all(isfield(raster, {'deltaZ','XGrid','YGrid'}))
    Z = raster.deltaZ;
    XGrid = raster.XGrid;
    YGrid = raster.YGrid;
else
    error('GeoDEM:UnsupportedRaster', 'Unsupported raster object for GeoTIFF export.');
end
end
