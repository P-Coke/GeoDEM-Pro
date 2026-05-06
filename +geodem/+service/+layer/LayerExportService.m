classdef LayerExportService
    %LAYEREXPORTSERVICE Export layer data by layer type and selected file.

    methods (Static)
        function [filters, defaultFile] = dialogSpec(project, layerName)
            idx = find(project.layers.Name == string(layerName), 1);
            if isempty(idx)
                error('GeoDEM:LayerNotFound', '图层不存在：%s', char(layerName));
            end
            typeName = string(project.layers.Type(idx));
            stem = char(geodem.model.ProjectState.layerKey(layerName));
            switch typeName
                case "pointcloud"
                    filters = {'*.csv','CSV 点云 (*.csv)'; '*.txt','TXT 点云 (*.txt)'; '*.mat','MATLAB 点云 (*.mat)'};
                    defaultFile = [stem '.csv'];
                case "dem"
                    filters = {'*.tif','GeoTIFF DEM (*.tif)'; '*.csv','CSV 矩阵 (*.csv)'; '*.mat','MATLAB DEM (*.mat)'};
                    defaultFile = [stem '.tif'];
                case "density"
                    filters = {'*.csv','CSV 密度矩阵 (*.csv)'; '*.mat','MATLAB 密度图 (*.mat)'};
                    defaultFile = [stem '_density.csv'];
                case "deformation"
                    filters = {'*.tif','GeoTIFF 差值栅格 (*.tif)'; '*.csv','CSV 差值矩阵 (*.csv)'; '*.mat','MATLAB 形变结果 (*.mat)'};
                    defaultFile = [stem '_deltaZ.tif'];
                case "classmap"
                    filters = {'*.csv','CSV 等级矩阵 (*.csv)'; '*.mat','MATLAB 等级图 (*.mat)'};
                    defaultFile = [stem '_classmap.csv'];
                case "contour"
                    filters = {'*.shp','Shapefile 等值线 (*.shp)'; '*.mat','MATLAB 等值线 (*.mat)'};
                    defaultFile = [stem '_contours.shp'];
                case "surface3d"
                    filters = {'*.tif','GeoTIFF 形变栅格 (*.tif)'; '*.mat','MATLAB 形变结果 (*.mat)'};
                    defaultFile = [stem '_surface.tif'];
                otherwise
                    filters = {'*.mat','MATLAB Data (*.mat)'};
                    defaultFile = [stem '.mat'];
            end
        end

        function folder = preferredExportDir(project, subfolder)
            folder = "";
            if isfield(project.parameters, 'lastExportDir') && strlength(string(project.parameters.lastExportDir)) > 0
                folder = string(project.parameters.lastExportDir);
            end
            if strlength(folder) == 0
                folder = string(fullfile(project.outputDir, subfolder));
            end
            folder = char(folder);
        end

        function files = exportData(project, layerName, targetFile)
            idx = find(project.layers.Name == string(layerName), 1);
            typeName = string(project.layers.Type(idx));
            targetFile = char(targetFile);
            [folder, baseName, ext] = fileparts(targetFile);
            if isempty(folder), folder = project.outputDir; end
            if ~exist(folder, 'dir'), mkdir(folder); end
            if isempty(ext)
                [~, defaultFile] = geodem.service.layer.LayerExportService.dialogSpec(project, layerName);
                [~, ~, ext] = fileparts(defaultFile);
                targetFile = fullfile(folder, [baseName ext]);
            end
            ext = lower(string(ext));
            files = {};
            switch typeName
                case "pointcloud"
                    files = exportPointCloud(project, layerName, targetFile, ext);
                case "dem"
                    files = exportDem(project, layerName, targetFile, ext);
                case "density"
                    files = exportDensity(project, layerName, targetFile, ext);
                case "deformation"
                    files = exportDeformation(project, layerName, targetFile, ext, folder, baseName);
                case "classmap"
                    files = exportClassMap(project, layerName, targetFile, ext);
                case "contour"
                    files = exportContours(project, layerName, targetFile, ext);
                case "surface3d"
                    files = exportSurface(project, layerName, targetFile, ext);
                otherwise
                    error('GeoDEM:UnsupportedLayerExport', '暂不支持导出该图层类型：%s。', typeName);
            end
        end
    end
end

function files = exportPointCloud(project, layerName, targetFile, ext)
cloud = project.getCloudByLayer(layerName);
pointTable = array2table(cloud.points, 'VariableNames', {'X','Y','Z'});
switch ext
    case ".csv"
        writetable(pointTable, targetFile);
    case ".txt"
        writetable(pointTable, targetFile, 'Delimiter', '\t');
    case ".mat"
        save(targetFile, 'cloud');
    otherwise
        error('GeoDEM:UnsupportedLayerExport', '点云图层支持 CSV、TXT、MAT。');
end
files = {targetFile};
end

function files = exportDem(project, layerName, targetFile, ext)
dem = geodem.tool.ToolRegistry.getDemByLayer(project, layerName);
switch ext
    case {".tif",".tiff"}
        geodem.service.export.exportGeoTiff(dem, project.spatialReference, targetFile);
    case ".csv"
        writematrix(dem.Z, targetFile);
    case ".mat"
        save(targetFile, 'dem');
    otherwise
        error('GeoDEM:UnsupportedLayerExport', 'DEM 图层支持 GeoTIFF、CSV、MAT。');
end
files = {targetFile};
end

function files = exportDensity(project, layerName, targetFile, ext)
density = geodem.service.layer.LayerInfoService.densityForLayer(project, layerName);
if isempty(density), error('GeoDEM:MissingDensity', '密度图层数据不存在。'); end
switch ext
    case ".csv"
        writematrix(density.Density, targetFile);
    case ".mat"
        save(targetFile, 'density');
    otherwise
        error('GeoDEM:UnsupportedLayerExport', '密度图层支持 CSV、MAT。');
end
files = {targetFile};
end

function files = exportDeformation(project, layerName, targetFile, ext, folder, baseName)
result = project.getDeformationByLayer(layerName);
switch ext
    case {".tif",".tiff"}
        geodem.service.export.exportGeoTiff(result, project.spatialReference, targetFile);
    case ".csv"
        writematrix(result.deltaZ, targetFile);
    case ".mat"
        save(targetFile, 'result');
    otherwise
        error('GeoDEM:UnsupportedLayerExport', '形变差值图层支持 GeoTIFF、CSV、MAT。');
end
statsFile = fullfile(folder, [baseName '_statistics.csv']);
writetable(result.statsTable(), statsFile);
files = {targetFile, statsFile};
end

function files = exportClassMap(project, layerName, targetFile, ext)
result = project.getDeformationByLayer(layerName);
switch ext
    case ".csv"
        writematrix(result.classMap, targetFile);
    case ".mat"
        classMap = result.classMap; %#ok<NASGU>
        save(targetFile, 'classMap', 'result');
    otherwise
        error('GeoDEM:UnsupportedLayerExport', '等级图层支持 CSV、MAT。');
end
files = {targetFile};
end

function files = exportContours(project, layerName, targetFile, ext)
result = project.getDeformationByLayer(layerName);
switch ext
    case ".shp"
        shp = geodem.service.export.exportContoursShapefile(result, targetFile);
        files = {shp.Contours, shp.MaxSubsidencePoint};
    case ".mat"
        contours = result.contours; %#ok<NASGU>
        maxSubsidencePoint = result.maxSubsidencePoint; %#ok<NASGU>
        save(targetFile, 'contours', 'maxSubsidencePoint', 'result');
        files = {targetFile};
    otherwise
        error('GeoDEM:UnsupportedLayerExport', '等值线图层支持 Shapefile、MAT。');
end
end

function files = exportSurface(project, layerName, targetFile, ext)
result = project.getDeformationByLayer(layerName);
switch ext
    case {".tif",".tiff"}
        geodem.service.export.exportGeoTiff(result, project.spatialReference, targetFile);
    case ".mat"
        save(targetFile, 'result');
    otherwise
        error('GeoDEM:UnsupportedLayerExport', '三维形变图层支持 GeoTIFF、MAT。');
end
files = {targetFile};
end
