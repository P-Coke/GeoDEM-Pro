classdef DensityGridTool
    %DENSITYGRIDTOOL Point-cloud density grid plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("density_grid", "点云密度", ...
                "统计单个点云图层的网格点密度。", ...
                "点云处理", "Quality", "density", [
                    P("inputLayer", "输入点云", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("cellSize", "网格大小/m", "numeric", 5.0, "Limits", [0.05 Inf])
                    P("outputLayer", "输出图层", "text", "点云密度图")
                ], @geodem.tool.plugins.pointcloud.DensityGridTool.run);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            inputLayer = geodem.tool.ToolRegistry.requireLayer(params, "inputLayer");
            cloud = project.getCloudByLayer(inputLayer);
            cellSize = geodem.tool.ToolRegistry.getNumber(params, "cellSize", 5.0);
            density = geodem.service.pointcloud.computeDensityGrid(cloud, cellSize, cloud.bounds);
            requested = geodem.tool.ToolRegistry.getString(params, "outputLayer", "点云密度图");
            layerName = project.uniqueLayerName(geodem.tool.ToolRegistry.outputName(requested, inputLayer));
            key = geodem.model.ProjectState.layerKey(layerName);
            if ~isfield(project.parameters, 'density')
                project.parameters.density = struct();
            end
            project.parameters.density.(key) = density;
            project.addLayer(layerName, "density", true);
            project.addLayerDataRef(layerName, "density", key, "density_grid", params);
            result = geodem.tool.ToolResult("OutputLayers", layerName, "RenderLayer", layerName, ...
                "Messages", sprintf('点云密度分析完成：%s，网格 %.3f m。', inputLayer, cellSize), "Stats", density);
        end
    end
end
