classdef DeformationResult
    %DEFORMATIONRESULT Multi-period DEM difference and classification model.

    properties
        XGrid
        YGrid
        deltaZ
        classMap
        stats
        contours
        maxSubsidencePoint
        volumeStats
        thresholds
        resolution
    end

    methods
        function obj = DeformationResult(XGrid, YGrid, deltaZ, classMap, stats, contours, maxSubsidencePoint, volumeStats, thresholds, resolution)
            if nargin < 1
                XGrid = [];
                YGrid = [];
                deltaZ = [];
                classMap = [];
            end
            if nargin < 5
                stats = struct();
                contours = [];
                maxSubsidencePoint = struct();
                volumeStats = struct();
                thresholds = struct();
                resolution = NaN;
            end
            obj.XGrid = XGrid;
            obj.YGrid = YGrid;
            obj.deltaZ = deltaZ;
            obj.classMap = classMap;
            obj.stats = stats;
            obj.contours = contours;
            obj.maxSubsidencePoint = maxSubsidencePoint;
            obj.volumeStats = volumeStats;
            obj.thresholds = thresholds;
            obj.resolution = resolution;
        end

        function tbl = statsTable(obj)
            s = obj.stats;
            v = obj.volumeStats;
            p = obj.maxSubsidencePoint;
            tbl = table( ...
                s.MaxSubsidence, s.MaxUplift, s.MeanChange, s.StdChange, ...
                s.SubsidenceArea, s.UpliftArea, s.StableArea, s.TotalValidArea, ...
                s.SubsidenceRatio, s.UpliftRatio, s.StableRatio, ...
                v.SubsidenceVolume, v.UpliftVolume, v.NetVolumeChange, ...
                p.X, p.Y, p.DeltaZ, ...
                'VariableNames', {'MaxSubsidence','MaxUplift','MeanChange','StdChange', ...
                'SubsidenceArea','UpliftArea','StableArea','TotalValidArea', ...
                'SubsidenceRatio','UpliftRatio','StableRatio', ...
                'SubsidenceVolume','UpliftVolume','NetVolumeChange', ...
                'MaxSubsidenceX','MaxSubsidenceY','MaxSubsidenceDeltaZ'});
        end
    end
end
