classdef ProjectState < handle
    %PROJECTSTATE Mutable application state shared by controller and services.

    properties
        name
        clouds
        cleanedClouds
        dems
        deformation
        deformations
        layers
        parameters
        outputDir
        projectPath
        logMessages
        spatialReference
        layerStyles
        layerDataRefs
        toolDefaults
        toolHistory
        activeLayer
        mapToolState
        viewStates
        activeViewId
    end

    methods
        function obj = ProjectState(projectRoot)
            if nargin < 1 || isempty(projectRoot)
                projectRoot = pwd;
            end
            obj.name = geodem.config.AppConfig.DefaultProjectName;
            obj.clouds = struct();
            obj.cleanedClouds = struct();
            obj.dems = struct();
            obj.deformation = [];
            obj.deformations = struct();
            obj.layers = geodem.model.ProjectState.emptyLayerTable();
            obj.parameters = geodem.model.ProjectState.defaultParameters();
            obj.outputDir = fullfile(projectRoot, geodem.config.AppConfig.DefaultOutputDir);
            obj.projectPath = "";
            obj.logMessages = strings(0, 1);
            obj.spatialReference = geodem.model.SpatialReference();
            obj.layerStyles = struct();
            obj.layerDataRefs = struct();
            obj.toolDefaults = struct();
            obj.toolHistory = geodem.model.ToolExecutionRecord.empty(0, 1);
            obj.activeLayer = "";
            obj.mapToolState = geodem.model.MapToolState();
            obj.viewStates = geodem.model.ProjectState.defaultViewStates();
            obj.activeViewId = "map";
            if ~exist(obj.outputDir, 'dir')
                mkdir(obj.outputDir);
            end
        end

        function addLog(obj, message)
            stamp = string(datetime('now', 'Format', geodem.config.AppConfig.TimeFormat));
            obj.logMessages(end + 1, 1) = "[" + stamp + "] " + string(message);
        end

        function addLayer(obj, name, type, visible)
            if nargin < 4
                visible = true;
            end
            [groupName, iconName] = geodem.model.ProjectState.layerDefaults(type, name);
            row = table(string(name), string(type), logical(visible), string(groupName), string(iconName), ...
                'VariableNames', {'Name','Type','Visible','Group','Icon'});
            existing = find(obj.layers.Name == string(name), 1);
            if isempty(existing)
                obj.layers = [obj.layers; row];
            else
                obj.layers(existing, :) = row;
            end
            obj.activeLayer = string(name);
            key = matlab.lang.makeValidName(char(name));
            if ~isfield(obj.layerStyles, key)
                obj.layerStyles.(key) = geodem.model.LayerStyle(iconName, [], 1, 1, "o", false);
            end
        end

        function layerName = addCloud(obj, cloud, visible)
            if nargin < 3
                visible = true;
            end
            baseName = string(cloud.name);
            if strlength(baseName) == 0
                baseName = "PointCloud";
            end
            layerName = obj.uniqueLayerName(baseName);
            key = geodem.model.ProjectState.layerKey(layerName);
            cloud.name = char(layerName);
            cloud.period = char(layerName);
            obj.clouds.(key) = cloud;
            obj.addLayer(layerName, 'pointcloud', visible);
        end

        function layerName = addDem(obj, dem, visible)
            if nargin < 3
                visible = true;
            end
            baseName = string(dem.name);
            if strlength(baseName) == 0
                baseName = "DEM";
            end
            layerName = obj.uniqueLayerName(baseName);
            key = geodem.model.ProjectState.layerKey(layerName);
            dem.name = char(layerName);
            obj.dems.(key) = dem;
            obj.addLayer(layerName, 'dem', visible);
        end

        function names = layerNamesByType(obj, typeName)
            if isempty(obj.layers)
                names = strings(0, 1);
                return;
            end
            names = obj.layers.Name(obj.layers.Type == string(typeName));
        end

        function cloud = getCloudByLayer(obj, layerName)
            ref = obj.getLayerDataRef(layerName);
            if ~isempty(ref) && isfield(obj.clouds, char(ref.StorageKey))
                cloud = obj.clouds.(char(ref.StorageKey));
                return;
            end
            key = geodem.model.ProjectState.layerKey(layerName);
            if isfield(obj.clouds, key)
                cloud = obj.clouds.(key);
                return;
            end
            error('GeoDEM:CloudLayerNotFound', 'Point-cloud layer not found: %s', char(layerName));
        end

        function layerName = uniqueLayerName(obj, baseName)
            baseName = string(baseName);
            existing = strings(0, 1);
            if ~isempty(obj.layers)
                existing = obj.layers.Name;
            end
            layerName = baseName;
            n = 2;
            while any(existing == layerName)
                layerName = baseName + " (" + n + ")";
                n = n + 1;
            end
        end

        function setLayerVisible(obj, name, visible)
            idx = obj.layers.Name == string(name);
            obj.layers.Visible(idx) = logical(visible);
        end

        function renameLayer(obj, oldName, newName)
            geodem.service.project.LayerRepository.renameLayer(obj, oldName, newName);
        end

        function deleteLayer(obj, layerName)
            geodem.service.project.LayerRepository.deleteLayer(obj, layerName);
        end

        function clearAnalysis(obj)
            geodem.service.project.LayerRepository.clearAnalysis(obj);
        end

        function addLayerDataRef(obj, layerName, layerType, storageKey, sourceToolId, sourceParams)
            if nargin < 6
                sourceParams = struct();
            end
            key = geodem.model.ProjectState.layerKey(layerName);
            obj.layerDataRefs.(key) = geodem.model.LayerDataRef(layerName, layerType, storageKey, sourceToolId, sourceParams, key);
        end

        function ref = getLayerDataRef(obj, layerName)
            key = geodem.model.ProjectState.layerKey(layerName);
            if isfield(obj.layerDataRefs, key)
                ref = obj.layerDataRefs.(key);
            else
                ref = [];
            end
        end

        function tf = hasLayer(obj, layerName)
            tf = ~isempty(obj.layers) && any(obj.layers.Name == string(layerName));
        end

        function recordToolExecution(obj, record)
            if isempty(obj.toolHistory)
                obj.toolHistory = record;
            else
                obj.toolHistory(end + 1, 1) = record;
            end
        end

        function key = addDeformation(obj, resultLayerName, deformationResult)
            key = geodem.model.ProjectState.layerKey(resultLayerName);
            obj.deformations.(key) = deformationResult;
            obj.deformation = deformationResult;
        end

        function result = getDeformationByLayer(obj, layerName)
            result = [];
            ref = obj.getLayerDataRef(layerName);
            if ~isempty(ref) && isfield(obj.deformations, char(ref.StorageKey))
                result = obj.deformations.(char(ref.StorageKey));
                return;
            end
            key = geodem.model.ProjectState.layerKey(layerName);
            if isfield(obj.deformations, key)
                result = obj.deformations.(key);
                return;
            end
            if ~isempty(obj.deformation)
                result = obj.deformation;
            end
        end

        function result = activeDeformation(obj)
            result = [];
            if strlength(string(obj.activeLayer)) > 0
                result = obj.getDeformationByLayer(obj.activeLayer);
            end
            if isempty(result)
                keys = fieldnames(obj.deformations);
                if ~isempty(keys)
                    result = obj.deformations.(keys{end});
                elseif ~isempty(obj.deformation)
                    result = obj.deformation;
                end
            end
        end

        function state = getViewState(obj, viewId)
            viewId = string(viewId);
            key = geodem.model.ProjectState.layerKey(viewId);
            if ~isfield(obj.viewStates, key)
                obj.viewStates.(key) = geodem.model.ViewState(viewId, viewId);
            end
            state = obj.viewStates.(key);
        end

        function setViewState(obj, viewId, state)
            key = geodem.model.ProjectState.layerKey(viewId);
            obj.viewStates.(key) = state;
        end

        function s = serializeState(obj)
            s = geodem.service.project.ProjectStateSerializer.serialize(obj);
        end

        function deserializeState(obj, s)
            geodem.service.project.ProjectStateSerializer.deserialize(obj, s);
        end
    end

    methods (Static)
        function layers = emptyLayerTable()
            layers = geodem.model.LayerTable.empty();
        end

        function key = layerKey(layerName)
            key = geodem.model.LayerTable.key(layerName);
        end

        function layers = normalizeLayerTable(layers)
            layers = geodem.model.LayerTable.normalize(layers);
        end

        function [groupName, iconName] = layerDefaults(typeName, layerName)
            [groupName, iconName] = geodem.model.LayerTable.defaults(typeName, layerName);
        end

        function params = defaultParameters()
            params = geodem.model.ProjectDefaults.parameters();
        end

        function states = defaultViewStates()
            states = geodem.model.ProjectDefaults.viewStates();
        end
    end
end
