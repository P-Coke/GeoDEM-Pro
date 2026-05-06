classdef ProjectDefaults
    %PROJECTDEFAULTS Centralizes default project parameters and view states.

    methods (Static)
        function params = parameters()
            params = struct();
            params.defaultPointCloudDir = 'testdata';
            params.gridResolution = 0.5;
            params.interpolationMethod = 'natural';
            params.smoothing = struct('method', 'mean', 'window', 3, 'enabled', false);
            params.cleaning = struct('method', 'percentile', 'lowerPercentile', 1, 'upperPercentile', 99, ...
                'sigma', 3, 'zMin', -Inf, 'zMax', Inf);
            params.thresholds = struct('subsidence', -0.05, 'uplift', 0.05, ...
                'severeSubsidence', -0.30, 'moderateSubsidence', -0.15, ...
                'minorSubsidence', -0.05, 'minorUplift', 0.15);
            params.contourInterval = 0.10;
            params.holeFill = struct('enabled', false, 'maxIterations', 2);
            params.profileSamples = 200;
            params.spatialReference = struct('epsgCode', [], 'name', '未知投影平面坐标', 'unit', 'meter', 'isProjected', true);
        end

        function states = viewStates()
            states = struct();
            states.map = geodem.model.ViewState("map", "map");
            states.scene = geodem.model.ViewState("scene", "scene");
            states.charts = geodem.model.ViewState("charts", "charts");
            states.compare = geodem.model.ViewState("compare", "compare");
        end
    end
end
