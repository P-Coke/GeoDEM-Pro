classdef MapController < handle
    %MAPCONTROLLER Owns map interaction mode and click handling.

    properties
        App
    end

    methods
        function obj = MapController(app)
            obj.App = app;
        end

        function setActiveMapTool(obj, toolName)
            geodem.controller.actions.ViewModeActions.setActiveMapTool(obj.App, toolName);
        end

        function handleMapClick(obj, x, y)
            geodem.controller.actions.ViewModeActions.handleMapClick(obj.App, x, y);
        end

        function syncLayerVisibility(obj, checkedLayerNames)
            geodem.controller.actions.ViewModeActions.syncLayerVisibility(obj.App, checkedLayerNames);
        end

        function setViewMode(obj, mode)
            geodem.controller.actions.ViewModeActions.setViewMode(obj.App, mode);
        end

        function showActiveDeformation(obj)
            geodem.controller.actions.ViewModeActions.showActiveDeformation(obj.App);
        end

        function set3DView(obj, mode)
            obj.App.View.set3DView(mode);
        end
    end
end
