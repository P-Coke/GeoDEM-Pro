classdef DemDifferenceTool
    %DEM DIFFERENCETOOL DEM differencing and deformation layer plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("dem_difference", "DEM 作差", ...
                "对两个不同 DEM 图层执行 ΔZ = 监测 DEM - 基准 DEM。", ...
                "形变分析", "Change", "diff", [
                    P("baseDemLayer", "基准 DEM", "layer", "", "LayerType", "dem", "Required", true)
                    P("monitorDemLayer", "监测 DEM", "layer", "", "LayerType", "dem", "Required", true)
                    P("gridHandling", "网格处理", "dropdown", "auto_align", "Items", {'auto_align','strict'})
                    P("subsidence", "沉降阈值/m", "numeric", -0.05)
                    P("uplift", "抬升阈值/m", "numeric", 0.05)
                    P("contourInterval", "等值线间隔/m", "numeric", 0.10, "Limits", [0.001 Inf])
                    P("outputPrefix", "输出前缀", "text", "DEM 差值图")
                ], @geodem.tool.plugins.deformation.DemDifferenceTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.deformation.DemDifferenceTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.deformation.DemDifferenceTool.spec(), project, params);
            messages = geodem.tool.ToolValidator.validateDifferentParams(messages, params, "baseDemLayer", "monitorDemLayer", "两个 DEM 图层不能相同。");
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            baseLayer = geodem.tool.ToolRegistry.requireLayer(params, "baseDemLayer");
            monitorLayer = geodem.tool.ToolRegistry.requireLayer(params, "monitorDemLayer");
            geodem.tool.ToolRegistry.assertDifferent(baseLayer, monitorLayer, "基准 DEM 和监测 DEM 不能相同。");
            demBase = geodem.tool.ToolRegistry.getDemByLayer(project, baseLayer);
            demMonitor = geodem.tool.ToolRegistry.getDemByLayer(project, monitorLayer);
            gridHandling = geodem.tool.ToolRegistry.getString(params, "gridHandling", "auto_align");
            warnings = strings(0, 1);
            if ~geodem.tool.ToolRegistry.sameDemGrid(demBase, demMonitor)
                if gridHandling == "strict"
                    error('GeoDEM:DemGridMismatch', '两个 DEM 的行列数或 X/Y 网格坐标不同。请在共同覆盖区和同一分辨率下构建 DEM，或将“网格处理”设为 auto_align。');
                end
                [demMonitor, didAlign] = geodem.service.dem.alignDemToReference(demBase, demMonitor, 'linear');
                if didAlign
                    warnings(end + 1, 1) = "监测 DEM 网格与基准 DEM 不一致，已自动重采样到基准 DEM 网格。";
                end
            end
            thresholds = project.parameters.thresholds;
            thresholds.subsidence = geodem.tool.ToolRegistry.getNumber(params, "subsidence", -0.05);
            thresholds.uplift = geodem.tool.ToolRegistry.getNumber(params, "uplift", 0.05);
            thresholds.contourInterval = geodem.tool.ToolRegistry.getNumber(params, "contourInterval", 0.10);
            prefix = geodem.tool.ToolRegistry.getString(params, "outputPrefix", "DEM 差值图");
            resultLayer = project.uniqueLayerName(prefix + " - " + string(monitorLayer) + " - " + string(baseLayer));
            classLayer = project.uniqueLayerName(prefix + " - 形变等级");
            contourLayer = project.uniqueLayerName(prefix + " - 沉降等值线");
            surfaceLayer = project.uniqueLayerName(prefix + " - 三维形变");
            deformation = geodem.service.deformation.analyzeDeformation(demBase, demMonitor, thresholds);
            resultKey = project.addDeformation(resultLayer, deformation);
            project.parameters.analysis = struct('BaseDemLayer', string(baseLayer), 'MonitorDemLayer', string(monitorLayer), 'ResultLayer', string(resultLayer));
            project.addLayer(resultLayer, "deformation", true);
            project.addLayer(classLayer, "classmap", false);
            project.addLayer(contourLayer, "contour", false);
            project.addLayer(surfaceLayer, "surface3d", false);
            project.addLayerDataRef(resultLayer, "deformation", resultKey, "dem_difference", params);
            project.addLayerDataRef(classLayer, "classmap", resultKey, "dem_difference", params);
            project.addLayerDataRef(contourLayer, "contour", resultKey, "dem_difference", params);
            project.addLayerDataRef(surfaceLayer, "surface3d", resultKey, "dem_difference", params);
            s = deformation.stats;
            conclusion = geodem.service.deformation.summarizeDeformation(deformation);
            project.parameters.conclusion = conclusion;
            msg = [sprintf('DEM 作差完成：最大沉降 %.3f m，最大抬升 %.3f m。', s.MaxSubsidence, s.MaxUplift); conclusion];
            result = geodem.tool.ToolResult("OutputLayers", [resultLayer; classLayer; contourLayer; surfaceLayer], "RenderLayer", resultLayer, "Messages", msg, "Warnings", warnings, "Stats", s);
        end
    end
end
