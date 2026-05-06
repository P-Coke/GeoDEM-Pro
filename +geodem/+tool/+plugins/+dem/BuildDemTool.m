classdef BuildDemTool
    %BUILDDEMTOOL DEM interpolation plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("build_dem", "DEM 构建", ...
                "从单个点云图层构建一个 DEM 图层。", ...
                "DEM 构建", "Surface", "dem", [
                    P("inputLayer", "输入点云", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("extentMode", "范围来源", "dropdown", "layer_bounds", "Items", {'layer_bounds','common_extent'})
                    P("resolution", "分辨率/m", "numeric", 0.5, "Limits", [0.05 Inf])
                    P("method", "插值方法", "dropdown", "natural", "Items", {'natural','linear','nearest','idw','cubic'})
                    P("smoothEnabled", "启用平滑", "logical", false)
                    P("smoothMethod", "平滑方法", "dropdown", "mean", "Items", {'mean','median','none'})
                    P("smoothWindow", "平滑窗口", "numeric", 3, "Limits", [1 99])
                    P("holeFillEnabled", "填补小空洞", "logical", false)
                    P("outputLayer", "输出 DEM", "text", "DEM")
                ], @geodem.tool.plugins.dem.BuildDemTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.dem.BuildDemTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.dem.BuildDemTool.spec(), project, params);
            if isstruct(params) && isfield(params, 'resolution') && isfield(params, 'inputLayer') && strlength(string(params.inputLayer)) > 0
                try
                    cloud = project.getCloudByLayer(params.inputLayer);
                    cells = ceil((cloud.bounds.XMax - cloud.bounds.XMin) / double(params.resolution)) * ceil((cloud.bounds.YMax - cloud.bounds.YMin) / double(params.resolution));
                    if cells > 5e6
                        messages(end + 1, 1) = "分辨率过小，预计格网超过 500 万，请提高分辨率。"; %#ok<AGROW>
                    end
                    if isfield(params, 'method') && string(params.method) == "idw" && cells > 2e6
                        messages(end + 1, 1) = "IDW 计算量较大，预计格网超过 200 万，请提高分辨率或改用 natural/linear。"; %#ok<AGROW>
                    end
                catch
                end
            end
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            inputLayer = geodem.tool.ToolRegistry.requireLayer(params, "inputLayer");
            cloud = project.getCloudByLayer(inputLayer);
            extentMode = geodem.tool.ToolRegistry.getString(params, "extentMode", "layer_bounds");
            warnings = strings(0, 1);
            if extentMode == "common_extent" && isfield(project.parameters, 'commonExtent')
                extent = project.parameters.commonExtent;
                cloud = geodem.service.pointcloud.cropPointCloud(cloud, extent);
            else
                extent = cloud.bounds;
                if extentMode == "common_extent"
                    warnings(end + 1) = "尚未生成共同覆盖区，已改用输入图层范围。";
                end
            end
            resolution = geodem.tool.ToolRegistry.getNumber(params, "resolution", 0.5);
            method = geodem.tool.ToolRegistry.getString(params, "method", "natural");
            smoothing = struct('enabled', geodem.tool.ToolRegistry.getLogical(params, "smoothEnabled", false), ...
                'method', char(geodem.tool.ToolRegistry.getString(params, "smoothMethod", "mean")), ...
                'window', geodem.tool.ToolRegistry.getNumber(params, "smoothWindow", 3));
            holeFill = struct('enabled', geodem.tool.ToolRegistry.getLogical(params, "holeFillEnabled", false), 'maxIterations', 2);
            dem = geodem.service.dem.buildDem(cloud, struct('extent', extent, 'resolution', resolution, 'holeFill', holeFill), method, smoothing);
            requested = geodem.tool.ToolRegistry.getString(params, "outputLayer", "DEM");
            layerName = project.uniqueLayerName(geodem.tool.ToolRegistry.outputName(requested, inputLayer));
            dem.name = char(layerName);
            key = geodem.model.ProjectState.layerKey(layerName);
            project.dems.(key) = dem;
            project.addLayer(layerName, "dem", true);
            project.addLayerDataRef(layerName, "dem", key, "build_dem", params);
            result = geodem.tool.ToolResult("OutputLayers", layerName, "RenderLayer", layerName, ...
                "Messages", sprintf('DEM 构建完成：%s，%d x %d，方法 %s。', layerName, size(dem.Z, 2), size(dem.Z, 1), method), ...
                "Warnings", warnings, "Stats", dem.qualityMetrics);
        end
    end
end
