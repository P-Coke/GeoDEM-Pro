classdef ViewState
    %VIEWSTATE Per-tab rendering and interaction state.

    properties
        ViewId = ""
        Kind = "map"
        ActiveLayer = ""
        ActiveTool = "identify"
        XLim = []
        YLim = []
        ZLim = []
        CameraView = []
        LastRenderedAt = ""
    end

    methods
        function obj = ViewState(viewId, kind)
            if nargin >= 1, obj.ViewId = string(viewId); end
            if nargin >= 2, obj.Kind = string(kind); end
        end

        function obj = touch(obj)
            obj.LastRenderedAt = string(datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat));
        end
    end
end
