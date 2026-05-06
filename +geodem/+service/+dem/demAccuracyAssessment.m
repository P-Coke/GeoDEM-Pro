function metrics = demAccuracyAssessment(cloud, options)
%DEMACCURACYASSESSMENT Cross-validate DEM interpolation against held-out points.

if nargin < 2 || isempty(options)
    options = struct();
end
resolution = geodem.util.getField(options, 'resolution', 1.0);
method = char(geodem.util.getField(options, 'method', 'natural'));
validationRatio = geodem.util.getField(options, 'validationRatio', 0.10);
maxValidation = round(geodem.util.getField(options, 'maxValidation', 5000));
maxTrain = round(geodem.util.getField(options, 'maxTrain', 80000));
seed = round(geodem.util.getField(options, 'seed', 42));

pts = cloud.points;
pts = pts(all(isfinite(pts(:, 1:3)), 2), :);
n = size(pts, 1);
if n < 20
    error('GeoDEM:TooFewValidationPoints', 'DEM 精度评价至少需要 20 个有效点。');
end

rng(seed, 'twister');
order = randperm(n);
nVal = min(maxValidation, max(5, round(n * validationRatio)));
nVal = min(nVal, n - 5);
validationIdx = order(1:nVal);
trainIdx = order(nVal + 1:end);
if numel(trainIdx) > maxTrain
    trainIdx = trainIdx(randperm(numel(trainIdx), maxTrain));
end

trainCloud = geodem.model.PointCloudData(pts(trainIdx, :), [cloud.name ' 训练样本'], cloud.period, cloud.sourcePath);
dem = geodem.service.dem.buildDem(trainCloud, struct('extent', cloud.bounds, 'resolution', resolution, 'holeFill', struct('enabled', false)), method, struct('enabled', false));
val = pts(validationIdx, :);
pred = interp2(dem.XGrid, dem.YGrid, dem.Z, val(:, 1), val(:, 2), 'linear', NaN);
err = pred - val(:, 3);
valid = isfinite(err);
if ~any(valid)
    error('GeoDEM:NoValidValidationPrediction', '验证点均未落入有效 DEM 区域。');
end
e = err(valid);

metrics = table( ...
    string(method), resolution, n, numel(trainIdx), nVal, sum(valid), ...
    mean(abs(e)), sqrt(mean(e .^ 2)), mean(e), std(e), 1 - sum(valid) / max(nVal, 1), ...
    dem.qualityMetrics.NanRatio, ...
    'VariableNames', {'Method','Resolution','TotalPoints','TrainPoints','ValidationPoints','ValidPredictions','MAE','RMSE','ME','STD','InvalidPredictionRatio','DemNanRatio'});
end

