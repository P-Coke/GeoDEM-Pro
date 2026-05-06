classdef SpatialReference
    %SPATIALREFERENCE Minimal spatial reference metadata for GIS exports.

    properties
        epsgCode
        name
        unit
        isProjected
        notes
    end

    methods
        function obj = SpatialReference(epsgCode, name, unit, isProjected, notes)
            if nargin < 1 || isempty(epsgCode)
                epsgCode = [];
            end
            if nargin < 2 || isempty(name)
                name = "未知投影平面坐标";
            end
            if nargin < 3 || isempty(unit)
                unit = "meter";
            end
            if nargin < 4 || isempty(isProjected)
                isProjected = true;
            end
            if nargin < 5
                notes = "未指定 EPSG，按平面坐标处理。";
            end
            obj.epsgCode = epsgCode;
            obj.name = string(name);
            obj.unit = string(unit);
            obj.isProjected = logical(isProjected);
            obj.notes = string(notes);
        end

        function tf = hasEpsg(obj)
            tf = ~isempty(obj.epsgCode) && all(isfinite(obj.epsgCode));
        end

        function code = coordRefSysCode(obj)
            if obj.hasEpsg()
                code = sprintf('EPSG:%d', round(obj.epsgCode));
            else
                code = "";
            end
        end

        function txt = displayName(obj)
            if obj.hasEpsg()
                txt = sprintf('%s (EPSG:%d)', obj.name, round(obj.epsgCode));
            else
                txt = char(obj.name);
            end
        end
    end
end
