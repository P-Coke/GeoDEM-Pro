function project = runAnalysisWorkflow(basePath, monitorPath, options)
%RUNANALYSISWORKFLOW Headless wrapper for the tool-based analysis workflow.

if nargin < 1 || isempty(basePath)
    basePath = fullfile(pwd, 'testdata', 'cloud_merged_6.csv');
end
if nargin < 2 || isempty(monitorPath)
    monitorPath = fullfile(pwd, 'testdata', 'cloud_merged_12.csv');
end
if nargin < 3 || isempty(options)
    options = struct();
end

projectRoot = geodem.util.getField(options, 'projectRoot', pwd);
project = geodem.model.ProjectState(projectRoot);
project.outputDir = geodem.util.getField(options, 'outputDir', project.outputDir);
if ~exist(project.outputDir, 'dir')
    mkdir(project.outputDir);
end

params = geodem.model.ProjectState.defaultParameters();
project.parameters = mergeStruct(params, options);
if isfield(project.parameters, 'spatialReference')
    sr = project.parameters.spatialReference;
    if isfield(sr, 'epsgCode') && ~isempty(sr.epsgCode) && isfinite(sr.epsgCode) && sr.epsgCode > 0
        project.spatialReference = geodem.model.SpatialReference(sr.epsgCode, sprintf('EPSG:%d', round(sr.epsgCode)), geodem.util.getField(sr, 'unit', 'meter'), geodem.util.getField(sr, 'isProjected', true), '用户指定 EPSG。');
    end
end

project.addLog('开始工具化 DEM 形变分析。');
baseCloud = geodem.service.io.importPointCloud(basePath, fileStem(basePath));
monitorCloud = geodem.service.io.importPointCloud(monitorPath, fileStem(monitorPath));
baseLayer = project.addCloud(baseCloud, true);
monitorLayer = project.addCloud(monitorCloud, false);
project.addLog(sprintf('导入点云图层 "%s" 与 "%s"。', baseLayer, monitorLayer));

toolParams = struct( ...
    'baseLayer', string(baseLayer), ...
    'monitorLayer', string(monitorLayer), ...
    'resolution', geodem.util.getField(project.parameters, 'gridResolution', 0.5), ...
    'method', string(geodem.util.getField(project.parameters, 'interpolationMethod', 'natural')), ...
    'cleanMethod', string(project.parameters.cleaning.method), ...
    'subsidence', project.parameters.thresholds.subsidence, ...
    'uplift', project.parameters.thresholds.uplift, ...
    'contourInterval', geodem.util.getField(project.parameters, 'contourInterval', 0.10), ...
    'outputPrefix', string(geodem.util.getField(options, 'outputPrefix', 'DEM 差值图')));

spec = geodem.tool.ToolRegistry.get("workflow_analysis");
ctx = geodem.tool.ToolContext(project, projectRoot, project.outputDir, project.activeLayer, project.layers.Name(project.layers.Visible), @(msg) project.addLog(msg));
startTime = datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat);
timer = tic;
result = spec.execute(ctx, toolParams);
duration = toc(timer);
endTime = datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat);
record = geodem.model.ToolExecutionRecord(spec.Id, spec.Name, "完成", string(startTime), string(endTime), duration, toolParams, ...
    [string(baseLayer); string(monitorLayer)], result.OutputLayers, result.Messages, "");
project.recordToolExecution(record);
for i = 1:numel(result.Messages)
    project.addLog(result.Messages(i));
end
end

function stem = fileStem(filePath)
[~, name, ext] = fileparts(filePath);
stem = [name ext];
end

function out = mergeStruct(base, override)
out = base;
if ~isstruct(override)
    return;
end
names = fieldnames(override);
for i = 1:numel(names)
    name = names{i};
    if isfield(out, name) && isstruct(out.(name)) && isstruct(override.(name))
        out.(name) = mergeStruct(out.(name), override.(name));
    else
        out.(name) = override.(name);
    end
end
end
