classdef ToolResult
    %TOOLRESULT Standard result envelope returned by geoprocessing tools.

    properties
        OutputLayers = strings(0, 1)
        RenderLayer = ""
        Messages = strings(0, 1)
        Warnings = strings(0, 1)
        Stats = []
        Presentation = "auto"
    end

    methods
        function obj = ToolResult(varargin)
            for i = 1:2:numel(varargin)
                key = string(varargin{i});
                value = varargin{i + 1};
                switch key
                    case "OutputLayers"
                        obj.OutputLayers = string(value);
                    case "RenderLayer"
                        obj.RenderLayer = string(value);
                    case "Messages"
                        obj.Messages = string(value);
                    case "Warnings"
                        obj.Warnings = string(value);
                    case "Stats"
                        obj.Stats = value;
                    case "Presentation"
                        obj.Presentation = string(value);
                end
            end
        end

        function obj = addMessage(obj, message)
            obj.Messages(end + 1, 1) = string(message);
        end

        function obj = addLayer(obj, layerName)
            obj.OutputLayers(end + 1, 1) = string(layerName);
            obj.RenderLayer = string(layerName);
        end
    end
end
