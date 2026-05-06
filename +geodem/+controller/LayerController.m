classdef LayerController < handle
    %LAYERCONTROLLER Owns visible layer view, metadata and export actions.

    properties
        App
    end

    methods
        function obj = LayerController(app)
            obj.App = app;
        end

        function renderLayer(obj, layerName)
            geodem.controller.actions.ViewModeActions.renderLayer(obj.App, layerName);
        end

        function zoomToLayer(obj, layerName)
            geodem.controller.actions.ViewModeActions.zoomToLayer(obj.App, obj.defaultLayerName(layerName));
        end

        function showOnlyLayer(obj, layerName)
            geodem.controller.actions.ViewModeActions.renderLayer(obj.App, obj.defaultLayerName(layerName));
        end

        function hideLayer(obj, layerName)
            geodem.controller.actions.ViewModeActions.hideLayer(obj.App, obj.defaultLayerName(layerName));
        end

        function openAttributeTable(obj, layerName)
            layerName = obj.defaultLayerName(layerName);
            obj.App.runSafely(@() geodem.controller.actions.LayerActions.openAttributeTable(obj.App, layerName));
        end

        function showLayerInfo(obj, layerName)
            layerName = obj.defaultLayerName(layerName);
            obj.App.runSafely(@() geodem.controller.actions.LayerActions.showInfo(obj.App, layerName));
        end

        function renameLayer(obj, layerName)
            geodem.controller.actions.LayerUiActions.rename(obj.App, obj.defaultLayerName(layerName));
        end

        function deleteLayer(obj, layerName)
            geodem.controller.actions.LayerUiActions.delete(obj.App, obj.defaultLayerName(layerName));
        end

        function exportLayer(obj, layerName)
            geodem.controller.actions.LayerUiActions.exportData(obj.App, obj.defaultLayerName(layerName));
        end
    end

    methods (Access = private)
        function layerName = defaultLayerName(obj, layerName)
            if nargin < 2 || isempty(layerName) || strlength(string(layerName)) == 0
                layerName = obj.App.Project.activeLayer;
            end
            layerName = string(layerName);
        end
    end
end
