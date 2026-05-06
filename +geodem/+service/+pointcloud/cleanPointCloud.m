function [cleanedCloud, report] = cleanPointCloud(cloud, method, params)
%CLEANPOINTCLOUD Remove elevation outliers using configured strategy.

if nargin < 2 || isempty(method)
    method = 'none';
end
if nargin < 3 || isempty(params)
    params = struct();
end

pts = cloud.points;
z = pts(:, 3);
method = lower(char(method));
keep = true(size(z));
details = struct();

switch method
    case {'none', 'off'}
        details.Description = 'No points removed.';
    case {'sigma', '3sigma', 'std'}
        sigma = geodem.util.getField(params, 'sigma', 3);
        mu = mean(z, 'omitnan');
        sd = std(z, 'omitnan');
        if sd > 0
            keep = abs(z - mu) <= sigma * sd;
        end
        details.Mean = mu;
        details.Std = sd;
        details.Sigma = sigma;
    case {'percentile', 'pct'}
        lowerP = geodem.util.getField(params, 'lowerPercentile', 1);
        upperP = geodem.util.getField(params, 'upperPercentile', 99);
        limits = prctile(z, [lowerP, upperP]);
        keep = z >= limits(1) & z <= limits(2);
        details.LowerPercentile = lowerP;
        details.UpperPercentile = upperP;
        details.ZMin = limits(1);
        details.ZMax = limits(2);
    case {'threshold', 'manual'}
        zMin = geodem.util.getField(params, 'zMin', -Inf);
        zMax = geodem.util.getField(params, 'zMax', Inf);
        keep = z >= zMin & z <= zMax;
        details.ZMin = zMin;
        details.ZMax = zMax;
    otherwise
        error('GeoDEM:UnsupportedCleaningMethod', 'Unsupported cleaning method: %s', method);
end

cleanedCloud = geodem.model.PointCloudData(pts(keep, :), cloud.name, cloud.period, cloud.sourcePath);
cleanedCloud.cleaned = ~strcmp(method, 'none');
cleanedCloud.history = cloud.history;
cleanedCloud.history{end + 1} = sprintf('Cleaned by %s: removed %d of %d points.', method, sum(~keep), numel(keep));

report = struct( ...
    'Method', method, ...
    'OriginalPointCount', numel(keep), ...
    'RemovedPointCount', sum(~keep), ...
    'RemainingPointCount', sum(keep), ...
    'RemovedRatio', sum(~keep) / max(numel(keep), 1), ...
    'Details', details);
cleanedCloud.qualityReport.CleaningReport = report;
end

