classdef ToolRegistry
    %TOOLREGISTRY Public facade for GeoDEM Pro geoprocessing tools.

    methods (Static)
        function specs = all()
            specs = geodem.tool.plugins.ToolPluginRegistry.allSpecs();
        end

        function spec = get(toolId)
            specs = geodem.tool.ToolRegistry.all();
            spec = [];
            for i = 1:numel(specs)
                if specs{i}.Id == string(toolId)
                    spec = specs{i};
                    return;
                end
            end
            error('GeoDEM:UnknownTool', 'Unknown tool: %s', char(toolId));
        end

        function specs = listByRibbonTab(tabName)
            allSpecs = geodem.tool.ToolRegistry.all();
            specs = {};
            for i = 1:numel(allSpecs)
                if allSpecs{i}.RibbonTab == string(tabName)
                    specs{end + 1} = allSpecs{i}; %#ok<AGROW>
                end
            end
        end

        function layerName = requireLayer(params, fieldName)
            layerName = geodem.tool.ToolRegistry.getString(params, fieldName, "");
            if strlength(layerName) == 0 || startsWith(layerName, "<")
                error('GeoDEM:MissingToolLayer', '请选择必需输入图层：%s。', char(fieldName));
            end
        end

        function assertDifferent(a, b, message)
            if string(a) == string(b)
                error('GeoDEM:SameToolInputLayer', '%s', char(message));
            end
        end

        function dem = getDemByLayer(project, layerName)
            ref = project.getLayerDataRef(layerName);
            if ~isempty(ref) && isfield(project.dems, char(ref.StorageKey))
                dem = project.dems.(char(ref.StorageKey));
                return;
            end
            key = geodem.model.ProjectState.layerKey(layerName);
            if isfield(project.dems, key)
                dem = project.dems.(key);
                return;
            end
            error('GeoDEM:DemLayerNotFound', 'DEM layer not found: %s', char(layerName));
        end

        function tf = sameDemGrid(a, b)
            tf = isequal(size(a.Z), size(b.Z));
            if ~tf
                return;
            end
            tf = max(abs(a.XGrid(1, :) - b.XGrid(1, :)), [], 'omitnan') <= 1e-6 && ...
                 max(abs(a.YGrid(:, 1) - b.YGrid(:, 1)), [], 'omitnan') <= 1e-6;
        end

        function bounds = commonDemBounds(a, b)
            bounds = struct( ...
                'XMin', max(a.bounds.XMin, b.bounds.XMin), ...
                'XMax', min(a.bounds.XMax, b.bounds.XMax), ...
                'YMin', max(a.bounds.YMin, b.bounds.YMin), ...
                'YMax', min(a.bounds.YMax, b.bounds.YMax));
            bounds.Width = bounds.XMax - bounds.XMin;
            bounds.Height = bounds.YMax - bounds.YMin;
            if bounds.Width <= 0 || bounds.Height <= 0
                error('GeoDEM:NoCommonDemExtent', '两个 DEM 没有共同覆盖范围，无法进行剖面分析。');
            end
        end

        function name = outputName(requested, inputLayer)
            requested = string(requested);
            if strlength(requested) == 0
                requested = "输出图层";
            end
            if contains(requested, string(inputLayer))
                name = requested;
            else
                name = requested + " - " + string(inputLayer);
            end
        end

        function lines = qualityReportHighlights(report)
            lines = strings(0, 1);
            wanted = ["点数","点云密度","3σ 异常点","空洞网格比例","推荐网格分辨率","推荐插值方法"];
            try
                items = string(report.("指标"));
                values = string(report.("值"));
                for i = 1:numel(wanted)
                    idx = find(items == wanted(i), 1);
                    if ~isempty(idx)
                        lines(end + 1, 1) = wanted(i) + "：" + values(idx); %#ok<AGROW>
                    end
                end
            catch
            end
        end

        function value = getString(params, fieldName, defaultValue)
            if isstruct(params) && isfield(params, char(fieldName))
                value = string(params.(char(fieldName)));
            else
                value = string(defaultValue);
            end
        end

        function value = getTextNumber(params, fieldName)
            textValue = strtrim(geodem.tool.ToolRegistry.getString(params, fieldName, ""));
            value = str2double(textValue);
            if strlength(textValue) == 0 || ~isfinite(value)
                error('GeoDEM:InvalidProfileCoordinate', '剖面坐标参数必须是有效数值：%s。', char(fieldName));
            end
        end

        function value = getNumber(params, fieldName, defaultValue)
            if isstruct(params) && isfield(params, char(fieldName)) && ~isempty(params.(char(fieldName)))
                value = double(params.(char(fieldName)));
            else
                value = double(defaultValue);
            end
        end

        function value = getLogical(params, fieldName, defaultValue)
            if isstruct(params) && isfield(params, char(fieldName))
                value = logical(params.(char(fieldName)));
            else
                value = logical(defaultValue);
            end
        end

    end
end
