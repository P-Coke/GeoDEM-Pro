function outputs = exportResults(project, exportSpec)
%EXPORTRESULTS Export rasters, statistics, project MAT data, and figures.

if nargin < 2 || isempty(exportSpec)
    exportSpec = struct();
end
outputDir = geodem.util.getField(exportSpec, 'outputDir', project.outputDir);
imageFormats = geodem.util.getField(exportSpec, 'imageFormats', {'png', 'pdf'});
exportData = geodem.util.getField(exportSpec, 'data', true);
exportImages = geodem.util.getField(exportSpec, 'images', true);

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
dataDir = fullfile(outputDir, 'data');
figureDir = fullfile(outputDir, 'figures');
if exportData && ~exist(dataDir, 'dir')
    mkdir(dataDir);
end
if exportImages && ~exist(figureDir, 'dir')
    mkdir(figureDir);
end

outputs = struct('OutputDir', outputDir, 'DataFiles', {{}}, 'FigureFiles', {{}}, 'GeoFiles', {{}}, 'ShapeFiles', {{}}, 'ProjectFile', "");

if exportData
    outputs = exportDataFiles(project, dataDir, outputs);
end
if exportImages
    outputs = exportFigureFiles(project, figureDir, imageFormats, outputs);
end

projectFile = fullfile(outputDir, 'GeoDEMPro_project.mat');
geodem.service.io.saveProject(project, projectFile);
outputs.ProjectFile = projectFile;
end

function outputs = exportDataFiles(project, dataDir, outputs)
dems = selectedDems(project);
for i = 1:numel(dems)
    stem = char(dems(i).FileStem);
    dem = dems(i).Dem;
    file = fullfile(dataDir, [stem '_matrix.csv']);
    writematrix(dem.Z, file);
    outputs.DataFiles{end + 1} = file;
    tif = fullfile(dataDir, [stem '.tif']);
    geodem.service.export.exportGeoTiff(dem, project.spatialReference, tif);
    outputs.GeoFiles{end + 1} = tif;
end
deformations = selectedDeformations(project);
for i = 1:numel(deformations)
    result = deformations(i).Result;
    stem = char(deformations(i).FileStem);
    file = fullfile(dataDir, [stem '_difference_matrix.csv']);
    writematrix(result.deltaZ, file);
    outputs.DataFiles{end + 1} = file;

    file = fullfile(dataDir, [stem '_class_matrix.csv']);
    writematrix(result.classMap, file);
    outputs.DataFiles{end + 1} = file;

    file = fullfile(dataDir, [stem '_statistics.csv']);
    writetable(result.statsTable(), file);
    outputs.DataFiles{end + 1} = file;

    file = fullfile(dataDir, [stem '_class_area.csv']);
    writetable(result.stats.ClassAreaTable, file);
    outputs.DataFiles{end + 1} = file;

    file = fullfile(dataDir, [stem '_contours.mat']);
    contours = result.contours; %#ok<NASGU>
    save(file, 'contours');
    outputs.DataFiles{end + 1} = file;

    tif = fullfile(dataDir, [stem '.tif']);
    geodem.service.export.exportGeoTiff(result, project.spatialReference, tif);
    outputs.GeoFiles{end + 1} = tif;

    shp = geodem.service.export.exportContoursShapefile(result, fullfile(dataDir, [stem '_subsidence_contours.shp']));
    outputs.ShapeFiles{end + 1} = shp.Contours;
    outputs.ShapeFiles{end + 1} = shp.MaxSubsidencePoint;
end
if isfield(project.parameters, 'density')
    file = fullfile(dataDir, 'point_density.mat');
    density = project.parameters.density; %#ok<NASGU>
    save(file, 'density');
    outputs.DataFiles{end + 1} = file;
end
end

function outputs = exportFigureFiles(project, figureDir, imageFormats, outputs)
if isstring(imageFormats)
    imageFormats = cellstr(imageFormats);
end
figSpecs = {};
dems = selectedDems(project);
for i = 1:numel(dems)
    dem = dems(i).Dem;
    figSpecs{end + 1} = {@() plotRaster(dem.XGrid, dem.YGrid, dem.Z, char(dems(i).Label + " 彩色高程图"), '高程 / m', parula(256)), char(dems(i).FileStem)}; %#ok<AGROW>
end
deformations = selectedDeformations(project);
for i = 1:numel(deformations)
    result = deformations(i).Result;
    stem = char(deformations(i).FileStem);
    figSpecs{end + 1} = {@() plotRaster(result.XGrid, result.YGrid, result.deltaZ, char(deformations(i).Label + " 差值热力图"), 'ΔZ / m', blueWhiteRed(256)), [stem '_difference']}; %#ok<AGROW>
    figSpecs{end + 1} = {@() plotClassMap(result), [stem '_class']}; %#ok<AGROW>
    figSpecs{end + 1} = {@() plotContours(result), [stem '_contours']}; %#ok<AGROW>
    monitorDem = selectedMonitorDem(project);
    if ~isempty(monitorDem)
        figSpecs{end + 1} = {@() plotSurface3D(monitorDem, result), [stem '_3d']}; %#ok<AGROW>
    end
end

for i = 1:numel(figSpecs)
    maker = figSpecs{i}{1};
    baseName = figSpecs{i}{2};
    fig = maker();
    cleanup = onCleanup(@() close(fig));
    for j = 1:numel(imageFormats)
        fmt = lower(char(imageFormats{j}));
        file = fullfile(figureDir, [baseName '.' fmt]);
        geodem.compat.exportFigure(fig, file, 'Resolution', 180);
        outputs.FigureFiles{end + 1} = file;
    end
    clear cleanup;
end
end

function fig = plotRaster(XGrid, YGrid, Z, titleText, colorbarLabel, cmap)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1100 800]);
ax = axes('Parent', fig);
imagesc(ax, XGrid(1, :), YGrid(:, 1), Z);
set(ax, 'YDir', 'normal');
axis(ax, 'equal');
axis(ax, 'tight');
grid(ax, 'on');
colormap(ax, cmap);
cb = colorbar(ax);
cb.Label.String = colorbarLabel;
geodem.service.cartography.createMapDecorations(ax, titleText, "");
end

function fig = plotClassMap(result)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1100 800]);
ax = axes('Parent', fig);
imagesc(ax, result.XGrid(1, :), result.YGrid(:, 1), result.classMap);
set(ax, 'YDir', 'normal');
axis(ax, 'equal');
axis(ax, 'tight');
grid(ax, 'on');
colormap(ax, [0.08 0.20 0.75; 0.20 0.48 0.90; 0.55 0.74 1.00; 0.93 0.93 0.93; 1.00 0.66 0.42; 0.80 0.13 0.10]);
caxis(ax, [-3 2]);
cb = colorbar(ax);
cb.Ticks = -3:2;
cb.TickLabels = {'严重沉降','中度沉降','轻微沉降','稳定','轻微抬升','明显抬升'};
geodem.service.cartography.createMapDecorations(ax, '形变等级分区图', "");
end

function fig = plotContours(result)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1100 800]);
ax = axes('Parent', fig);
contourf(ax, result.XGrid, result.YGrid, result.deltaZ, 24, 'LineStyle', 'none');
hold(ax, 'on');
colormap(ax, blueWhiteRed(256));
cb = colorbar(ax);
cb.Label.String = 'ΔZ / m';
interval = result.thresholds.contourInterval;
valid = isfinite(result.deltaZ);
minDz = min(result.deltaZ(valid));
maxDz = max(result.deltaZ(valid));
levels = floor(minDz / interval) * interval:interval:ceil(maxDz / interval) * interval;
[C, h] = contour(ax, result.XGrid, result.YGrid, result.deltaZ, levels, 'k', 'LineWidth', 0.7);
clabel(C, h, 'FontSize', 8, 'Color', 'k');
plot(ax, result.maxSubsidencePoint.X, result.maxSubsidencePoint.Y, 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
axis(ax, 'equal');
axis(ax, 'tight');
grid(ax, 'on');
geodem.service.cartography.createMapDecorations(ax, '沉降等值线图', sprintf('等值线间隔 %.2f m', interval));
hold(ax, 'off');
end

function fig = plotSurface3D(dem, result)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 850]);
ax = axes('Parent', fig);
surf(ax, dem.XGrid, dem.YGrid, dem.Z, result.deltaZ, 'EdgeColor', 'none');
colormap(ax, blueWhiteRed(256));
cb = colorbar(ax);
cb.Label.String = 'ΔZ / m';
title(ax, '三维形变地形图');
xlabel(ax, 'X / m');
ylabel(ax, 'Y / m');
zlabel(ax, '高程 / m');
axis(ax, 'tight');
view(ax, 45, 35);
camlight(ax, 'headlight');
lighting(ax, 'gouraud');
end

function cmap = blueWhiteRed(n)
if nargin < 1
    n = 256;
end
half = floor(n / 2);
blue = [linspace(0.08, 1, half)', linspace(0.25, 1, half)', ones(half, 1)];
red = [ones(n - half, 1), linspace(1, 0.10, n - half)', linspace(1, 0.08, n - half)'];
cmap = [blue; red];
end


function dems = selectedDems(project)
dems = struct('Label', {}, 'FileStem', {}, 'Dem', {});
names = project.layerNamesByType("dem");
for i = 1:numel(names)
    dem = geodem.tool.ToolRegistry.getDemByLayer(project, names(i));
    key = geodem.model.ProjectState.layerKey(names(i));
    dems(end + 1) = struct('Label', names(i), 'FileStem', string(key), 'Dem', dem); %#ok<AGROW>
end
end

function items = selectedDeformations(project)
items = struct('Label', {}, 'FileStem', {}, 'Result', {});
keys = fieldnames(project.deformations);
for i = 1:numel(keys)
    items(end + 1) = struct('Label', string(keys{i}), 'FileStem', string(keys{i}), 'Result', project.deformations.(keys{i})); %#ok<AGROW>
end
if isempty(items) && ~isempty(project.deformation)
    items(1) = struct('Label', "deformation", 'FileStem', "deformation", 'Result', project.deformation);
end
end

function dem = selectedMonitorDem(project)
dem = [];
names = project.layerNamesByType("dem");
if isempty(names)
    return;
end
layerName = names(end);
if isfield(project.parameters, 'analysis') && isfield(project.parameters.analysis, 'MonitorDemLayer') && any(names == string(project.parameters.analysis.MonitorDemLayer))
    layerName = string(project.parameters.analysis.MonitorDemLayer);
end
key = geodem.model.ProjectState.layerKey(layerName);
try
    dem = geodem.tool.ToolRegistry.getDemByLayer(project, layerName);
catch
    if isfield(project.dems, key)
        dem = project.dems.(key);
    end
end
end
