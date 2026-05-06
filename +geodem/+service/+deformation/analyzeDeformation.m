function result = analyzeDeformation(baseDem, monitorDem, thresholds)
%ANALYZEDEFORMATION Compute monitor DEM minus base DEM and summarize.

if nargin < 3 || isempty(thresholds)
    defaults = geodem.model.ProjectState.defaultParameters();
    thresholds = defaults.thresholds;
end
thresholds = completeThresholds(thresholds);

if ~isequal(size(baseDem.Z), size(monitorDem.Z))
    error('GeoDEM:DemSizeMismatch', 'DEM grids must have the same size.');
end
xMismatch = max(abs(baseDem.XGrid(1, :) - monitorDem.XGrid(1, :)), [], 'omitnan') > 1e-6;
yMismatch = max(abs(baseDem.YGrid(:, 1) - monitorDem.YGrid(:, 1)), [], 'omitnan') > 1e-6;
if xMismatch || yMismatch
    error('GeoDEM:DemGridMismatch', 'DEM grids must use the same coordinates.');
end

deltaZ = monitorDem.Z - baseDem.Z;
valid = isfinite(deltaZ);
classMap = NaN(size(deltaZ));
classMap(valid & deltaZ < thresholds.severeSubsidence) = -3;
classMap(valid & deltaZ >= thresholds.severeSubsidence & deltaZ < thresholds.moderateSubsidence) = -2;
classMap(valid & deltaZ >= thresholds.moderateSubsidence & deltaZ < thresholds.subsidence) = -1;
classMap(valid & deltaZ >= thresholds.subsidence & deltaZ <= thresholds.uplift) = 0;
classMap(valid & deltaZ > thresholds.uplift & deltaZ <= thresholds.minorUplift) = 1;
classMap(valid & deltaZ > thresholds.minorUplift) = 2;

cellArea = baseDem.resolution ^ 2;
dzv = deltaZ(valid);
if isempty(dzv)
    error('GeoDEM:NoValidOverlap', 'DEM difference contains no valid overlapping cells.');
end

subsidence = valid & deltaZ < thresholds.subsidence;
uplift = valid & deltaZ > thresholds.uplift;
stable = valid & deltaZ >= thresholds.subsidence & deltaZ <= thresholds.uplift;

[maxSubsidence, minIdxLinear] = min(deltaZ(:), [], 'omitnan');
[minRow, minCol] = ind2sub(size(deltaZ), minIdxLinear);
maxSubsidencePoint = struct( ...
    'X', baseDem.XGrid(minRow, minCol), ...
    'Y', baseDem.YGrid(minRow, minCol), ...
    'DeltaZ', maxSubsidence, ...
    'BaseDEM', baseDem.Z(minRow, minCol), ...
    'MonitorDEM', monitorDem.Z(minRow, minCol), ...
    'ClassCode', classMap(minRow, minCol), ...
    'Row', minRow, ...
    'Col', minCol);

totalValidArea = sum(valid(:)) * cellArea;
stats = struct( ...
    'MaxSubsidence', min(dzv), ...
    'MaxUplift', max(dzv), ...
    'MeanChange', mean(dzv), ...
    'MedianChange', median(dzv), ...
    'StdChange', std(dzv), ...
    'SubsidenceArea', sum(subsidence(:)) * cellArea, ...
    'UpliftArea', sum(uplift(:)) * cellArea, ...
    'StableArea', sum(stable(:)) * cellArea, ...
    'TotalValidArea', totalValidArea, ...
    'SubsidenceRatio', sum(subsidence(:)) * cellArea / max(totalValidArea, eps), ...
    'UpliftRatio', sum(uplift(:)) * cellArea / max(totalValidArea, eps), ...
    'StableRatio', sum(stable(:)) * cellArea / max(totalValidArea, eps), ...
    'ValidCellCount', sum(valid(:)), ...
    'NanCellCount', sum(~valid(:)));
stats.ClassAreaTable = classAreaTable(classMap, cellArea);

volumeStats = struct( ...
    'SubsidenceVolume', sum(abs(deltaZ(subsidence))) * cellArea, ...
    'UpliftVolume', sum(deltaZ(uplift)) * cellArea, ...
    'NetVolumeChange', sum(dzv) * cellArea);

contours = buildContours(baseDem.XGrid, baseDem.YGrid, deltaZ, thresholds);
result = geodem.model.DeformationResult(baseDem.XGrid, baseDem.YGrid, deltaZ, classMap, stats, contours, maxSubsidencePoint, volumeStats, thresholds, baseDem.resolution);
end

function thresholds = completeThresholds(thresholds)
params = geodem.model.ProjectState.defaultParameters();
defaults = params.thresholds;
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(thresholds, names{i}) || isempty(thresholds.(names{i}))
        thresholds.(names{i}) = defaults.(names{i});
    end
end
if ~isfield(thresholds, 'contourInterval')
    thresholds.contourInterval = 0.10;
end
end

function tbl = classAreaTable(classMap, cellArea)
codes = [-3; -2; -1; 0; 1; 2];
names = ["严重沉降"; "中度沉降"; "轻微沉降"; "稳定"; "轻微抬升"; "明显抬升"];
counts = zeros(size(codes));
areas = zeros(size(codes));
for i = 1:numel(codes)
    counts(i) = sum(classMap(:) == codes(i));
    areas(i) = counts(i) * cellArea;
end
total = max(sum(areas), eps);
ratios = areas ./ total;
tbl = table(codes, names, counts, areas, ratios, 'VariableNames', {'Code','ClassName','CellCount','Area','Ratio'});
end

function contours = buildContours(XGrid, YGrid, deltaZ, thresholds)
valid = isfinite(deltaZ);
if ~any(valid(:))
    contours = struct('Levels', [], 'Lines', []);
    return;
end
interval = thresholds.contourInterval;
if interval <= 0
    interval = 0.10;
end
minDz = min(deltaZ(valid));
maxDz = max(deltaZ(valid));
lower = floor(minDz / interval) * interval;
upper = ceil(maxDz / interval) * interval;
levels = lower:interval:upper;
if numel(levels) < 2
    levels = [minDz, maxDz];
end
xv = XGrid(1, :);
yv = YGrid(:, 1);
C = contourc(xv, yv, deltaZ, levels);
lines = parseContourMatrix(C);
contours = struct('Levels', levels, 'Lines', lines);
end

function lines = parseContourMatrix(C)
lines = struct('Level', {}, 'X', {}, 'Y', {});
col = 1;
while col < size(C, 2)
    level = C(1, col);
    n = C(2, col);
    cols = col + (1:n);
    lines(end + 1) = struct('Level', level, 'X', C(1, cols), 'Y', C(2, cols)); %#ok<AGROW>
    col = col + n + 1;
end
end
