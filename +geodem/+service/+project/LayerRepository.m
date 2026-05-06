classdef LayerRepository
    %LAYERREPOSITORY Maintains layer references and backing data storage.

    methods (Static)
        function renameLayer(project, oldName, newName)
            oldName = string(oldName);
            newName = strtrim(string(newName));
            if strlength(oldName) == 0 || strlength(newName) == 0
                error('GeoDEM:InvalidLayerName', '图层名称不能为空。');
            end
            idx = find(project.layers.Name == oldName, 1);
            if isempty(idx)
                error('GeoDEM:LayerNotFound', '图层不存在：%s', char(oldName));
            end
            if any(project.layers.Name == newName)
                error('GeoDEM:DuplicateLayerName', '已存在同名图层：%s', char(newName));
            end
            oldKey = geodem.model.ProjectState.layerKey(oldName);
            newKey = geodem.model.ProjectState.layerKey(newName);
            project.layers.Name(idx) = newName;
            if project.activeLayer == oldName
                project.activeLayer = newName;
            end

            if isfield(project.layerStyles, oldKey)
                project.layerStyles.(newKey) = project.layerStyles.(oldKey);
                project.layerStyles = rmfield(project.layerStyles, oldKey);
            end
            if isfield(project.layerDataRefs, oldKey)
                ref = project.layerDataRefs.(oldKey);
                ref.LayerName = newName;
                ref.StyleKey = string(newKey);
                project.layerDataRefs.(newKey) = ref;
                project.layerDataRefs = rmfield(project.layerDataRefs, oldKey);
            else
                geodem.service.project.LayerRepository.moveDirectStorage(project, oldKey, newKey, newName);
            end
            geodem.service.project.LayerRepository.renameAnalysisLayerReference(project, oldName, newName);
            geodem.service.project.LayerRepository.renameViewLayerReference(project, oldName, newName);
        end

        function deleteLayer(project, layerName)
            layerName = string(layerName);
            idx = find(project.layers.Name == layerName, 1);
            if isempty(idx)
                error('GeoDEM:LayerNotFound', '图层不存在：%s', char(layerName));
            end
            typeName = project.layers.Type(idx);
            key = geodem.model.ProjectState.layerKey(layerName);
            storageKey = key;
            if isfield(project.layerDataRefs, key)
                storageKey = char(project.layerDataRefs.(key).StorageKey);
                project.layerDataRefs = rmfield(project.layerDataRefs, key);
            end
            project.layers(idx, :) = [];
            if isfield(project.layerStyles, key)
                project.layerStyles = rmfield(project.layerStyles, key);
            end
            if ~geodem.service.project.LayerRepository.storageKeyStillUsed(project, storageKey)
                geodem.service.project.LayerRepository.deleteStorage(project, typeName, storageKey);
            end
            if project.activeLayer == layerName
                if isempty(project.layers)
                    project.activeLayer = "";
                else
                    project.activeLayer = project.layers.Name(max(1, min(idx, height(project.layers))));
                    project.layers.Visible(:) = false;
                    project.setLayerVisible(project.activeLayer, true);
                end
            end
            geodem.service.project.LayerRepository.renameViewLayerReference(project, layerName, "");
        end

        function clearAnalysis(project)
            project.cleanedClouds = struct();
            project.dems = struct();
            project.deformation = [];
            project.deformations = struct();
            if ~isempty(project.layers)
                keep = project.layers.Type == "pointcloud";
                project.layers = project.layers(keep, :);
            end
            styleNames = fieldnames(project.layerStyles);
            pointCloudNames = project.layerNamesByType("pointcloud");
            keepStyles = struct();
            keepRefs = struct();
            for i = 1:numel(pointCloudNames)
                key = matlab.lang.makeValidName(char(pointCloudNames(i)));
                if ismember(key, styleNames)
                    keepStyles.(key) = project.layerStyles.(key);
                end
                if isfield(project.layerDataRefs, key)
                    keepRefs.(key) = project.layerDataRefs.(key);
                end
            end
            project.layerStyles = keepStyles;
            project.layerDataRefs = keepRefs;
            project.activeLayer = "";
            project.mapToolState = geodem.model.MapToolState();
            project.viewStates = geodem.model.ProjectState.defaultViewStates();
            project.activeViewId = "map";
        end
    end

    methods (Static, Access = private)
        function moveDirectStorage(project, oldKey, newKey, newName)
            if isfield(project.clouds, oldKey)
                project.clouds.(newKey) = project.clouds.(oldKey);
                project.clouds.(newKey).name = char(newName);
                project.clouds.(newKey).period = char(newName);
                project.clouds = rmfield(project.clouds, oldKey);
            end
            if isfield(project.dems, oldKey)
                project.dems.(newKey) = project.dems.(oldKey);
                project.dems.(newKey).name = char(newName);
                project.dems = rmfield(project.dems, oldKey);
            end
            if isfield(project.parameters, 'density') && isfield(project.parameters.density, oldKey)
                project.parameters.density.(newKey) = project.parameters.density.(oldKey);
                project.parameters.density = rmfield(project.parameters.density, oldKey);
            end
        end

        function tf = storageKeyStillUsed(project, storageKey)
            tf = false;
            refs = fieldnames(project.layerDataRefs);
            for i = 1:numel(refs)
                if string(project.layerDataRefs.(refs{i}).StorageKey) == string(storageKey)
                    tf = true;
                    return;
                end
            end
        end

        function deleteStorage(project, typeName, storageKey)
            storageKey = char(storageKey);
            switch string(typeName)
                case "pointcloud"
                    if isfield(project.clouds, storageKey), project.clouds = rmfield(project.clouds, storageKey); end
                case "dem"
                    if isfield(project.dems, storageKey), project.dems = rmfield(project.dems, storageKey); end
                case "density"
                    if isfield(project.parameters, 'density') && isfield(project.parameters.density, storageKey)
                        project.parameters.density = rmfield(project.parameters.density, storageKey);
                    end
                case {"deformation","classmap","contour","surface3d"}
                    if isfield(project.deformations, storageKey)
                        project.deformations = rmfield(project.deformations, storageKey);
                        keys = fieldnames(project.deformations);
                        if isempty(keys)
                            project.deformation = [];
                        else
                            project.deformation = project.deformations.(keys{end});
                        end
                    end
            end
        end

        function renameAnalysisLayerReference(project, oldName, newName)
            if ~isfield(project.parameters, 'analysis') || ~isstruct(project.parameters.analysis)
                return;
            end
            names = fieldnames(project.parameters.analysis);
            for i = 1:numel(names)
                value = project.parameters.analysis.(names{i});
                if isstring(value) || ischar(value)
                    if string(value) == string(oldName)
                        project.parameters.analysis.(names{i}) = string(newName);
                    end
                end
            end
        end

        function renameViewLayerReference(project, oldName, newName)
            viewKeys = fieldnames(project.viewStates);
            for i = 1:numel(viewKeys)
                state = project.viewStates.(viewKeys{i});
                if state.ActiveLayer == string(oldName)
                    state.ActiveLayer = string(newName);
                    project.viewStates.(viewKeys{i}) = state;
                end
            end
        end
    end
end
