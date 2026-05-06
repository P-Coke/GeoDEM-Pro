classdef ProjectStateSerializer
    %PROJECTSTATESERIALIZER Converts ProjectState to and from plain structs.

    methods (Static)
        function s = serialize(project)
            s.name = project.name;
            s.clouds = project.clouds;
            s.cleanedClouds = project.cleanedClouds;
            s.dems = project.dems;
            s.deformation = project.deformation;
            s.deformations = project.deformations;
            s.layers = project.layers;
            s.parameters = project.parameters;
            s.outputDir = project.outputDir;
            s.projectPath = project.projectPath;
            s.logMessages = project.logMessages;
            s.spatialReference = project.spatialReference;
            s.layerStyles = project.layerStyles;
            s.layerDataRefs = project.layerDataRefs;
            s.toolDefaults = project.toolDefaults;
            s.toolHistory = project.toolHistory;
            s.activeLayer = project.activeLayer;
            s.mapToolState = project.mapToolState;
            s.viewStates = project.viewStates;
            s.activeViewId = project.activeViewId;
        end

        function deserialize(project, s)
            if isfield(s, 'name'), project.name = s.name; end
            if isfield(s, 'clouds'), project.clouds = s.clouds; end
            if isfield(s, 'cleanedClouds'), project.cleanedClouds = s.cleanedClouds; end
            if isfield(s, 'dems'), project.dems = s.dems; end
            if isfield(s, 'deformations'), project.deformations = s.deformations; end
            if isfield(s, 'deformation')
                project.deformation = s.deformation;
            else
                project.deformation = [];
            end
            if isfield(s, 'layers'), project.layers = geodem.model.ProjectState.normalizeLayerTable(s.layers); end
            if isfield(s, 'parameters'), project.parameters = s.parameters; end
            if isfield(s, 'outputDir'), project.outputDir = s.outputDir; end
            if isfield(s, 'projectPath'), project.projectPath = s.projectPath; end
            if isfield(s, 'logMessages'), project.logMessages = s.logMessages; end
            if isfield(s, 'spatialReference')
                project.spatialReference = s.spatialReference;
            else
                project.spatialReference = geodem.model.SpatialReference();
            end
            if isfield(s, 'layerStyles')
                project.layerStyles = s.layerStyles;
            else
                project.layerStyles = struct();
            end
            if isfield(s, 'layerDataRefs')
                project.layerDataRefs = s.layerDataRefs;
            else
                project.layerDataRefs = struct();
            end
            if isfield(s, 'toolDefaults')
                project.toolDefaults = s.toolDefaults;
            else
                project.toolDefaults = struct();
            end
            if isfield(s, 'toolHistory')
                project.toolHistory = s.toolHistory;
            else
                project.toolHistory = geodem.model.ToolExecutionRecord.empty(0, 1);
            end
            if isfield(s, 'activeLayer')
                project.activeLayer = s.activeLayer;
            else
                project.activeLayer = "";
            end
            if isfield(s, 'mapToolState')
                project.mapToolState = s.mapToolState;
            else
                project.mapToolState = geodem.model.MapToolState();
            end
            if isfield(s, 'viewStates')
                project.viewStates = s.viewStates;
            else
                project.viewStates = geodem.model.ProjectState.defaultViewStates();
            end
            if isfield(s, 'activeViewId')
                project.activeViewId = string(s.activeViewId);
            else
                project.activeViewId = "map";
            end
        end
    end
end
