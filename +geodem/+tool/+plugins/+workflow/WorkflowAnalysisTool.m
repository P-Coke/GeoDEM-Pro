classdef WorkflowAnalysisTool
    %WORKFLOWANALYSISTOOL Full point-cloud to deformation workflow plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("workflow_analysis", "一键工作流", ...
                "按当前选择点云串联清洗、共同区、DEM、差分和统计。", ...
                "成果输出", "Workflow", "spark", [
                    P("baseLayer", "基准点云", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("monitorLayer", "监测点云", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("resolution", "分辨率/m", "numeric", 0.5, "Limits", [0.05 Inf])
                    P("method", "插值方法", "dropdown", "natural", "Items", {'natural','linear','nearest','idw','cubic'})
                    P("cleanMethod", "清洗方法", "dropdown", "percentile", "Items", {'percentile','sigma','threshold','none'})
                    P("subsidence", "沉降阈值/m", "numeric", -0.05)
                    P("uplift", "抬升阈值/m", "numeric", 0.05)
                    P("contourInterval", "等值线间隔/m", "numeric", 0.10, "Limits", [0.001 Inf])
                    P("outputPrefix", "输出前缀", "text", "Analysis")
                ], @geodem.tool.plugins.workflow.WorkflowAnalysisTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.workflow.WorkflowAnalysisTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.workflow.WorkflowAnalysisTool.spec(), project, params);
            messages = geodem.tool.ToolValidator.validateDifferentParams(messages, params, "baseLayer", "monitorLayer", "两个输入点云不能相同。");
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            baseLayer = geodem.tool.ToolRegistry.requireLayer(params, "baseLayer");
            monitorLayer = geodem.tool.ToolRegistry.requireLayer(params, "monitorLayer");
            geodem.tool.ToolRegistry.assertDifferent(baseLayer, monitorLayer, "基准点云和监测点云不能相同。");
            qualityParams = struct('inputLayer', baseLayer, 'cellSize', 5.0, 'sigma', 3.0);
            geodem.tool.plugins.pointcloud.PointCloudQualityTool.run(ctx, qualityParams);
            qualityParams.inputLayer = monitorLayer;
            geodem.tool.plugins.pointcloud.PointCloudQualityTool.run(ctx, qualityParams);
            cleanParams = struct('inputLayer', baseLayer, 'method', geodem.tool.ToolRegistry.getString(params, "cleanMethod", "percentile"), 'outputLayer', "清洗点云");
            cleanResultA = geodem.tool.plugins.pointcloud.CleanPointCloudTool.run(ctx, cleanParams);
            cleanParams.inputLayer = monitorLayer;
            cleanResultB = geodem.tool.plugins.pointcloud.CleanPointCloudTool.run(ctx, cleanParams);
            cleanBaseLayer = cleanResultA.RenderLayer;
            cleanMonitorLayer = cleanResultB.RenderLayer;
            commonParams = struct('baseLayer', cleanBaseLayer, 'monitorLayer', cleanMonitorLayer, 'outputPrefix', "共同区点云");
            commonResult = geodem.tool.plugins.pointcloud.CommonExtentTool.run(ctx, commonParams);
            densityParams = struct('inputLayer', commonResult.OutputLayers(1), 'cellSize', 5.0, 'outputLayer', "点云密度图");
            densityResult = geodem.tool.plugins.pointcloud.DensityGridTool.run(ctx, densityParams);
            demParams = struct('inputLayer', cleanBaseLayer, 'extentMode', "common_extent", 'resolution', geodem.tool.ToolRegistry.getNumber(params, "resolution", 0.5), ...
                'method', geodem.tool.ToolRegistry.getString(params, "method", "natural"), 'smoothEnabled', false, 'holeFillEnabled', false, 'outputLayer', "DEM");
            demResultA = geodem.tool.plugins.dem.BuildDemTool.run(ctx, demParams);
            demParams.inputLayer = cleanMonitorLayer;
            demResultB = geodem.tool.plugins.dem.BuildDemTool.run(ctx, demParams);
            diffParams = struct('baseDemLayer', demResultA.RenderLayer, 'monitorDemLayer', demResultB.RenderLayer, ...
                'gridHandling', "auto_align", ...
                'subsidence', geodem.tool.ToolRegistry.getNumber(params, "subsidence", -0.05), ...
                'uplift', geodem.tool.ToolRegistry.getNumber(params, "uplift", 0.05), ...
                'contourInterval', geodem.tool.ToolRegistry.getNumber(params, "contourInterval", 0.10), ...
                'outputPrefix', geodem.tool.ToolRegistry.getString(params, "outputPrefix", "Analysis"));
            diffResult = geodem.tool.plugins.deformation.DemDifferenceTool.run(ctx, diffParams);
            outputs = [cleanResultA.OutputLayers; cleanResultB.OutputLayers; commonResult.OutputLayers; densityResult.OutputLayers; demResultA.OutputLayers; demResultB.OutputLayers; diffResult.OutputLayers];
            activeResult = project.activeDeformation();
            result = geodem.tool.ToolResult("OutputLayers", outputs, "RenderLayer", diffResult.RenderLayer, ...
                "Messages", ["一键工作流完成：体检、清洗、共同区、密度、DEM 构建、DEM 作差和专题图层已生成。"; geodem.service.deformation.summarizeDeformation(activeResult)], "Stats", activeResult.stats);
        end
    end
end
