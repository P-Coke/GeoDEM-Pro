classdef PointCloudQualityTool
    %POINTCLOUDQUALITYTOOL Point-cloud inspection plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("pointcloud_quality", "点云质量体检", ...
                "生成点数、范围、高程统计、异常点、密度、空洞和推荐参数报告。", ...
                "点云处理", "质量", "identify", [
                    P("inputLayer", "输入点云", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("cellSize", "体检网格/m", "numeric", 5.0, "Limits", [0.05 Inf])
                    P("sigma", "异常 Sigma", "numeric", 3.0, "Limits", [0.1 Inf])
                ], @geodem.tool.plugins.pointcloud.PointCloudQualityTool.run);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            inputLayer = geodem.tool.ToolRegistry.requireLayer(params, "inputLayer");
            cloud = project.getCloudByLayer(inputLayer);
            options = struct('cellSize', geodem.tool.ToolRegistry.getNumber(params, "cellSize", 5.0), ...
                'sigma', geodem.tool.ToolRegistry.getNumber(params, "sigma", 3.0));
            report = geodem.service.pointcloud.pointCloudQualityReport(cloud, options);
            key = geodem.model.ProjectState.layerKey("quality_" + inputLayer);
            if ~isfield(project.parameters, 'qualityReports')
                project.parameters.qualityReports = struct();
            end
            project.parameters.qualityReports.(key) = report;
            result = geodem.tool.ToolResult("Messages", ["点云质量体检完成：" + string(inputLayer); geodem.tool.ToolRegistry.qualityReportHighlights(report)], "Stats", report);
        end
    end
end
