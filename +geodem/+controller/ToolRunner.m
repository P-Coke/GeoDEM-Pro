classdef ToolRunner
    %TOOLRUNNER Runs selected geoprocessing tools and handles UI updates.

    methods (Static)
        function run(controller, toolId, params)
            spec = geodem.tool.ToolRegistry.get(toolId);
            [isValid, validationMessages] = spec.validate(controller.Project, params);
            if ~isValid
                error('GeoDEM:InvalidToolParameters', '%s', strjoin(validationMessages, newline));
            end
            controller.View.updateProgress(0.12, "检查参数");
            startTime = datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat);
            timer = tic;
            inputLayers = geodem.controller.ToolRunner.collectInputLayers(params);
            try
                visibleLayers = strings(0, 1);
                if ~isempty(controller.Project.layers)
                    visibleLayers = controller.Project.layers.Name(controller.Project.layers.Visible);
                end
                controller.View.updateProgress(0.25, "运行 " + string(spec.Name));
                context = geodem.tool.ToolContext(controller.Project, controller.ProjectRoot, controller.Project.outputDir, controller.Project.activeLayer, visibleLayers, @(msg) controller.log(msg));
                result = spec.execute(context, params);
                controller.View.updateProgress(0.72, "整理结果");
                duration = toc(timer);
                endTime = datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat);
                key = matlab.lang.makeValidName(char(spec.Id));
                controller.Project.toolDefaults.(key) = params;
                record = geodem.model.ToolExecutionRecord(spec.Id, spec.Name, "完成", string(startTime), string(endTime), duration, params, inputLayers, result.OutputLayers, result.Messages, "");
                controller.Project.recordToolExecution(record);
                for i = 1:numel(result.Messages)
                    controller.log(result.Messages(i));
                end
                for i = 1:numel(result.Warnings)
                    controller.log("警告：" + result.Warnings(i));
                end
                controller.View.updateProgress(0.88, "刷新界面");
                controller.updateView();
                geodem.controller.ToolRunner.presentResult(controller, spec, result);
            catch ME
                duration = toc(timer);
                endTime = datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat);
                record = geodem.model.ToolExecutionRecord(spec.Id, spec.Name, "错误", string(startTime), string(endTime), duration, params, inputLayers, strings(0, 1), strings(0, 1), ME.message);
                controller.Project.recordToolExecution(record);
                controller.updateView();
                rethrow(ME);
            end
        end

        function presentResult(controller, spec, result)
            if result.Presentation == "profile" && istable(result.Stats)
                controller.View.renderProfile(result.Stats);
            elseif result.Presentation == "common_extent" && isstruct(result.Stats)
                controller.View.setStats(geodem.controller.ToolRunner.commonExtentLines(result.Stats));
            elseif istable(result.Stats)
                controller.View.showTable(result.Stats, char(spec.Name));
                controller.View.setStats(geodem.controller.ToolRunner.statsToLines(result.Stats));
            elseif strlength(result.RenderLayer) > 0
                controller.renderLayer(result.RenderLayer);
            end
        end

        function layers = collectInputLayers(params)
            layers = strings(0, 1);
            if ~isstruct(params)
                return;
            end
            names = fieldnames(params);
            for i = 1:numel(names)
                name = string(names{i});
                if contains(lower(name), "layer")
                    value = string(params.(names{i}));
                    if strlength(value) > 0 && ~startsWith(value, "<")
                        layers(end + 1, 1) = value; %#ok<AGROW>
                    end
                end
            end
            layers = unique(layers, 'stable');
        end

        function lines = statsToLines(stats)
            lines = strings(0, 1);
            if ~istable(stats) || height(stats) == 0
                return;
            end
            vars = string(stats.Properties.VariableNames);
            if all(ismember(["指标","值"], vars))
                n = min(height(stats), 14);
                for i = 1:n
                    lines(end + 1, 1) = string(stats.("指标")(i)) + "：" + string(stats.("值")(i)); %#ok<AGROW>
                end
                return;
            end
            for j = 1:numel(vars)
                value = stats{1, char(vars(j))};
                if isnumeric(value)
                    if isscalar(value)
                        valueText = string(sprintf('%.4g', value));
                    else
                        valueText = "[" + strjoin(string(size(value)), "x") + "]";
                    end
                else
                    valueText = string(value);
                end
                lines(end + 1, 1) = vars(j) + "：" + valueText; %#ok<AGROW>
            end
        end

        function lines = commonExtentLines(extent)
            lines = [
                "共同覆盖区"
                "X 范围：" + sprintf('%.3f - %.3f m', extent.XMin, extent.XMax)
                "Y 范围：" + sprintf('%.3f - %.3f m', extent.YMin, extent.YMax)
                "面积：" + sprintf('%.2f m²', extent.Area)
                "共同覆盖率：" + sprintf('%.2f%%', 100 * geodem.controller.ToolRunner.getStructField(extent, 'CommonCoverageRatio', NaN))
                "点云 A 保留率：" + sprintf('%.2f%%', 100 * geodem.controller.ToolRunner.getStructField(extent, 'PointRetentionA', NaN))
                "点云 B 保留率：" + sprintf('%.2f%%', 100 * geodem.controller.ToolRunner.getStructField(extent, 'PointRetentionB', NaN))
                ];
        end

        function value = getStructField(s, fieldName, defaultValue)
            if isstruct(s) && isfield(s, fieldName)
                value = s.(fieldName);
            else
                value = defaultValue;
            end
        end
    end
end
