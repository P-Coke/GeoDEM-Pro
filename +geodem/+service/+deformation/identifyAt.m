function result = identifyAt(project, x, y)
%IDENTIFYAT Return DEM/deformation values nearest to an XY location.

if nargin < 3
    error('GeoDEM:InvalidIdentifyInput', 'identifyAt requires project, x and y.');
end

result = struct('X', x, 'Y', y, 'Layer', "", 'Row', NaN, 'Col', NaN, ...
    'BaseDEM', NaN, 'MonitorDEM', NaN, 'DeltaZ', NaN, ...
    'ClassCode', NaN, 'ClassName', "", 'Distance', NaN);

[baseDem, monitorDem] = selectedDems(project);
if ~isempty(baseDem)
    [row, col, distance] = nearestGridCell(baseDem.XGrid, baseDem.YGrid, x, y);
    result.Row = row;
    result.Col = col;
    result.Distance = distance;
    result.Layer = "DEM / Deformation";
    result.BaseDEM = baseDem.Z(row, col);
end
if ~isempty(monitorDem) && isfinite(result.Row)
    result.MonitorDEM = monitorDem.Z(result.Row, result.Col);
end
deformation = project.activeDeformation();
if ~isempty(deformation) && isfinite(result.Row)
    result.DeltaZ = deformation.deltaZ(result.Row, result.Col);
    result.ClassCode = deformation.classMap(result.Row, result.Col);
    result.ClassName = className(result.ClassCode);
end
end

function [baseDem, monitorDem] = selectedDems(project)
baseDem = [];
monitorDem = [];
demNames = project.layerNamesByType("dem");
if isempty(demNames)
    return;
end

baseLayer = demNames(1);
monitorLayer = "";
if numel(demNames) >= 2
    monitorLayer = demNames(2);
end

if isfield(project.parameters, 'analysis')
    analysis = project.parameters.analysis;
    if isfield(analysis, 'BaseDemLayer') && any(demNames == string(analysis.BaseDemLayer))
        baseLayer = string(analysis.BaseDemLayer);
    end
    if isfield(analysis, 'MonitorDemLayer') && any(demNames == string(analysis.MonitorDemLayer))
        monitorLayer = string(analysis.MonitorDemLayer);
    end
end

baseDem = geodem.tool.ToolRegistry.getDemByLayer(project, baseLayer);
if strlength(monitorLayer) > 0
    monitorDem = geodem.tool.ToolRegistry.getDemByLayer(project, monitorLayer);
end
end

function [row, col, distance] = nearestGridCell(XGrid, YGrid, x, y)
dx = XGrid(1, :) - x;
dy = YGrid(:, 1) - y;
[~, col] = min(abs(dx));
[~, row] = min(abs(dy));
distance = hypot(XGrid(row, col) - x, YGrid(row, col) - y);
end

function name = className(code)
switch code
    case -3
        name = "严重沉降";
    case -2
        name = "中度沉降";
    case -1
        name = "轻微沉降";
    case 0
        name = "稳定";
    case 1
        name = "轻微抬升";
    case 2
        name = "明显抬升";
    otherwise
        name = "无数据";
end
end
