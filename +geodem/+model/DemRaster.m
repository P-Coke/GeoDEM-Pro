classdef DemRaster
    %DEMRASTER Regular-grid DEM raster model.

    properties
        XGrid
        YGrid
        Z
        resolution
        method
        bounds
        mask
        qualityMetrics
        name
    end

    methods
        function obj = DemRaster(XGrid, YGrid, Z, resolution, method, name)
            if nargin < 1
                XGrid = [];
                YGrid = [];
                Z = [];
            end
            if nargin < 4 || isempty(resolution)
                resolution = NaN;
            end
            if nargin < 5
                method = "";
            end
            if nargin < 6
                name = "";
            end

            obj.XGrid = XGrid;
            obj.YGrid = YGrid;
            obj.Z = Z;
            obj.resolution = resolution;
            obj.method = char(method);
            obj.name = char(name);
            obj.mask = isfinite(Z);
            obj.bounds = obj.computeBounds();
            obj.qualityMetrics = obj.computeMetrics();
        end

        function bounds = computeBounds(obj)
            if isempty(obj.XGrid) || isempty(obj.YGrid)
                bounds = struct('XMin', NaN, 'XMax', NaN, 'YMin', NaN, 'YMax', NaN, 'Width', 0, 'Height', 0);
                return;
            end
            bounds = struct( ...
                'XMin', min(obj.XGrid(:)), 'XMax', max(obj.XGrid(:)), ...
                'YMin', min(obj.YGrid(:)), 'YMax', max(obj.YGrid(:)), ...
                'Width', max(obj.XGrid(:)) - min(obj.XGrid(:)), ...
                'Height', max(obj.YGrid(:)) - min(obj.YGrid(:)));
        end

        function metrics = computeMetrics(obj)
            z = obj.Z;
            valid = isfinite(z);
            n = numel(z);
            nv = sum(valid(:));
            if nv == 0
                metrics = struct('Rows', size(z, 1), 'Cols', size(z, 2), 'CellCount', n, ...
                    'ValidCellCount', 0, 'NanCellCount', n, 'NanRatio', 1, ...
                    'Min', NaN, 'Max', NaN, 'Mean', NaN, 'Std', NaN);
                return;
            end
            zv = z(valid);
            metrics = struct( ...
                'Rows', size(z, 1), ...
                'Cols', size(z, 2), ...
                'CellCount', n, ...
                'ValidCellCount', nv, ...
                'NanCellCount', n - nv, ...
                'NanRatio', (n - nv) / max(n, 1), ...
                'Min', min(zv), ...
                'Max', max(zv), ...
                'Mean', mean(zv), ...
                'Std', std(zv));
        end

        function summary = summaryTable(obj)
            summary = table(string(obj.name), string(obj.method), obj.resolution, ...
                obj.qualityMetrics.Rows, obj.qualityMetrics.Cols, ...
                obj.qualityMetrics.ValidCellCount, obj.qualityMetrics.NanRatio, ...
                obj.qualityMetrics.Min, obj.qualityMetrics.Max, obj.qualityMetrics.Mean, obj.qualityMetrics.Std, ...
                'VariableNames', {'Name','Method','Resolution','Rows','Cols','ValidCells','NanRatio','Min','Max','Mean','Std'});
        end
    end
end
