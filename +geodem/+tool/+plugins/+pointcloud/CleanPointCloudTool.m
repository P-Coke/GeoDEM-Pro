classdef CleanPointCloudTool
    %CLEANPOINTCLOUDTOOL Single-layer outlier removal plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("clean_pointcloud", "异常点剔除", ...
                "对一个点云图层执行独立清洗，不依赖基准/监测配对。", ...
                "点云处理", "Quality", "clean", [
                    P("inputLayer", "输入点云", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("method", "剔除方法", "dropdown", "percentile", "Items", {'percentile','sigma','threshold','none'})
                    P("lowerPercentile", "下百分位", "numeric", 1, "Limits", [0 100])
                    P("upperPercentile", "上百分位", "numeric", 99, "Limits", [0 100])
                    P("sigma", "Sigma", "numeric", 3, "Limits", [0.1 Inf])
                    P("zMin", "Z 最小值", "numeric", -1.0e9)
                    P("zMax", "Z 最大值", "numeric", 1.0e9)
                    P("outputLayer", "输出图层", "text", "清洗点云")
                ], @geodem.tool.plugins.pointcloud.CleanPointCloudTool.run);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            inputLayer = geodem.tool.ToolRegistry.requireLayer(params, "inputLayer");
            cloud = project.getCloudByLayer(inputLayer);
            cleanSpec = project.parameters.cleaning;
            cleanSpec.method = char(geodem.tool.ToolRegistry.getString(params, "method", cleanSpec.method));
            cleanSpec.lowerPercentile = geodem.tool.ToolRegistry.getNumber(params, "lowerPercentile", cleanSpec.lowerPercentile);
            cleanSpec.upperPercentile = geodem.tool.ToolRegistry.getNumber(params, "upperPercentile", cleanSpec.upperPercentile);
            cleanSpec.sigma = geodem.tool.ToolRegistry.getNumber(params, "sigma", cleanSpec.sigma);
            cleanSpec.zMin = geodem.tool.ToolRegistry.getNumber(params, "zMin", cleanSpec.zMin);
            cleanSpec.zMax = geodem.tool.ToolRegistry.getNumber(params, "zMax", cleanSpec.zMax);
            [cleanCloud, report] = geodem.service.pointcloud.cleanPointCloud(cloud, cleanSpec.method, cleanSpec);
            requested = geodem.tool.ToolRegistry.getString(params, "outputLayer", "清洗点云");
            layerBase = geodem.tool.ToolRegistry.outputName(requested, inputLayer);
            cleanCloud.name = char(layerBase);
            layerName = project.addCloud(cleanCloud, false);
            project.addLayerDataRef(layerName, "pointcloud", geodem.model.ProjectState.layerKey(layerName), "clean_pointcloud", params);
            result = geodem.tool.ToolResult("OutputLayers", layerName, "RenderLayer", layerName, ...
                "Messages", sprintf('异常点剔除完成：%s -> %s，移除 %d 点，剩余 %d 点。', inputLayer, layerName, report.RemovedPointCount, report.RemainingPointCount), ...
                "Stats", report);
        end
    end
end
