function tbl = buildLayerAttributeTable(project, layerName)
%BUILDLAYERATTRIBUTETABLE Build a table for selected layer inspection.

layerName = string(layerName);
if isa(project, 'geodem.model.ProjectState') || isstruct(project)
    idx = find(project.layers.Name == layerName, 1);
    if ~isempty(idx)
        typeName = string(project.layers.Type(idx));
        switch typeName
            case "pointcloud"
                tbl = pointSampleTable(project.getCloudByLayer(layerName));
                return;
            case "dem"
                dem = geodem.tool.ToolRegistry.getDemByLayer(project, layerName);
                tbl = rasterTable(dem.XGrid, dem.YGrid, dem.Z, "DEM");
                return;
            case "density"
                density = densityForLayer(project, layerName);
                if ~isempty(density)
                    tbl = rasterTable(density.XGrid, density.YGrid, density.Density, "Density");
                    return;
                end
            case "deformation"
                result = project.getDeformationByLayer(layerName);
                tbl = rasterTable(result.XGrid, result.YGrid, result.deltaZ, "DeltaZ");
                return;
            case "classmap"
                tbl = classTable(project.getDeformationByLayer(layerName));
                return;
            case "contour"
                tbl = contourTable(project.getDeformationByLayer(layerName));
                return;
        end
    end
end
result = project.activeDeformation();
if ~isempty(result)
    tbl = result.statsTable();
else
    tbl = table();
end
end

function density = densityForLayer(project, layerName)
density = [];
if ~isfield(project.parameters, 'density')
    return;
end
ref = [];
if isa(project, 'geodem.model.ProjectState')
    ref = project.getLayerDataRef(layerName);
end
if ~isempty(ref) && isfield(project.parameters.density, char(ref.StorageKey))
    density = project.parameters.density.(char(ref.StorageKey));
    return;
end
key = geodem.model.ProjectState.layerKey(layerName);
if isfield(project.parameters.density, key)
    density = project.parameters.density.(key);
end
end

function tbl = pointSampleTable(cloud)
pts = cloud.points;
maxRows = min(size(pts, 1), 5000);
idx = round(linspace(1, size(pts, 1), maxRows));
tbl = table(pts(idx, 1), pts(idx, 2), pts(idx, 3), ...
    'VariableNames', {'X','Y','Z'});
end

function tbl = rasterTable(XGrid, YGrid, Z, valueName)
valid = isfinite(Z);
idx = find(valid);
maxRows = min(numel(idx), 10000);
idx = idx(round(linspace(1, numel(idx), maxRows)));
tbl = table(XGrid(idx), YGrid(idx), Z(idx), ...
    'VariableNames', {'X','Y',char(valueName)});
end

function tbl = classTable(result)
valid = isfinite(result.classMap);
idx = find(valid);
maxRows = min(numel(idx), 10000);
idx = idx(round(linspace(1, numel(idx), maxRows)));
code = result.classMap(idx);
names = strings(size(code));
for i = 1:numel(code)
    names(i) = className(code(i));
end
tbl = table(result.XGrid(idx), result.YGrid(idx), result.deltaZ(idx), code, names, ...
    'VariableNames', {'X','Y','DeltaZ','ClassCode','ClassName'});
end

function tbl = contourTable(result)
lines = result.contours.Lines;
if isempty(lines)
    tbl = table();
    return;
end
level = zeros(numel(lines), 1);
vertices = zeros(numel(lines), 1);
for i = 1:numel(lines)
    level(i) = lines(i).Level;
    vertices(i) = numel(lines(i).X);
end
tbl = table((1:numel(lines))', level, vertices, 'VariableNames', {'ContourID','Level','VertexCount'});
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
