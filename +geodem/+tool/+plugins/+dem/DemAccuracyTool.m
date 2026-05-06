classdef DemAccuracyTool
    %DEMACCURACYTOOL DEM cross-validation plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("dem_accuracy", "DEM 精度评价", ...
                "随机抽取验证点，对 DEM 插值结果进行 MAE/RMSE/ME/STD 交叉验证。", ...
                "DEM 构建", "评价", "chart", [
                    P("inputLayer", "输入点云", "layer", "", "LayerType", "pointcloud", "Required", true)
                    P("resolution", "分辨率/m", "numeric", 1.0, "Limits", [0.05 Inf])
                    P("method", "插值方法", "dropdown", "natural", "Items", {'natural','linear','nearest','idw'})
                    P("validationRatio", "验证比例", "numeric", 0.10, "Limits", [0.01 0.50])
                    P("maxValidation", "最大验证点", "numeric", 5000, "Limits", [20 Inf])
                    P("maxTrain", "最大训练点", "numeric", 80000, "Limits", [100 Inf])
                ], @geodem.tool.plugins.dem.DemAccuracyTool.run);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            inputLayer = geodem.tool.ToolRegistry.requireLayer(params, "inputLayer");
            cloud = project.getCloudByLayer(inputLayer);
            options = struct( ...
                'resolution', geodem.tool.ToolRegistry.getNumber(params, "resolution", 1.0), ...
                'method', geodem.tool.ToolRegistry.getString(params, "method", "natural"), ...
                'validationRatio', geodem.tool.ToolRegistry.getNumber(params, "validationRatio", 0.10), ...
                'maxValidation', geodem.tool.ToolRegistry.getNumber(params, "maxValidation", 5000), ...
                'maxTrain', geodem.tool.ToolRegistry.getNumber(params, "maxTrain", 80000));
            metrics = geodem.service.dem.demAccuracyAssessment(cloud, options);
            if ~isfield(project.parameters, 'demAccuracy')
                project.parameters.demAccuracy = struct();
            end
            key = geodem.model.ProjectState.layerKey("accuracy_" + inputLayer);
            project.parameters.demAccuracy.(key) = metrics;
            result = geodem.tool.ToolResult("Messages", sprintf('DEM 精度评价完成：RMSE %.4f m，MAE %.4f m。', metrics.RMSE(1), metrics.MAE(1)), "Stats", metrics);
        end
    end
end
