function cloud = importPointCloud(filePath, period, progressFcn)
%IMPORTPOINTCLOUD Import CSV/TXT point cloud with X,Y,Z fields.

if nargin < 2
    period = "";
end
if nargin < 3
    progressFcn = [];
end
if ~(ischar(filePath) || isstring(filePath))
    error('GeoDEM:InvalidPath', 'filePath must be a char vector or string.');
end
filePath = char(filePath);
if ~isfile(filePath)
    error('GeoDEM:FileNotFound', 'Point-cloud file not found: %s', filePath);
end

[~, ~, ext] = fileparts(filePath);
if any(strcmpi(ext, {'.las', '.laz'}))
    cloud = geodem.service.io.importLasPointCloud(filePath, period, progressFcn);
    return;
end

notifyProgress(progressFcn, 0.12, "识别字段");
opts = detectImportOptions(filePath, 'FileType', 'text');
if isprop(opts, 'VariableNamingRule')
    opts.VariableNamingRule = 'preserve';
end
notifyProgress(progressFcn, 0.30, "读取表格");
tbl = readtable(filePath, opts);
if isempty(tbl) || height(tbl) == 0
    error('GeoDEM:EmptyPointCloud', 'Point-cloud file is empty: %s', filePath);
end

notifyProgress(progressFcn, 0.62, "检查 XYZ 字段");
names = string(tbl.Properties.VariableNames);
idxX = findColumn(names, "X");
idxY = findColumn(names, "Y");
idxZ = findColumn(names, "Z");
if any([idxX, idxY, idxZ] == 0)
    error('GeoDEM:MissingXYZ', 'Point-cloud file must contain X, Y and Z columns: %s', filePath);
end

notifyProgress(progressFcn, 0.74, "解析坐标");
x = toNumeric(tbl{:, idxX}, 'X');
y = toNumeric(tbl{:, idxY}, 'Y');
z = toNumeric(tbl{:, idxZ}, 'Z');
points = [x(:), y(:), z(:)];
finiteMask = all(isfinite(points), 2);
invalidCount = sum(~finiteMask);
points = points(finiteMask, :);
if isempty(points)
    error('GeoDEM:NoFinitePoints', 'Point-cloud file contains no finite XYZ points: %s', filePath);
end

notifyProgress(progressFcn, 0.88, "生成点云模型");
[~, name, ext] = fileparts(filePath);
cloud = geodem.model.PointCloudData(points, [name ext], period, filePath);
cloud.qualityReport.InvalidInputRows = invalidCount;
if invalidCount > 0
    cloud.history{end + 1} = sprintf('Removed %d invalid input rows during import.', invalidCount);
end
notifyProgress(progressFcn, 1.00, "点云读取完成");
end

function notifyProgress(progressFcn, fraction, message)
if ~isempty(progressFcn)
    try
        progressFcn(fraction, message);
    catch
    end
end
end

function idx = findColumn(names, target)
canon = lower(regexprep(names, '\s+', ''));
target = lower(target);
idx = find(canon == target, 1);
if isempty(idx)
    idx = 0;
end
end

function values = toNumeric(values, colName)
if isnumeric(values)
    values = double(values);
    return;
end
if iscell(values)
    values = string(values);
end
values = str2double(string(values));
if all(isnan(values))
    error('GeoDEM:NonNumericColumn', 'Column %s cannot be converted to numeric values.', colName);
end
end
