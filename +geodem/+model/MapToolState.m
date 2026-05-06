classdef MapToolState
    %MAPTOOLSTATE Stores active map interaction mode and last results.

    properties
        activeTool
        cursorMode
        selectedLayer
        lastIdentifyResult
        measurePoints
        lastDistance
    end

    methods
        function obj = MapToolState(activeTool, selectedLayer)
            if nargin < 1 || isempty(activeTool)
                activeTool = "none";
            end
            if nargin < 2
                selectedLayer = "";
            end
            obj.activeTool = string(activeTool);
            obj.cursorMode = "arrow";
            obj.selectedLayer = string(selectedLayer);
            obj.lastIdentifyResult = struct();
            obj.measurePoints = zeros(0, 2);
            obj.lastDistance = NaN;
        end
    end
end
