classdef LayerInfoService
    %LAYERINFOSERVICE Centralized layer metadata and style helpers.

    methods (Static)
        function tbl = infoTable(project, layerName)
            idx = find(project.layers.Name == string(layerName), 1);
            row = project.layers(idx, :);
            items = strings(0, 1);
            values = strings(0, 1);
            add("名称", row.Name);
            add("类型", row.Type);
            add("分组", row.Group);
            add("可见", string(row.Visible));
            add("当前激活", string(project.activeLayer == string(layerName)));
            style = geodem.service.layer.LayerInfoService.getStyle(project, layerName);
            add("透明度", sprintf('%.0f%%', 100 * style.alpha));
            add("线宽", sprintf('%.2f', style.lineWidth));
            add("点符号", style.marker);
            add("标注", string(style.labelsEnabled));
            ref = project.getLayerDataRef(layerName);
            if ~isempty(ref)
                add("数据键", ref.StorageKey);
                add("来源工具", ref.SourceToolId);
                add("创建时间", ref.CreatedAt);
                add("源参数", geodem.service.layer.LayerInfoService.sourceParamsSummary(ref.SourceParams));
            end
            sourceText = geodem.service.layer.LayerInfoService.sourceText(project, layerName);
            if strlength(sourceText) > 0
                add("数据源", sourceText);
            end
            bounds = geodem.service.layer.LayerInfoService.bounds(project, layerName, row.Type);
            if ~isempty(bounds)
                add("X 范围", sprintf('%.3f - %.3f', bounds.XMin, bounds.XMax));
                add("Y 范围", sprintf('%.3f - %.3f', bounds.YMin, bounds.YMax));
                if isfield(bounds, 'ZMin')
                    add("Z 范围", sprintf('%.3f - %.3f', bounds.ZMin, bounds.ZMax));
                end
            end
            tbl = table(items, values, 'VariableNames', {'属性','值'});

            function add(item, value)
                items(end + 1, 1) = string(item);
                values(end + 1, 1) = string(value);
            end
        end

        function lines = formatLines(tbl)
            lines = strings(min(height(tbl), 12), 1);
            for i = 1:numel(lines)
                lines(i) = tbl.("属性")(i) + "：" + tbl.("值")(i);
            end
        end

        function bounds = bounds(project, layerName, typeName)
            bounds = [];
            switch string(typeName)
                case "pointcloud"
                    bounds = project.getCloudByLayer(layerName).bounds;
                case "dem"
                    dem = geodem.tool.ToolRegistry.getDemByLayer(project, layerName);
                    bounds = dem.bounds;
                case "density"
                    density = geodem.service.layer.LayerInfoService.densityForLayer(project, layerName);
                    if ~isempty(density)
                        bounds = struct('XMin', min(density.XGrid(:)), 'XMax', max(density.XGrid(:)), ...
                            'YMin', min(density.YGrid(:)), 'YMax', max(density.YGrid(:)));
                    end
                case {"deformation","classmap","contour","surface3d"}
                    result = project.getDeformationByLayer(layerName);
                    if ~isempty(result)
                        bounds = struct('XMin', min(result.XGrid(:)), 'XMax', max(result.XGrid(:)), ...
                            'YMin', min(result.YGrid(:)), 'YMax', max(result.YGrid(:)));
                    end
            end
        end

        function density = densityForLayer(project, layerName)
            density = [];
            if ~isfield(project.parameters, 'density')
                return;
            end
            ref = project.getLayerDataRef(layerName);
            if ~isempty(ref) && isfield(project.parameters.density, char(ref.StorageKey))
                density = project.parameters.density.(char(ref.StorageKey));
                return;
            end
            key = geodem.model.ProjectState.layerKey(layerName);
            if isfield(project.parameters.density, key)
                density = project.parameters.density.(key);
            end
        end

        function style = getStyle(project, layerName)
            key = geodem.model.ProjectState.layerKey(layerName);
            if isfield(project.layerStyles, key)
                style = project.layerStyles.(key);
                return;
            end
            idx = find(project.layers.Name == string(layerName), 1);
            iconName = "layer";
            if ~isempty(idx)
                iconName = project.layers.Icon(idx);
            end
            style = geodem.model.LayerStyle(iconName, [], 1, 1, "o", false);
            project.layerStyles.(key) = style;
        end

        function setStyle(project, layerName, style)
            key = geodem.model.ProjectState.layerKey(layerName);
            project.layerStyles.(key) = style;
        end

        function text = sourceText(project, layerName)
            text = "";
            layerName = string(layerName);
            idx = find(project.layers.Name == layerName, 1);
            if isempty(idx), return; end
            typeName = string(project.layers.Type(idx));
            try
                switch typeName
                    case "pointcloud"
                        cloud = project.getCloudByLayer(layerName);
                        text = string(cloud.sourcePath);
                    otherwise
                        ref = project.getLayerDataRef(layerName);
                        if ~isempty(ref) && isstruct(ref.SourceParams)
                            fields = ["filePath","sourcePath","inputLayer","baseLayer","monitorLayer","baseDemLayer","monitorDemLayer"];
                            for i = 1:numel(fields)
                                f = char(fields(i));
                                if isfield(ref.SourceParams, f) && strlength(string(ref.SourceParams.(f))) > 0
                                    text = string(ref.SourceParams.(f));
                                    return;
                                end
                            end
                            if strlength(ref.SourceToolId) > 0
                                text = "来源工具：" + ref.SourceToolId;
                            end
                        end
                end
            catch
                text = "";
            end
        end

        function text = sourceParamsSummary(params)
            text = "";
            if ~isstruct(params) || isempty(fieldnames(params))
                return;
            end
            names = fieldnames(params);
            parts = strings(0, 1);
            for i = 1:min(numel(names), 6)
                value = params.(names{i});
                if isnumeric(value) && isscalar(value)
                    valueText = string(sprintf('%.6g', value));
                elseif islogical(value) && isscalar(value)
                    valueText = string(value);
                elseif ischar(value) || isstring(value)
                    valueText = string(value);
                else
                    valueText = string(class(value));
                end
                parts(end + 1, 1) = string(names{i}) + "=" + valueText; %#ok<AGROW>
            end
            if numel(names) > 6
                parts(end + 1, 1) = "..."; %#ok<AGROW>
            end
            text = strjoin(parts, "; ");
        end

    end
end
