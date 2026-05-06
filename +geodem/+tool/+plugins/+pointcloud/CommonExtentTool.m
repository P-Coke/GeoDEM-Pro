classdef CommonExtentTool
    %COMMONEXTENTTOOL Common point-cloud extent extraction plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("common_extent", "共同覆盖区", ...
                "从两个点云图层提取共同覆盖范围并输出两份裁剪点云。", ...
                "点云处理", "Extent", "clip", [
                    P("baseLayer", "输入点云 A", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("monitorLayer", "输入点云 B", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("outputPrefix", "输出前缀", "text", "共同区点云")
                ], @geodem.tool.plugins.pointcloud.CommonExtentTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.pointcloud.CommonExtentTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.pointcloud.CommonExtentTool.spec(), project, params);
            messages = geodem.tool.ToolValidator.validateDifferentParams(messages, params, "baseLayer", "monitorLayer", "两个输入点云不能相同。");
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            baseLayer = geodem.tool.ToolRegistry.requireLayer(params, "baseLayer");
            monitorLayer = geodem.tool.ToolRegistry.requireLayer(params, "monitorLayer");
            geodem.tool.ToolRegistry.assertDifferent(baseLayer, monitorLayer, "输入点云 A 和 B 不能相同。");
            cloudBase = project.getCloudByLayer(baseLayer);
            cloudMonitor = project.getCloudByLayer(monitorLayer);
            [extent, commonBase, commonMonitor] = geodem.service.pointcloud.extractCommonExtent(cloudBase, cloudMonitor);
            prefix = geodem.tool.ToolRegistry.getString(params, "outputPrefix", "共同区点云");
            commonBase.name = char(prefix + " - " + string(baseLayer));
            commonMonitor.name = char(prefix + " - " + string(monitorLayer));
            baseOut = project.addCloud(commonBase, false);
            monitorOut = project.addCloud(commonMonitor, false);
            project.parameters.commonExtent = extent;
            project.addLayerDataRef(baseOut, "pointcloud", geodem.model.ProjectState.layerKey(baseOut), "common_extent", params);
            project.addLayerDataRef(monitorOut, "pointcloud", geodem.model.ProjectState.layerKey(monitorOut), "common_extent", params);
            result = geodem.tool.ToolResult("OutputLayers", [baseOut; monitorOut], "RenderLayer", baseOut, "Presentation", "common_extent", ...
                "Messages", sprintf('共同覆盖区提取完成：%.3f m x %.3f m，共同覆盖率 %.2f%%，点云保留率 %.2f%% / %.2f%%。', ...
                extent.Width, extent.Height, 100 * extent.CommonCoverageRatio, 100 * extent.PointRetentionA, 100 * extent.PointRetentionB), "Stats", extent);
        end
    end
end
