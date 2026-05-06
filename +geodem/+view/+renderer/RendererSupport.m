classdef RendererSupport
    %RENDERERSUPPORT Shared renderer lookup, axes, sampling and utility logic.

    methods (Static)
        function [ax, kind] = activeRenderAxes(view)
            ax = view.MapAxes;
            kind = "map";
            if isempty(view.MainTabGroup) || ~isvalid(view.MainTabGroup) || isempty(view.MainTabGroup.SelectedTab)
                return;
            end
            tab = view.MainTabGroup.SelectedTab;
            data = tab.UserData;
            if ~isstruct(data) || ~isfield(data, 'Kind')
                return;
            end
            kind = string(data.Kind);
            if isfield(data, 'Axes') && ~isempty(data.Axes)
                candidate = data.Axes;
                if isvalid(candidate)
                    ax = candidate;
                end
            end
        end

        function bounds = layerBounds(project, layerName)
            layerName = string(layerName);
            bounds = [];
            typeName = "";
            idx = find(project.layers.Name == layerName, 1);
            if ~isempty(idx), typeName = string(project.layers.Type(idx)); end
            if typeName == "pointcloud"
                cloud = project.getCloudByLayer(layerName);
                if ~isempty(cloud), bounds = cloud.bounds; end
            elseif typeName == "dem"
                dem = geodem.view.renderer.RendererSupport.demForLayer(project, layerName);
                if ~isempty(dem), bounds = dem.bounds; end
            elseif any(typeName == ["deformation","classmap","contour","surface3d"])
                result = geodem.view.renderer.RendererSupport.deformationForLayer(project, layerName);
                if ~isempty(result)
                    bounds = struct('XMin', min(result.XGrid(:)), 'XMax', max(result.XGrid(:)), ...
                        'YMin', min(result.YGrid(:)), 'YMax', max(result.YGrid(:)));
                end
            end
        end

        function typeName = layerType(project, layerName)
            idx = find(project.layers.Name == string(layerName), 1);
            if isempty(idx)
                typeName = "";
            else
                typeName = char(project.layers.Type(idx));
            end
        end

        function style = layerStyle(project, layerName)
            style = geodem.service.layer.LayerInfoService.getStyle(project, layerName);
        end

        function cloud = cloudForLayer(project, layerName)
            cloud = project.getCloudByLayer(layerName);
        end

        function dem = demForLayer(project, layerName)
            layerName = string(layerName);
            key = geodem.model.ProjectState.layerKey(layerName);
            if isfield(project.dems, key)
                dem = project.dems.(key);
                return;
            end
            dem = geodem.tool.ToolRegistry.getDemByLayer(project, layerName);
        end

        function result = deformationForLayer(project, layerName)
            result = [];
            if nargin >= 2 && strlength(string(layerName)) > 0
                result = project.getDeformationByLayer(layerName);
            end
            if isempty(result)
                result = project.activeDeformation();
            end
        end

        function dem = deformationSurfaceDem(project, layerName)
            dem = [];
            analysis = struct();
            if nargin >= 2 && strlength(string(layerName)) > 0
                ref = project.getLayerDataRef(layerName);
                if ~isempty(ref) && isstruct(ref.SourceParams)
                    analysis = ref.SourceParams;
                end
            end
            if ~isfield(analysis, 'monitorDemLayer') && isfield(project.parameters, 'analysis')
                projectAnalysis = project.parameters.analysis;
                if isfield(projectAnalysis, 'MonitorDemLayer')
                    analysis.monitorDemLayer = projectAnalysis.MonitorDemLayer;
                end
            end
            if isfield(analysis, 'monitorDemLayer')
                try
                    dem = geodem.view.renderer.RendererSupport.demForLayer(project, string(analysis.monitorDemLayer));
                    return;
                catch
                end
            end
            names = project.layerNamesByType("dem");
            if ~isempty(names)
                dem = geodem.view.renderer.RendererSupport.demForLayer(project, names(end));
            end
        end

        function [baseDem, monitorDem, baseName, monitorName] = comparisonDems(project)
            baseDem = [];
            monitorDem = [];
            demNames = project.layerNamesByType("dem");
            if isempty(demNames)
                baseName = "";
                monitorName = "";
                return;
            end
            baseName = demNames(1);
            monitorName = "";
            if numel(demNames) >= 2
                monitorName = demNames(2);
            end
            analysis = struct();
            if strlength(string(project.activeLayer)) > 0
                ref = project.getLayerDataRef(project.activeLayer);
                if ~isempty(ref) && isstruct(ref.SourceParams)
                    analysis = ref.SourceParams;
                end
            end
            if isfield(analysis, 'baseDemLayer') && any(demNames == string(analysis.baseDemLayer))
                baseName = string(analysis.baseDemLayer);
            end
            if isfield(analysis, 'monitorDemLayer') && any(demNames == string(analysis.monitorDemLayer))
                monitorName = string(analysis.monitorDemLayer);
            end
            if strlength(monitorName) == 0 && isfield(project.parameters, 'analysis')
                analysis = project.parameters.analysis;
                if isfield(analysis, 'BaseDemLayer') && any(demNames == string(analysis.BaseDemLayer))
                    baseName = string(analysis.BaseDemLayer);
                end
                if isfield(analysis, 'MonitorDemLayer') && any(demNames == string(analysis.MonitorDemLayer))
                    monitorName = string(analysis.MonitorDemLayer);
                end
            end
            if strlength(baseName) > 0
                baseDem = geodem.view.renderer.RendererSupport.demForLayer(project, baseName);
            end
            if strlength(monitorName) > 0
                monitorDem = geodem.view.renderer.RendererSupport.demForLayer(project, monitorName);
            end
        end

        function resetPlotAxes(ax)
            fig = ancestor(ax, 'figure');
            if ~isempty(fig)
                bars = findall(fig, 'Type', 'ColorBar');
                for i = 1:numel(bars)
                    try
                        if isequal(bars(i).Axes, ax)
                            delete(bars(i));
                        end
                    catch
                    end
                end
            end
            cla(ax);
            axis(ax, 'on');
            ax.XGrid = 'on';
            ax.YGrid = 'on';
            ax.ZGrid = 'off';
            try
                ax.XMinorGrid = 'off';
                ax.YMinorGrid = 'off';
                ax.GridLineStyle = '-';
                ax.GridColor = [0.64 0.68 0.72];
                ax.GridAlpha = 0.28;
                ax.XAxis.Exponent = 0;
                ax.YAxis.Exponent = 0;
                xtickformat(ax, '%.0f');
                ytickformat(ax, '%.0f');
            catch
            end
        end

        function clearCompareAxes(view, message)
            labels = ["输入图层 A", "输入图层 B", "差分专题", "等值线/分区"];
            for i = 1:numel(view.CompareAxes)
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(i), labels(i), message);
            end
        end

        function plotPlaceholder(ax, titleText, message)
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            xlim(ax, [0 1]);
            ylim(ax, [0 1]);
            axis(ax, 'off');
            title(ax, char(titleText), 'FontWeight', 'bold');
            text(ax, 0.5, 0.56, char(message), 'HorizontalAlignment', 'center', ...
                'FontSize', 11, 'Color', [0.34 0.40 0.48], 'HitTest', 'off');
        end

        function disableAxesChildrenHitTest(view, axesList)
            if nargin < 2 || isempty(axesList)
                axesList = view.MapAxes;
            end
            axesList = axesList(:)';
            for i = 1:numel(axesList)
                if isvalid(axesList(i))
                    set(findall(axesList(i), '-property', 'HitTest'), 'HitTest', 'off');
                end
            end
            view.MapAxes.HitTest = 'on';
            geodem.compat.setUiCallback(view.MapAxes, 'ButtonDownFcn', @(~, ~) view.onMapAxesClick());
        end

        function pts = samplePointsForDisplay(pts, maxPoints)
            n = size(pts, 1);
            if n <= maxPoints
                return;
            end
            idx = round(linspace(1, n, maxPoints));
            pts = pts(idx, :);
        end

        function [X, Y, Z, C] = sampleGridForDisplay(X, Y, Z, maxCells, C)
            if nargin < 5
                C = [];
            end
            cells = numel(Z);
            if cells <= maxCells
                return;
            end
            step = max(1, ceil(sqrt(cells / maxCells)));
            X = X(1:step:end, 1:step:end);
            Y = Y(1:step:end, 1:step:end);
            Z = Z(1:step:end, 1:step:end);
            if ~isempty(C)
                C = C(1:step:end, 1:step:end);
            end
        end

        function cmap = blueWhiteRed(n)
            if nargin < 1
                n = 256;
            end
            half = floor(n / 2);
            blue = [linspace(0.08, 1, half)', linspace(0.25, 1, half)', ones(half, 1)];
            red = [ones(n - half, 1), linspace(1, 0.10, n - half)', linspace(1, 0.08, n - half)'];
            cmap = [blue; red];
        end

        function value = zExaggeration()
            value = 1;
        end
    end
end
