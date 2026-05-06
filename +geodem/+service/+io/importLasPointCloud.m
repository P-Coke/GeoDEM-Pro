function cloud = importLasPointCloud(filePath, period, progressFcn)
%IMPORTLASPOINTCLOUD Import LAS/LAZ point cloud using Lidar Toolbox.

if nargin < 2
    period = "";
end
if nargin < 3
    progressFcn = [];
end
filePath = char(filePath);
if ~isfile(filePath)
    error('GeoDEM:FileNotFound', 'LAS/LAZ file not found: %s', filePath);
end
if exist('lasFileReader', 'file') ~= 2
    error('GeoDEM:MissingLidarToolbox', ...
        ['当前 MATLAB 版本或工具箱不支持 lasFileReader，R2019b 不能直接导入 LAS/LAZ。' ...
         '请改用 CSV/TXT 点云，或在 R2020b+ 并启用 Lidar Toolbox 后再导入 LAS/LAZ。']);
end

notifyProgress(progressFcn, 0.18, "打开 LAS/LAZ");
reader = lasFileReader(filePath);
notifyProgress(progressFcn, 0.42, "读取点云");
ptCloud = readPointCloud(reader);
notifyProgress(progressFcn, 0.70, "解析坐标");
locations = double(ptCloud.Location);
points = reshape(locations, [], 3);
finiteMask = all(isfinite(points), 2);
points = points(finiteMask, :);
if isempty(points)
    error('GeoDEM:NoFinitePoints', 'LAS/LAZ file contains no finite XYZ points: %s', filePath);
end

notifyProgress(progressFcn, 0.88, "生成点云模型");
[~, name, ext] = fileparts(filePath);
cloud = geodem.model.PointCloudData(points, [name ext], period, filePath);
cloud.qualityReport.InvalidInputRows = sum(~finiteMask);
cloud.history{end + 1} = sprintf('Imported LAS/LAZ file with %d finite points.', size(points, 1));
notifyProgress(progressFcn, 1.00, "LAS/LAZ 读取完成");
end

function notifyProgress(progressFcn, fraction, message)
if ~isempty(progressFcn)
    try
        progressFcn(fraction, message);
    catch
    end
end
end
