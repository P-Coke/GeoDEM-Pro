function dem = buildDem(cloud, gridSpec, method, smoothSpec)
%BUILDDEM Interpolate a point cloud onto a regular DEM grid.

if nargin < 2 || isempty(gridSpec)
    gridSpec = struct('extent', cloud.bounds, 'resolution', 0.5);
end
if nargin < 3 || isempty(method)
    method = 'natural';
end
if nargin < 4 || isempty(smoothSpec)
    smoothSpec = struct('enabled', false, 'method', 'none', 'window', 3);
end

resolution = geodem.util.getField(gridSpec, 'resolution', 0.5);
if resolution <= 0
    error('GeoDEM:InvalidResolution', 'DEM grid resolution must be positive.');
end
extent = geodem.util.getField(gridSpec, 'extent', cloud.bounds);
extent = normalizeExtent(extent);
method = lower(char(method));

xv = extent(1):resolution:extent(2);
yv = extent(3):resolution:extent(4);
if xv(end) < extent(2)
    xv(end + 1) = extent(2);
end
if yv(end) < extent(4)
    yv(end + 1) = extent(4);
end
[XGrid, YGrid] = meshgrid(xv, yv);

pts = cloud.points;
inside = pts(:, 1) >= extent(1) & pts(:, 1) <= extent(2) & ...
         pts(:, 2) >= extent(3) & pts(:, 2) <= extent(4);
pts = pts(inside, :);
if size(pts, 1) < 3
    error('GeoDEM:TooFewPoints', 'At least 3 points are required to build a DEM.');
end

switch method
    case {'nearest', 'linear', 'natural'}
        interpolant = scatteredInterpolant(pts(:, 1), pts(:, 2), pts(:, 3), method, 'none');
        Z = interpolant(XGrid, YGrid);
    case {'idw', 'inverse_distance', 'inversedistance'}
        Z = idwInterpolate(pts, XGrid, YGrid, 12, 2);
    case {'cubic', 'v4'}
        Z = griddata(pts(:, 1), pts(:, 2), pts(:, 3), XGrid, YGrid, method);
    otherwise
        error('GeoDEM:UnsupportedInterpolationMethod', 'Unsupported interpolation method: %s', method);
end

holeFill = geodem.util.getField(gridSpec, 'holeFill', struct('enabled', false));
if isstruct(holeFill) && geodem.util.getField(holeFill, 'enabled', false)
    Z = fillSmallHoles(Z, geodem.util.getField(holeFill, 'maxIterations', 2));
end

if isstruct(smoothSpec) && geodem.util.getField(smoothSpec, 'enabled', false)
    Z = smoothRaster(Z, geodem.util.getField(smoothSpec, 'method', 'mean'), geodem.util.getField(smoothSpec, 'window', 3));
end

name = sprintf('%s DEM', cloud.period);
dem = geodem.model.DemRaster(XGrid, YGrid, Z, resolution, method, name);
end

function Z = idwInterpolate(pts, XGrid, YGrid, k, powerValue)
query = [XGrid(:), YGrid(:)];
k = min(k, size(pts, 1));
Z = nan(size(query, 1), 1);
chunkSize = 50000;
if exist('knnsearch', 'file') == 2
    xy = pts(:, 1:2);
    z = pts(:, 3);
    for startIdx = 1:chunkSize:size(query, 1)
        stopIdx = min(size(query, 1), startIdx + chunkSize - 1);
        [idx, dist] = knnsearch(xy, query(startIdx:stopIdx, :), 'K', k);
        Z(startIdx:stopIdx) = idwValues(z, idx, dist, powerValue);
    end
else
    work = size(query, 1) * size(pts, 1);
    if work > 5e7
        error('GeoDEM:IDWNeedsKnnsearch', 'IDW 插值需要 Statistics and Machine Learning Toolbox 的 knnsearch，或使用更粗分辨率。');
    end
    for i = 1:size(query, 1)
        dist = hypot(pts(:, 1) - query(i, 1), pts(:, 2) - query(i, 2));
        [dist, order] = sort(dist, 'ascend');
        idx = order(1:k)';
        Z(i) = idwValues(pts(:, 3), idx, dist(1:k)', powerValue);
    end
end
Z = reshape(Z, size(XGrid));
end

function values = idwValues(z, idx, dist, powerValue)
values = nan(size(idx, 1), 1);
exact = dist <= eps;
if any(exact(:))
    [exactRows, exactCols] = find(exact);
    [rows, firstIdx] = unique(exactRows, 'stable');
    cols = exactCols(firstIdx);
    values(rows) = z(idx(sub2ind(size(idx), rows, cols)));
end
rows = ~isfinite(values);
if any(rows)
    d = dist(rows, :);
    w = 1 ./ max(d, eps) .^ powerValue;
    vals = z(idx(rows, :));
    values(rows) = sum(w .* vals, 2) ./ sum(w, 2);
end
end

function Z = smoothRaster(Z, method, windowSize)
windowSize = max(1, round(windowSize));
if mod(windowSize, 2) == 0
    windowSize = windowSize + 1;
end
method = lower(char(method));
switch method
    case {'none', 'off'}
        return;
    case {'mean', 'average'}
        W = ones(windowSize, windowSize);
        valid = isfinite(Z);
        numerator = conv2(replaceNaN(Z, 0), W, 'same');
        denominator = conv2(double(valid), W, 'same');
        out = numerator ./ denominator;
        out(denominator == 0) = NaN;
        Z = out;
    case {'median', 'med'}
        Z = movmedian(Z, windowSize, 1, 'omitnan', 'Endpoints', 'shrink');
        Z = movmedian(Z, windowSize, 2, 'omitnan', 'Endpoints', 'shrink');
    otherwise
        error('GeoDEM:UnsupportedSmoothingMethod', 'Unsupported smoothing method: %s', method);
end
end

function Z = fillSmallHoles(Z, maxIterations)
maxIterations = max(0, round(maxIterations));
for k = 1:maxIterations
    nanMask = ~isfinite(Z);
    if ~any(nanMask(:))
        return;
    end
    W = ones(3, 3);
    valid = isfinite(Z);
    numerator = conv2(replaceNaN(Z, 0), W, 'same');
    denominator = conv2(double(valid), W, 'same');
    filled = numerator ./ denominator;
    canFill = nanMask & denominator >= 4;
    Z(canFill) = filled(canFill);
end
end

function A = replaceNaN(A, value)
A(~isfinite(A)) = value;
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
