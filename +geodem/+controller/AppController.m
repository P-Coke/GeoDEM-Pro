classdef AppController < handle
    %APPCONTROLLER Coordinates UI events, project state, and service calls.

    properties
        ProjectRoot
        Project
        View
        SelectedToolId = ""
        ProjectController
        ToolController
        LayerController
        MapController
    end

    methods
        function obj = AppController(projectRoot)
            if nargin < 1 || isempty(projectRoot)
                projectRoot = pwd;
            end
            obj.ProjectRoot = projectRoot;
            obj.Project = geodem.model.ProjectState(projectRoot);
            obj.View = geodem.view.MainView(obj);
            obj.ProjectController = geodem.controller.ProjectController(obj);
            obj.ToolController = geodem.controller.ToolController(obj);
            obj.LayerController = geodem.controller.LayerController(obj);
            obj.MapController = geodem.controller.MapController(obj);
            obj.log('就绪：导入数据或运行一键工作流。');
            obj.updateView();
            obj.selectTool("workflow_analysis");
        end

        function newProject(obj), obj.ProjectController.newProject(); end
        function openProject(obj), obj.ProjectController.openProject(); end
        function saveProject(obj), obj.ProjectController.saveProject(); end
        function saveProjectAs(obj), obj.ProjectController.saveProjectAs(); end
        function target = chooseProjectSavePath(obj, dialogTitle), target = obj.ProjectController.chooseProjectSavePath(dialogTitle); end
        function clearWorkspace(obj), obj.ProjectController.clearWorkspace(); end
        function importCloud(obj, varargin), obj.ProjectController.importCloud(varargin{:}); end
        function importLasCloud(obj, varargin), obj.ProjectController.importLasCloud(varargin{:}); end
        function importDem(obj), obj.ProjectController.importDem(); end
        function showCloudProperties(obj), obj.ProjectController.showCloudProperties(); end

        function preprocessClouds(obj), obj.ToolController.preprocessClouds(); end
        function extractCommonArea(obj), obj.ToolController.extractCommonArea(); end
        function buildDems(obj), obj.ToolController.buildDems(); end
        function analyzeDeformation(obj), obj.ToolController.analyzeDeformation(); end
        function runOneClick(obj), obj.ToolController.runOneClick(); end
        function exportResults(obj), obj.ToolController.exportResults(); end
        function generateReport(obj), obj.ToolController.generateReport(); end
        function exportGeoTiff(obj), obj.ToolController.exportGeoTiff(); end
        function exportShapefile(obj), obj.ToolController.exportShapefile(); end
        function compareMethods(obj), obj.ToolController.compareMethods(); end
        function runProfile(obj), obj.ToolController.runProfile(); end
        function activateProfileAnalysis(obj), obj.ToolController.activateProfileAnalysis(); end
        function selectTool(obj, toolId), obj.ToolController.selectTool(toolId); end
        function resetSelectedToolDefaults(obj), obj.ToolController.resetSelectedToolDefaults(); end
        function runSelectedTool(obj, varargin), obj.ToolController.runSelectedTool(varargin{:}); end
        function runTool(obj, toolId, params), obj.ToolController.runTool(toolId, params); end

        function renderLayer(obj, layerName), obj.LayerController.renderLayer(layerName); end
        function zoomToLayer(obj, varargin), obj.LayerController.zoomToLayer(layerArg(varargin)); end
        function showOnlyLayer(obj, varargin), obj.LayerController.showOnlyLayer(layerArg(varargin)); end
        function hideLayer(obj, varargin), obj.LayerController.hideLayer(layerArg(varargin)); end
        function openAttributeTable(obj, varargin), obj.LayerController.openAttributeTable(layerArg(varargin)); end
        function showLayerInfo(obj, varargin), obj.LayerController.showLayerInfo(layerArg(varargin)); end
        function renameLayer(obj, varargin), obj.LayerController.renameLayer(layerArg(varargin)); end
        function deleteLayer(obj, varargin), obj.LayerController.deleteLayer(layerArg(varargin)); end
        function exportLayer(obj, varargin), obj.LayerController.exportLayer(layerArg(varargin)); end

        function setActiveMapTool(obj, toolName), obj.MapController.setActiveMapTool(toolName); end
        function handleMapClick(obj, x, y), obj.MapController.handleMapClick(x, y); end
        function syncLayerVisibility(obj, checkedLayerNames), obj.MapController.syncLayerVisibility(checkedLayerNames); end
        function setViewMode(obj, mode), obj.MapController.setViewMode(mode); end
        function showActiveDeformation(obj), obj.MapController.showActiveDeformation(); end
        function set3DView(obj, mode), obj.MapController.set3DView(mode); end

        function log(obj, message)
            if shouldSuppressMessage(message)
                return;
            end
            obj.Project.addLog(message);
            if ~isempty(obj.View) && isvalid(obj.View)
                obj.View.setLog(obj.Project.logMessages);
            end
        end

        function updateView(obj)
            obj.View.setLayers(obj.Project.layers);
            obj.View.setLog(obj.Project.logMessages);
            obj.View.updateStatsFromProject(obj.Project);
            obj.View.updateToolHistory(obj.Project);
            obj.View.updateStatusBar(obj.Project, [], "就绪");
        end

        function runSafely(obj, fn)
            try
                obj.View.setBusy(true);
                fn();
            catch ME
                obj.log(['错误：' ME.message]);
                uialert(obj.View.UIFigure, ME.message, 'GeoDEM Pro 错误');
            end
            obj.View.setBusy(false);
        end
    end
end

function layerName = layerArg(args)
if isempty(args)
    layerName = [];
else
    layerName = args{1};
end
end

function tf = shouldSuppressMessage(message)
message = strtrim(string(message));
tf = strlength(message) == 0 || ...
     startsWith(message, "已选择工具：") || ...
     startsWith(message, "当前地图工具：");
end
