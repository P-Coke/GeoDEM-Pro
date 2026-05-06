classdef ToolParameterSpec
    %TOOLPARAMETERSPEC Declarative parameter definition for one GIS tool.

    properties
        Name = ""
        Label = ""
        Type = "text"
        DefaultValue = []
        Items = {}
        LayerType = ""
        Required = false
        Tooltip = ""
        Limits = []
    end

    methods
        function obj = ToolParameterSpec(name, label, typeName, defaultValue, varargin)
            if nargin >= 1, obj.Name = string(name); end
            if nargin >= 2, obj.Label = string(label); end
            if nargin >= 3, obj.Type = string(typeName); end
            if nargin >= 4, obj.DefaultValue = defaultValue; end
            for i = 1:2:numel(varargin)
                key = string(varargin{i});
                value = varargin{i + 1};
                switch key
                    case "Items"
                        obj.Items = value;
                    case "LayerType"
                        obj.LayerType = string(value);
                    case "Required"
                        obj.Required = logical(value);
                    case "Tooltip"
                        obj.Tooltip = string(value);
                    case "Limits"
                        obj.Limits = value;
                end
            end
        end
    end
end
