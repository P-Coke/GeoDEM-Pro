classdef LayerDataRef
    %LAYERDATAREF Metadata linking a UI layer to generated data and source tool.

    properties
        LayerName = ""
        LayerType = ""
        StorageKey = ""
        SourceToolId = ""
        SourceParams = struct()
        CreatedAt = ""
        StyleKey = ""
    end

    methods
        function obj = LayerDataRef(layerName, layerType, storageKey, sourceToolId, sourceParams, styleKey)
            if nargin >= 1, obj.LayerName = string(layerName); end
            if nargin >= 2, obj.LayerType = string(layerType); end
            if nargin >= 3, obj.StorageKey = string(storageKey); end
            if nargin >= 4, obj.SourceToolId = string(sourceToolId); end
            if nargin >= 5, obj.SourceParams = sourceParams; end
            if nargin >= 6, obj.StyleKey = string(styleKey); end
            obj.CreatedAt = string(datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat));
        end
    end
end
