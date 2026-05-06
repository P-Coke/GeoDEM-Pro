classdef MapRenderer
    %MAPRENDERER Renders 2-D map layers.

    methods (Static)
        function renderLayer(view, project, ax, layerName, layerType, style)
            switch layerType
                case 'pointcloud'
                    cloud = geodem.view.renderer.RendererSupport.cloudForLayer(project, layerName);
                    geodem.view.renderer.MapRenderer.plotPointCloud2D(view, ax, cloud, layerName, style);
                case 'dem'
                    dem = geodem.view.renderer.RendererSupport.demForLayer(project, layerName);
                    geodem.view.renderer.MapRenderer.plotRaster(view, ax, dem.XGrid, dem.YGrid, dem.Z, layerName, parula(256), '高程 / m', 'Resolution ' + string(dem.resolution) + ' m', style);
                case 'deformation'
                    result = geodem.view.renderer.RendererSupport.deformationForLayer(project, layerName);
                    if ~isempty(result), geodem.view.renderer.MapRenderer.plotRaster(view, ax, result.XGrid, result.YGrid, result.deltaZ, layerName, geodem.view.renderer.RendererSupport.blueWhiteRed(256), 'ΔZ / m', 'ΔZ = DEM B - DEM A', style); end
                case 'classmap'
                    result = geodem.view.renderer.RendererSupport.deformationForLayer(project, layerName);
                    if ~isempty(result), geodem.view.renderer.MapRenderer.plotClassMap(view, ax, result, style); end
                case 'contour'
                    result = geodem.view.renderer.RendererSupport.deformationForLayer(project, layerName);
                    if ~isempty(result), geodem.view.renderer.MapRenderer.plotContours(view, ax, result, style); end
                case 'surface3d'
                    result = geodem.view.renderer.RendererSupport.deformationForLayer(project, layerName);
                    dem = geodem.view.renderer.RendererSupport.deformationSurfaceDem(project, layerName);
                    if ~isempty(result) && ~isempty(dem), geodem.view.renderer.SceneRenderer.plotSurface(view, ax, dem, result, style); end
                case 'density'
                    density = geodem.service.layer.LayerInfoService.densityForLayer(project, layerName);
                    if ~isempty(density), geodem.view.renderer.MapRenderer.plotDensity(view, ax, density, style); end
                otherwise
                    result = geodem.view.renderer.RendererSupport.deformationForLayer(project, layerName);
                    if ~isempty(result), geodem.view.renderer.MapRenderer.plotRaster(view, ax, result.XGrid, result.YGrid, result.deltaZ, layerName, geodem.view.renderer.RendererSupport.blueWhiteRed(256), 'ΔZ / m', '', style); end
            end
        end

        function plotPointCloud2D(view, ax, cloud, titleText, style)
            if nargin < 5 || isempty(style), style = geodem.model.LayerStyle(); end
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            pts = geodem.view.renderer.RendererSupport.samplePointsForDisplay(cloud.points, view.MaxMapDisplayPoints);
            h = scatter(ax, pts(:, 1), pts(:, 2), 3, pts(:, 3), char(style.marker), 'filled', 'HitTest', 'off');
            try
                h.MarkerFaceAlpha = style.alpha;
                h.MarkerEdgeAlpha = style.alpha;
            catch
            end
            axis(ax, 'equal');
            axis(ax, 'tight');
            cb = colorbar(ax);
            cb.Label.String = 'Z / m';
            geodem.service.cartography.createMapDecorations(ax, titleText, sprintf('显示 %d / 总计 %d 点', size(pts, 1), cloud.bounds.PointCount));
        end

        function plotDensity(view, ax, density, style)
            if nargin < 4 || isempty(style), style = geodem.model.LayerStyle(); end
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            [XGrid, YGrid, densityValues] = geodem.view.renderer.RendererSupport.sampleGridForDisplay(density.XGrid, density.YGrid, density.Density, view.MaxSurfaceDisplayCells * 2);
            img = imagesc(ax, XGrid(1, :), YGrid(:, 1), densityValues, 'HitTest', 'off');
            img.AlphaData = style.alpha * isfinite(densityValues);
            set(ax, 'YDir', 'normal');
            axis(ax, 'equal');
            axis(ax, 'tight');
            colormap(ax, turbo(256));
            cb = colorbar(ax);
            cb.Label.String = 'points / m²';
            geodem.service.cartography.createMapDecorations(ax, '点云密度热力图', sprintf('Empty cells %.1f%%', density.EmptyCellRatio*100));
        end

        function plotRaster(view, ax, XGrid, YGrid, Z, titleText, cmap, colorLabel, paramsText, style)
            if nargin < 10 || isempty(style), style = geodem.model.LayerStyle(); end
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            [XGrid, YGrid, Z] = geodem.view.renderer.RendererSupport.sampleGridForDisplay(XGrid, YGrid, Z, view.MaxSurfaceDisplayCells * 2);
            img = imagesc(ax, XGrid(1, :), YGrid(:, 1), Z, 'HitTest', 'off');
            img.AlphaData = style.alpha * isfinite(Z);
            set(ax, 'YDir', 'normal');
            axis(ax, 'equal');
            axis(ax, 'tight');
            colormap(ax, cmap);
            cb = colorbar(ax);
            cb.Label.String = colorLabel;
            geodem.service.cartography.createMapDecorations(ax, titleText, paramsText);
        end

        function plotClassMap(view, ax, result, style)
            if nargin < 4 || isempty(style), style = geodem.model.LayerStyle(); end
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            [XGrid, YGrid, classMap] = geodem.view.renderer.RendererSupport.sampleGridForDisplay(result.XGrid, result.YGrid, result.classMap, view.MaxSurfaceDisplayCells * 2);
            img = imagesc(ax, XGrid(1, :), YGrid(:, 1), classMap, 'HitTest', 'off');
            img.AlphaData = style.alpha * isfinite(classMap);
            set(ax, 'YDir', 'normal');
            axis(ax, 'equal');
            axis(ax, 'tight');
            colormap(ax, [0.08 0.20 0.75; 0.20 0.48 0.90; 0.55 0.74 1.00; 0.93 0.93 0.93; 1.00 0.66 0.42; 0.80 0.13 0.10]);
            caxis(ax, [-3 2]);
            cb = colorbar(ax);
            cb.Ticks = -3:2;
            cb.TickLabels = {'严重沉降','中度沉降','轻微沉降','稳定','轻微抬升','明显抬升'};
            geodem.service.cartography.createMapDecorations(ax, '形变等级分区图', 'Classification by ΔZ thresholds');
        end

        function plotContours(view, ax, result, style)
            if nargin < 4 || isempty(style), style = geodem.model.LayerStyle(); end
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            [XGrid, YGrid, deltaZ] = geodem.view.renderer.RendererSupport.sampleGridForDisplay(result.XGrid, result.YGrid, result.deltaZ, view.MaxSurfaceDisplayCells * 2);
            [~, fillHandle] = contourf(ax, XGrid, YGrid, deltaZ, 24, 'LineStyle', 'none', 'HitTest', 'off');
            try
                fillHandle.FaceAlpha = style.alpha;
            catch
            end
            hold(ax, 'on');
            colormap(ax, geodem.view.renderer.RendererSupport.blueWhiteRed(256));
            cb = colorbar(ax);
            cb.Label.String = 'ΔZ / m';
            valid = isfinite(deltaZ);
            interval = result.thresholds.contourInterval;
            levels = floor(min(deltaZ(valid)) / interval) * interval:interval:ceil(max(deltaZ(valid)) / interval) * interval;
            [C, h] = contour(ax, XGrid, YGrid, deltaZ, levels, 'k', 'LineWidth', max(0.1, style.lineWidth), 'HitTest', 'off');
            if style.labelsEnabled
                clabel(C, h, 'FontSize', 8, 'Color', 'k');
            end
            plot(ax, result.maxSubsidencePoint.X, result.maxSubsidencePoint.Y, 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'HitTest', 'off');
            axis(ax, 'equal');
            axis(ax, 'tight');
            geodem.service.cartography.createMapDecorations(ax, '沉降等值线图', sprintf('Contour interval %.2f m', interval));
            hold(ax, 'off');
        end
    end
end
