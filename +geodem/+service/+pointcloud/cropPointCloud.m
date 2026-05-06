function croppedCloud = cropPointCloud(cloud, extent)
%CROPPOINTCLOUD Crop point cloud to [xmin xmax ymin ymax] extent.

extent = normalizeExtent(extent);
pts = cloud.points;
mask = pts(:, 1) >= extent(1) & pts(:, 1) <= extent(2) & ...
       pts(:, 2) >= extent(3) & pts(:, 2) <= extent(4);
croppedCloud = geodem.model.PointCloudData(pts(mask, :), cloud.name, cloud.period, cloud.sourcePath);
croppedCloud.cleaned = cloud.cleaned;
croppedCloud.history = cloud.history;
croppedCloud.history{end + 1} = sprintf('Cropped to common extent: %.3f %.3f %.3f %.3f.', extent(1), extent(2), extent(3), extent(4));
end

function extent = normalizeExtent(extent)
if isstruct(extent)
    extent = [extent.XMin, extent.XMax, extent.YMin, extent.YMax];
end
if numel(extent) ~= 4
    error('GeoDEM:InvalidExtent', 'Extent must be [xmin xmax ymin ymax].');
end
extent = double(extent(:)');
if extent(1) >= extent(2) || extent(3) >= extent(4)
    error('GeoDEM:InvalidExtent', 'Extent has no positive area.');
end
end
