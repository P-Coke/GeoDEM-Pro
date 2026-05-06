function results = runAllTests()
%RUNALLTESTS Headless verification for GeoDEM Pro core services.

root = fileparts(fileparts(mfilename('fullpath')));
configureSourceEncoding();
addpath(root);
outputDir = fullfile(root, 'output', 'test_run');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

fprintf('GeoDEM Pro tests started in %s\n', root);
iconDir = geodem.view.IconFactory.ensureIcons(root);
assert(isfolder(iconDir), 'Icon directory was not created.');
assert(isfile(geodem.view.IconFactory.getIcon(root, 'dem', 32)), 'DEM icon was not generated.');

sampleDir = findSampleDataDir(root);
sampleACsv = fullfile(sampleDir, 'cloud_merged_6.csv');
sampleBCsv = fullfile(sampleDir, 'cloud_merged_12.csv');
sampleATxt = fullfile(sampleDir, 'cloud_merged_6.txt');
sampleBTxt = fullfile(sampleDir, 'cloud_merged_12.txt');

cloudA = geodem.service.io.importPointCloud(sampleACsv, 'Sample A');
cloudB = geodem.service.io.importPointCloud(sampleBCsv, 'Sample B');
cloudAtxt = geodem.service.io.importPointCloud(sampleATxt, 'Sample A TXT');
cloudBtxt = geodem.service.io.importPointCloud(sampleBTxt, 'Sample B TXT');
assert(size(cloudA.points, 1) == 112604, 'Unexpected Sample A CSV point count.');
assert(size(cloudB.points, 1) == 110666, 'Unexpected Sample B CSV point count.');
assert(size(cloudAtxt.points, 1) == size(cloudA.points, 1), 'Sample A TXT/CSV point count mismatch.');
assert(size(cloudBtxt.points, 1) == size(cloudB.points, 1), 'Sample B TXT/CSV point count mismatch.');

params = geodem.model.ProjectState.defaultParameters();
[cleanA, cleanReportA] = geodem.service.pointcloud.cleanPointCloud(cloudA, params.cleaning.method, params.cleaning);
[cleanB, cleanReportB] = geodem.service.pointcloud.cleanPointCloud(cloudB, params.cleaning.method, params.cleaning);
assert(cleanReportA.RemainingPointCount < cleanReportA.OriginalPointCount, 'Sample A cleaning did not remove points.');
assert(cleanReportB.RemainingPointCount < cleanReportB.OriginalPointCount, 'Sample B cleaning did not remove points.');

[extent, commonA, commonB] = geodem.service.pointcloud.extractCommonExtent(cleanA, cleanB);
assert(extent.Width > 380 && extent.Height > 380, 'Unexpected common extent.');
assert(size(commonA.points, 1) > 0 && size(commonB.points, 1) > 0, 'Common extent crop removed all points.');

density = geodem.service.pointcloud.computeDensityGrid(commonA, 5.0, extent);
assert(all(size(density.Density) == size(density.Counts)), 'Density grid shape mismatch.');

gridSpec = struct('extent', extent, 'resolution', 1.0, 'holeFill', struct('enabled', false));
methods = {'nearest', 'linear', 'natural'};
for i = 1:numel(methods)
    demA = geodem.service.dem.buildDem(commonA, gridSpec, methods{i}, struct('enabled', false));
    demB = geodem.service.dem.buildDem(commonB, gridSpec, methods{i}, struct('enabled', false));
    assert(isequal(size(demA.Z), size(demB.Z)), 'DEM size mismatch.');
    assert(demA.qualityMetrics.ValidCellCount > 0, 'DEM has no valid cells.');
end

demA = geodem.service.dem.buildDem(commonA, gridSpec, 'natural', struct('enabled', false));
demB = geodem.service.dem.buildDem(commonB, gridSpec, 'natural', struct('enabled', false));
thresholds = params.thresholds;
thresholds.contourInterval = 0.10;
result = geodem.service.deformation.analyzeDeformation(demA, demB, thresholds);
assert(isequal(size(result.deltaZ), size(demA.Z)), 'Delta grid shape mismatch.');
assert(result.stats.TotalValidArea > 0, 'No valid deformation area.');
assert(result.stats.SubsidenceArea >= 0 && result.stats.UpliftArea >= 0, 'Invalid area statistics.');

tmpTif = fullfile(outputDir, 'single_dem_test.tif');
geodem.service.export.exportGeoTiff(demA, geodem.model.SpatialReference(), tmpTif);
assert(isfile(tmpTif), 'GeoTIFF export failed.');
[A, R] = readRasterCompat(tmpTif); %#ok<ASGLU>
assert(isequal(size(A), size(demA.Z)), 'GeoTIFF readback size mismatch.');

tmpShape = geodem.service.export.exportContoursShapefile(result, fullfile(outputDir, 'single_contours_test.shp'));
assert(isfile(tmpShape.Contours), 'Contour Shapefile export failed.');
assert(isfile(tmpShape.MaxSubsidencePoint), 'Max subsidence Shapefile export failed.');
shapeRecords = shaperead(tmpShape.Contours);
assert(~isempty(shapeRecords), 'Shapefile readback failed.');

profile = geodem.service.deformation.profileAnalysis(demA, demB, [extent.XMin extent.YMin], [extent.XMax extent.YMax], 50);
assert(height(profile) == 50, 'Profile sample count mismatch.');
measurement = geodem.service.deformation.measureDistance([extent.XMin extent.YMin; extent.XMax extent.YMax]);
assert(measurement.TotalDistance > 0, 'Distance measurement failed.');

comparison = geodem.service.dem.compareInterpolationMethods(commonA, commonB, gridSpec, {'nearest','linear'}, struct('enabled', false), thresholds);
assert(height(comparison.Summary) == 2, 'Interpolation comparison row count mismatch.');

project = geodem.service.workflow.runAnalysisWorkflow(sampleACsv, sampleBCsv, struct( ...
    'projectRoot', root, ...
    'outputDir', outputDir, ...
    'gridResolution', 1.0, ...
    'interpolationMethod', 'natural', ...
    'smoothing', struct('enabled', false, 'method', 'mean', 'window', 3)));
outputs = geodem.service.export.exportResults(project, struct('outputDir', outputDir, 'imageFormats', {{'png'}}, 'data', true, 'images', true));
assert(isfile(outputs.ProjectFile), 'Project MAT file was not exported.');
assert(~isempty(outputs.DataFiles) && all(cellfun(@isfile, outputs.DataFiles)), 'One or more data exports are missing.');
assert(~isempty(outputs.FigureFiles) && all(cellfun(@isfile, outputs.FigureFiles)), 'One or more figure exports are missing.');
assert(~isempty(outputs.GeoFiles) && all(cellfun(@isfile, outputs.GeoFiles)), 'One or more GeoTIFF exports are missing.');
assert(~isempty(outputs.ShapeFiles) && all(cellfun(@isfile, outputs.ShapeFiles)), 'One or more Shapefile exports are missing.');

identify = geodem.service.deformation.identifyAt(project, extent.XMin + extent.Width/2, extent.YMin + extent.Height/2);
assert(isfield(identify, 'DeltaZ'), 'Identify result missing DeltaZ.');
deformationLayers = project.layerNamesByType("deformation");
attr = geodem.service.layer.buildLayerAttributeTable(project, deformationLayers(1));
assert(height(attr) > 0, 'Attribute table is empty.');

reports = geodem.service.export.generateReport(project, struct('outputDir', outputDir));
assert(isfile(reports.HTML), 'HTML report was not generated.');

loadedProject = geodem.service.io.loadProject(outputs.ProjectFile);
assert(~isempty(loadedProject.deformation), 'Loaded project lost deformation result.');
assert(~isempty(fieldnames(loadedProject.deformations)), 'Loaded project lost deformation result repository.');
assert(isa(loadedProject.spatialReference, 'geodem.model.SpatialReference'), 'Loaded project lost spatial reference.');

results = struct( ...
    'Root', root, ...
    'OutputDir', outputDir, ...
    'SampleAPoints', size(cloudA.points, 1), ...
    'SampleBPoints', size(cloudB.points, 1), ...
    'CommonExtent', extent, ...
    'MaxSubsidence', result.stats.MaxSubsidence, ...
    'MaxUplift', result.stats.MaxUplift, ...
    'ReportHTML', reports.HTML, ...
    'ReportDOCX', reports.DOCX);

fprintf('GeoDEM Pro tests passed. Output: %s\n', outputDir);
disp(results);
end

function configureSourceEncoding()
if exist('slCharacterEncoding', 'file') == 2
    try
        slCharacterEncoding('UTF-8');
    catch
    end
end
end

function sampleDir = findSampleDataDir(root)
direct = fullfile(root, 'testdata');
if isfile(fullfile(direct, 'cloud_merged_6.csv'))
    sampleDir = direct;
    return;
end
hits = dir(fullfile(root, '**', 'cloud_merged_6.csv'));
if isempty(hits)
    error('GeoDEM:MissingSampleData', 'Sample point-cloud data was not found under: %s', root);
end
sampleDir = hits(1).folder;
end

function [A, R] = readRasterCompat(filePath)
[A, R] = geodem.compat.readGeoRaster(filePath);
end
