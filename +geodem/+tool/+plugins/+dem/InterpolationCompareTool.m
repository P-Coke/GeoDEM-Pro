classdef InterpolationCompareTool
    %INTERPOLATIONCOMPARETOOL DEM interpolation method comparison plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("compare_methods", "插值对比", ...
                "比较 nearest/linear/natural 插值结果。", ...
                "DEM 构建", "Methods", "interpolate", [
                    P("baseLayer", "输入点云 A", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("monitorLayer", "输入点云 B", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("resolution", "分辨率/m", "numeric", 1.0, "Limits", [0.05 Inf])
                    P("includeIdw", "包含 IDW", "logical", false)
                ], @geodem.tool.plugins.dem.InterpolationCompareTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.dem.InterpolationCompareTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.dem.InterpolationCompareTool.spec(), project, params);
            messages = geodem.tool.ToolValidator.validateDifferentParams(messages, params, "baseLayer", "monitorLayer", "两个输入点云不能相同。");
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            baseLayer = geodem.tool.ToolRegistry.requireLayer(params, "baseLayer");
            monitorLayer = geodem.tool.ToolRegistry.requireLayer(params, "monitorLayer");
            geodem.tool.ToolRegistry.assertDifferent(baseLayer, monitorLayer, "输入点云 A 和 B 不能相同。");
            [extent, commonBase, commonMonitor] = geodem.service.pointcloud.extractCommonExtent(project.getCloudByLayer(baseLayer), project.getCloudByLayer(monitorLayer));
            thresholds = project.parameters.thresholds;
            thresholds.contourInterval = project.parameters.contourInterval;
            gridSpec = struct('extent', extent, 'resolution', geodem.tool.ToolRegistry.getNumber(params, "resolution", 1.0), 'holeFill', project.parameters.holeFill);
            methods = {'nearest','linear','natural'};
            if geodem.tool.ToolRegistry.getLogical(params, "includeIdw", false)
                methods{end + 1} = 'idw';
            end
            comparison = geodem.service.dem.compareInterpolationMethods(commonBase, commonMonitor, gridSpec, methods, struct('enabled', false), thresholds);
            project.parameters.interpolationComparison = comparison;
            result = geodem.tool.ToolResult("Messages", "插值方法对比完成。", "Stats", comparison.Summary);
        end
    end
end
