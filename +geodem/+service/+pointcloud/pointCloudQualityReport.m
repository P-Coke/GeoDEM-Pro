function report = pointCloudQualityReport(cloud, options)
%POINTCLOUDQUALITYREPORT Build a point-cloud quality inspection table.

if nargin < 2 || isempty(options)
    options = struct();
end
cellSize = geodem.util.getField(options, 'cellSize', 5.0);
sigma = geodem.util.getField(options, 'sigma', 3.0);

pts = cloud.points;
if isempty(pts) || size(pts, 2) < 3
    error('GeoDEM:EmptyPointCloud', '点云为空或不包含 X/Y/Z 字段。');
end
z = pts(:, 3);
b = cloud.bounds;
area = max(b.Width * b.Height, eps);
density = size(pts, 1) / area;
mu = mean(z, 'omitnan');
sd = std(z, 'omitnan');
sigmaOutliers = abs(z - mu) > sigma * max(sd, eps);
pct = prctile(z, [1 99]);
pctOutliers = z < pct(1) | z > pct(2);

densityGrid = geodem.service.pointcloud.computeDensityGrid(cloud, cellSize, b);
emptyCellCount = sum(densityGrid.Counts(:) == 0);
nonzero = densityGrid.Density(densityGrid.Counts > 0);
if isempty(nonzero)
    lowDensityCellCount = emptyCellCount;
    lowDensityThreshold = NaN;
else
    lowDensityThreshold = 0.25 * median(nonzero, 'omitnan');
    lowDensityCellCount = sum(densityGrid.Density(:) > 0 & densityGrid.Density(:) < lowDensityThreshold);
end
emptyRatio = emptyCellCount / max(numel(densityGrid.Counts), 1);

recommendedResolution = recommendResolution(density);
items = [
    "点云名称"
    "点数"
    "X 范围"
    "Y 范围"
    "Z 范围"
    "平均高程"
    "高程标准差"
    "点云密度"
    "3σ 异常点"
    "1%-99% 百分位异常点"
    "空洞网格数"
    "空洞网格比例"
    "低密度网格数"
    "推荐网格分辨率"
    "推荐插值方法"
    ];
values = [
    string(cloud.name)
    string(size(pts, 1))
    sprintf('%.3f - %.3f m', b.XMin, b.XMax)
    sprintf('%.3f - %.3f m', b.YMin, b.YMax)
    sprintf('%.3f - %.3f m', b.ZMin, b.ZMax)
    sprintf('%.3f m', mu)
    sprintf('%.3f m', sd)
    sprintf('%.4f 点/m²', density)
    sprintf('%d (%.2f%%)', sum(sigmaOutliers), 100 * mean(sigmaOutliers))
    sprintf('%d (%.2f%%)', sum(pctOutliers), 100 * mean(pctOutliers))
    string(emptyCellCount)
    sprintf('%.2f%%', 100 * emptyRatio)
    sprintf('%d，阈值 %.4f 点/m²', lowDensityCellCount, lowDensityThreshold)
    sprintf('%.2f m', recommendedResolution)
    recommendedInterpolation(density, emptyRatio)
    ];
report = table(items, values, 'VariableNames', {'指标','值'});
end


function resolution = recommendResolution(density)
if density >= 4
    resolution = 0.25;
elseif density >= 1
    resolution = 0.5;
else
    resolution = 1.0;
end
end

function method = recommendedInterpolation(density, emptyRatio)
if emptyRatio > 0.25
    method = "natural";
elseif density >= 2
    method = "natural";
elseif density >= 0.5
    method = "linear";
else
    method = "nearest";
end
end
