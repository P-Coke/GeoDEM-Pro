function [extent, cloudACommon, cloudBCommon] = extractCommonExtent(cloudA, cloudB)
%EXTRACTCOMMONEXTENT Compute and crop to the overlapping XY extent.

xmin = max(cloudA.bounds.XMin, cloudB.bounds.XMin);
xmax = min(cloudA.bounds.XMax, cloudB.bounds.XMax);
ymin = max(cloudA.bounds.YMin, cloudB.bounds.YMin);
ymax = min(cloudA.bounds.YMax, cloudB.bounds.YMax);

if xmin >= xmax || ymin >= ymax
    error('GeoDEM:NoCommonExtent', 'The two point clouds have no common XY coverage.');
end

extent = struct( ...
    'XMin', xmin, 'XMax', xmax, ...
    'YMin', ymin, 'YMax', ymax, ...
    'Width', xmax - xmin, ...
    'Height', ymax - ymin, ...
    'Area', (xmax - xmin) * (ymax - ymin));

cloudACommon = geodem.service.pointcloud.cropPointCloud(cloudA, extent);
cloudBCommon = geodem.service.pointcloud.cropPointCloud(cloudB, extent);
areaA = max(cloudA.bounds.Width * cloudA.bounds.Height, eps);
areaB = max(cloudB.bounds.Width * cloudB.bounds.Height, eps);
unionArea = max(areaA + areaB - extent.Area, eps);
extent.AreaA = areaA;
extent.AreaB = areaB;
extent.UnionArea = unionArea;
extent.CoverageRatioA = extent.Area / areaA;
extent.CoverageRatioB = extent.Area / areaB;
extent.CommonCoverageRatio = extent.Area / unionArea;
extent.PointRetentionA = size(cloudACommon.points, 1) / max(size(cloudA.points, 1), 1);
extent.PointRetentionB = size(cloudBCommon.points, 1) / max(size(cloudB.points, 1), 1);
extent.PointCountA = size(cloudACommon.points, 1);
extent.PointCountB = size(cloudBCommon.points, 1);
end
