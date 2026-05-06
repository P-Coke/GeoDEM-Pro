classdef MapInteractionActions
    %MAPINTERACTIONACTIONS Identify, measure and profile map click handlers.

    methods (Static)
        function identifyAt(controller, x, y)
            result = geodem.service.deformation.identifyAt(controller.Project, x, y);
            controller.Project.mapToolState.lastIdentifyResult = result;
            lines = [
                "Identify"
                "X: " + sprintf('%.3f', result.X)
                "Y: " + sprintf('%.3f', result.Y)
                "DEM A: " + sprintf('%.3f', result.BaseDEM)
                "DEM B: " + sprintf('%.3f', result.MonitorDEM)
                "ΔZ: " + sprintf('%.3f', result.DeltaZ)
                "等级: " + result.ClassName
                ];
            controller.View.setStats(lines);
            controller.View.showIdentifyMarker(x, y);
            controller.View.updateStatusBar(controller.Project, result, "就绪");
            controller.log(sprintf('识别位置：X=%.3f, Y=%.3f, ΔZ=%.3f。', result.X, result.Y, result.DeltaZ));
        end

        function measureAt(controller, x, y)
            pts = controller.Project.mapToolState.measurePoints;
            pts(end + 1, :) = [x y];
            controller.Project.mapToolState.measurePoints = pts;
            if size(pts, 1) >= 2
                measurement = geodem.service.deformation.measureDistance(pts);
                controller.Project.mapToolState.lastDistance = measurement.TotalDistance;
                controller.View.drawMeasurement(pts, measurement.TotalDistance);
                controller.View.setStats([
                    "测距"
                    "点数: " + size(pts, 1)
                    "总距离: " + sprintf('%.3f m', measurement.TotalDistance)
                    ]);
                controller.View.updateStatusBar(controller.Project, struct('X', x, 'Y', y, 'Z', NaN), "就绪");
                controller.log(sprintf('测距总长度：%.3f m。', measurement.TotalDistance));
            else
                controller.View.showIdentifyMarker(x, y);
                controller.View.updateStatusBar(controller.Project, struct('X', x, 'Y', y, 'Z', NaN), "就绪");
                controller.log('测距起点已设置，请点击终点。');
            end
        end

        function profileFromClicks(controller, x, y)
            pts = controller.Project.mapToolState.measurePoints;
            pts(end + 1, :) = [x y];
            controller.Project.mapToolState.measurePoints = pts;
            if size(pts, 1) >= 2
                params = geodem.controller.actions.MapInteractionActions.currentProfileParams(controller);
                [demBase, demMonitor] = geodem.controller.actions.MapInteractionActions.selectedProfileDems(controller.Project, params);
                sampleCount = geodem.controller.actions.MapInteractionActions.profileSampleCount(controller.Project, params);
                startPoint = pts(end-1, :);
                endPoint = pts(end, :);
                profile = geodem.service.deformation.profileAnalysis(demBase, demMonitor, startPoint, endPoint, sampleCount);
                controller.Project.parameters.lastProfile = profile;
                params.lineMode = "manual";
                params.startX = string(sprintf('%.6f', startPoint(1)));
                params.startY = string(sprintf('%.6f', startPoint(2)));
                params.endX = string(sprintf('%.6f', endPoint(1)));
                params.endY = string(sprintf('%.6f', endPoint(2)));
                controller.Project.toolDefaults.(matlab.lang.makeValidName('profile_analysis')) = params;
                controller.View.renderProfile(profile);
                controller.Project.mapToolState.measurePoints = zeros(0, 2);
                controller.log('交互剖面分析完成。');
            else
                controller.View.showIdentifyMarker(x, y);
                controller.log('剖面起点已设置，请点击终点。');
            end
        end

        function params = currentProfileParams(controller)
            params = struct();
            try
                if string(controller.SelectedToolId) == "profile_analysis"
                    params = controller.View.readToolParameters();
                end
            catch
                params = struct();
            end
        end

        function [demBase, demMonitor] = selectedProfileDems(project, params)
            if nargin < 2
                params = struct();
            end
            demNames = project.layerNamesByType("dem");
            if numel(demNames) < 2
                error('GeoDEM:NeedTwoDemLayers', '剖面分析需要两个已生成的 DEM 图层。请先运行 DEM 构建工具或一键工作流。');
            end
            baseLayer = demNames(1);
            monitorLayer = demNames(2);
            if isstruct(params) && isfield(params, 'baseDemLayer') && any(demNames == string(params.baseDemLayer))
                baseLayer = string(params.baseDemLayer);
            end
            if isstruct(params) && isfield(params, 'monitorDemLayer') && any(demNames == string(params.monitorDemLayer))
                monitorLayer = string(params.monitorDemLayer);
            end
            if isfield(project.parameters, 'analysis')
                a = project.parameters.analysis;
                if baseLayer == demNames(1) && isfield(a, 'BaseDemLayer') && any(demNames == string(a.BaseDemLayer))
                    baseLayer = string(a.BaseDemLayer);
                end
                if monitorLayer == demNames(2) && isfield(a, 'MonitorDemLayer') && any(demNames == string(a.MonitorDemLayer))
                    monitorLayer = string(a.MonitorDemLayer);
                end
            end
            if baseLayer == monitorLayer
                error('GeoDEM:SameToolInputLayer', '剖面分析需要选择两个不同的 DEM 图层。');
            end
            demBase = geodem.tool.ToolRegistry.getDemByLayer(project, baseLayer);
            demMonitor = geodem.tool.ToolRegistry.getDemByLayer(project, monitorLayer);
        end

        function sampleCount = profileSampleCount(project, params)
            if nargin < 2
                params = struct();
            end
            sampleCount = project.parameters.profileSamples;
            if isstruct(params) && isfield(params, 'sampleCount') && isfinite(double(params.sampleCount))
                sampleCount = round(double(params.sampleCount));
                sampleCount = max(2, round(sampleCount));
                return;
            end
            key = matlab.lang.makeValidName('profile_analysis');
            if isfield(project.toolDefaults, key)
                defaults = project.toolDefaults.(key);
                if isfield(defaults, 'sampleCount') && isfinite(defaults.sampleCount)
                    sampleCount = round(defaults.sampleCount);
                end
            end
            sampleCount = max(2, round(sampleCount));
        end
    end
end
