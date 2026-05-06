function comparison = compareInterpolationMethods(baseCloud, monitorCloud, gridSpec, methods, smoothSpec, thresholds)
%COMPAREINTERPOLATIONMETHODS Build/analyze DEMs with several methods.

if nargin < 4 || isempty(methods)
    methods = {'nearest', 'linear', 'natural'};
end
if isstring(methods)
    methods = cellstr(methods);
end
if nargin < 5
    smoothSpec = struct('enabled', false);
end
if nargin < 6
    params = geodem.model.ProjectState.defaultParameters();
    thresholds = params.thresholds;
end

rows = table();
results = struct();
for i = 1:numel(methods)
    method = methods{i};
    baseDem = geodem.service.dem.buildDem(baseCloud, gridSpec, method, smoothSpec);
    monitorDem = geodem.service.dem.buildDem(monitorCloud, gridSpec, method, smoothSpec);
    result = geodem.service.deformation.analyzeDeformation(baseDem, monitorDem, thresholds);
    s = result.stats;
    v = result.volumeStats;
    row = table(string(method), s.MaxSubsidence, s.MaxUplift, s.MeanChange, ...
        s.SubsidenceArea, s.UpliftArea, s.StableRatio, ...
        v.SubsidenceVolume, v.UpliftVolume, v.NetVolumeChange, ...
        'VariableNames', {'Method','MaxSubsidence','MaxUplift','MeanChange', ...
        'SubsidenceArea','UpliftArea','StableRatio','SubsidenceVolume','UpliftVolume','NetVolumeChange'});
    rows = [rows; row]; %#ok<AGROW>
    results.(matlab.lang.makeValidName(method)) = struct('BaseDEM', baseDem, 'MonitorDEM', monitorDem, 'Result', result);
end
comparison = struct('Summary', rows, 'Results', results);
end
