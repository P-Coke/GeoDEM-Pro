function density = computeDensityGrid(cloud, resolution, extent)
%COMPUTEDENSITYGRID Count points per grid cell and per square metre.

if nargin < 2 || isempty(resolution)
    resolution = 1.0;
end
if nargin < 3 || isempty(extent)
    extent = cloud.bounds;
end
extent = normalizeExtent(extent);
if resolution <= 0
    error('GeoDEM:InvalidResolution', 'Density resolution must be positive.');
end

pts = cloud.points;
xEdges = extent(1):resolution:extent(2);
yEdges = extent(3):resolution:extent(4);
if xEdges(end) < extent(2)
    xEdges(end + 1) = extent(2);
end
if yEdges(end) < extent(4)
    yEdges(end + 1) = extent(4);
end

xBin = discretize(pts(:, 1), xEdges);
yBin = discretize(pts(:, 2), yEdges);
valid = isfinite(xBin) & isfinite(yBin);
ny = numel(yEdges) - 1;
nx = numel(xEdges) - 1;
counts = accumarray([yBin(valid), xBin(valid)], 1, [ny, nx], @sum, 0);
xCenters = xEdges(1:end-1) + diff(xEdges) / 2;
yCenters = yEdges(1:end-1) + diff(yEdges) / 2;
[XGrid, YGrid] = meshgrid(xCenters, yCenters);

density = struct( ...
    'XGrid', XGrid, ...
    'YGrid', YGrid, ...
    'Counts', counts, ...
    'Density', counts ./ (resolution ^ 2), ...
    'Resolution', resolution, ...
    'MeanDensity', mean(counts(:) ./ (resolution ^ 2)), ...
    'MaxDensity', max(counts(:) ./ (resolution ^ 2)), ...
    'EmptyCellRatio', sum(counts(:) == 0) / max(numel(counts), 1));
end

function extent = normalizeExtent(extent)
if isstruct(extent)
    extent = [extent.XMin, extent.XMax, extent.YMin, extent.YMax];
end
extent = double(extent(:)');
if numel(extent) ~= 4 || extent(1) >= extent(2) || extent(3) >= extent(4)
    error('GeoDEM:InvalidExtent', 'Extent must be [xmin xmax ymin ymax] with positive area.');
end
end
