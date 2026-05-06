classdef ProfileAnalysisTool
    %PROFILEANALYSISTOOL DEM profile analysis plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("profile_analysis", "剖面分析", ...
                "从两个 DEM 图层生成对比剖面，可使用共同范围对角线或手动起止点。", ...
                "形变分析", "Explore", "profile", [
                    P("baseDemLayer", "基准 DEM", "layer", "", "LayerType", "dem", "Required", true)
                    P("monitorDemLayer", "监测 DEM", "layer", "", "LayerType", "dem", "Required", true)
                    P("lineMode", "剖面线", "dropdown", "overlap_diagonal", "Items", {'overlap_diagonal','manual'})
                    P("startX", "起点 X", "text", "")
                    P("startY", "起点 Y", "text", "")
                    P("endX", "终点 X", "text", "")
                    P("endY", "终点 Y", "text", "")
                    P("sampleCount", "采样点数", "numeric", 200, "Limits", [2 Inf])
                ], @geodem.tool.plugins.deformation.ProfileAnalysisTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.deformation.ProfileAnalysisTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.deformation.ProfileAnalysisTool.spec(), project, params);
            messages = geodem.tool.ToolValidator.validateDifferentParams(messages, params, "baseDemLayer", "monitorDemLayer", "两个 DEM 图层不能相同。");
            if isstruct(params)
                try
                    baseLayer = geodem.tool.ToolRegistry.getString(params, "baseDemLayer", "");
                    monitorLayer = geodem.tool.ToolRegistry.getString(params, "monitorDemLayer", "");
                    if strlength(baseLayer) > 0 && strlength(monitorLayer) > 0 && ~startsWith(baseLayer, "<") && ~startsWith(monitorLayer, "<") && baseLayer ~= monitorLayer
                        demBase = geodem.tool.ToolRegistry.getDemByLayer(project, baseLayer);
                        demMonitor = geodem.tool.ToolRegistry.getDemByLayer(project, monitorLayer);
                        bounds = geodem.tool.ToolRegistry.commonDemBounds(demBase, demMonitor);
                        lineMode = lower(geodem.tool.ToolRegistry.getString(params, "lineMode", "overlap_diagonal"));
                        if lineMode == "manual"
                            startPoint = [
                                geodem.tool.ToolRegistry.getTextNumber(params, "startX")
                                geodem.tool.ToolRegistry.getTextNumber(params, "startY")
                                ]';
                            endPoint = [
                                geodem.tool.ToolRegistry.getTextNumber(params, "endX")
                                geodem.tool.ToolRegistry.getTextNumber(params, "endY")
                                ]';
                            if hypot(endPoint(1) - startPoint(1), endPoint(2) - startPoint(2)) <= eps
                                messages(end + 1, 1) = "剖面起点和终点不能相同。"; %#ok<AGROW>
                            end
                            if ~geodem.tool.plugins.deformation.ProfileAnalysisTool.pointInsideBounds(startPoint, bounds) || ~geodem.tool.plugins.deformation.ProfileAnalysisTool.pointInsideBounds(endPoint, bounds)
                                messages(end + 1, 1) = "手动剖面端点必须位于两个 DEM 的共同覆盖范围内。"; %#ok<AGROW>
                            end
                        end
                    end
                catch ME
                    messages(end + 1, 1) = string(ME.message); %#ok<AGROW>
                end
            end
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            project = ctx.Project;
            baseLayer = geodem.tool.ToolRegistry.requireLayer(params, "baseDemLayer");
            monitorLayer = geodem.tool.ToolRegistry.requireLayer(params, "monitorDemLayer");
            geodem.tool.ToolRegistry.assertDifferent(baseLayer, monitorLayer, "基准 DEM 和监测 DEM 不能相同。");
            demBase = geodem.tool.ToolRegistry.getDemByLayer(project, baseLayer);
            demMonitor = geodem.tool.ToolRegistry.getDemByLayer(project, monitorLayer);
            b = geodem.tool.ToolRegistry.commonDemBounds(demBase, demMonitor);
            lineMode = lower(geodem.tool.ToolRegistry.getString(params, "lineMode", "overlap_diagonal"));
            if lineMode == "manual"
                startPoint = [
                    geodem.tool.ToolRegistry.getTextNumber(params, "startX")
                    geodem.tool.ToolRegistry.getTextNumber(params, "startY")
                    ]';
                endPoint = [
                    geodem.tool.ToolRegistry.getTextNumber(params, "endX")
                    geodem.tool.ToolRegistry.getTextNumber(params, "endY")
                    ]';
            else
                startPoint = [b.XMin, b.YMin];
                endPoint = [b.XMax, b.YMax];
            end
            sampleCount = round(geodem.tool.ToolRegistry.getNumber(params, "sampleCount", 200));
            profile = geodem.service.deformation.profileAnalysis(demBase, demMonitor, startPoint, endPoint, sampleCount);
            project.parameters.lastProfile = profile;
            validRatio = sum(profile.Valid) / max(height(profile), 1);
            warnings = strings(0, 1);
            if validRatio < 0.80
                warnings(end + 1, 1) = sprintf('剖面有效采样比例为 %.1f%%，部分线段经过 DEM 空洞或共同范围外。', 100 * validRatio);
            end
            message = sprintf('剖面分析完成：%d 个采样点，起点 X=%.3f Y=%.3f，终点 X=%.3f Y=%.3f。', ...
                sampleCount, startPoint(1), startPoint(2), endPoint(1), endPoint(2));
            result = geodem.tool.ToolResult("Messages", message, "Warnings", warnings, "Stats", profile, "Presentation", "profile");
        end

        function tf = pointInsideBounds(point, bounds)
            tf = point(1) >= bounds.XMin && point(1) <= bounds.XMax && ...
                 point(2) >= bounds.YMin && point(2) <= bounds.YMax;
        end
    end
end
