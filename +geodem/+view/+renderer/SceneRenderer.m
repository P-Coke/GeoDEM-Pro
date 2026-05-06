classdef SceneRenderer
    %SCENERENDERER Renders 3-D scene layers.

    methods (Static)
        function render(view, project, mode)
            if nargin < 3
                mode = 'auto';
            end
            switch mode
                case 'pointcloud'
                    names = project.layerNamesByType("pointcloud");
                    if ~isempty(names)
                        geodem.view.renderer.SceneRenderer.plotPointCloud3D(view, view.SceneAxes, geodem.view.renderer.RendererSupport.cloudForLayer(project, names(1)));
                    end
                case 'dem'
                    names = project.layerNamesByType("dem");
                    if ~isempty(names)
                        geodem.view.renderer.SceneRenderer.plotDemSurface(view, view.SceneAxes, geodem.view.renderer.RendererSupport.demForLayer(project, names(1)), "三维 DEM - " + names(1));
                    end
                case 'deformation'
                    result = project.activeDeformation();
                    dem = geodem.view.renderer.RendererSupport.deformationSurfaceDem(project, project.activeLayer);
                    if ~isempty(dem) && ~isempty(result)
                        geodem.view.renderer.SceneRenderer.plotSurface(view, view.SceneAxes, dem, result);
                    elseif ~isempty(dem)
                        geodem.view.renderer.SceneRenderer.plotDemSurface(view, view.SceneAxes, dem, '三维 DEM');
                    end
                otherwise
                    activeResult = project.activeDeformation();
                    if ~isempty(activeResult)
                        geodem.view.renderer.SceneRenderer.render(view, project, 'deformation');
                    elseif ~isempty(project.layerNamesByType("dem"))
                        geodem.view.renderer.SceneRenderer.render(view, project, 'dem');
                    elseif ~isempty(project.layerNamesByType("pointcloud"))
                        geodem.view.renderer.SceneRenderer.render(view, project, 'pointcloud');
                    end
            end
        end

        function renderLayer(view, project, ax, layerName, layerType, style)
            if strcmp(layerType, 'pointcloud')
                cloud = geodem.view.renderer.RendererSupport.cloudForLayer(project, layerName);
                geodem.view.renderer.SceneRenderer.plotPointCloud3D(view, ax, cloud, style);
            elseif strcmp(layerType, 'dem')
                dem = geodem.view.renderer.RendererSupport.demForLayer(project, layerName);
                geodem.view.renderer.SceneRenderer.plotDemSurface(view, ax, dem, "三维 DEM - " + string(layerName), style);
            elseif any(strcmp(layerType, {'deformation','classmap','contour','surface3d'}))
                result = geodem.view.renderer.RendererSupport.deformationForLayer(project, layerName);
                dem = geodem.view.renderer.RendererSupport.deformationSurfaceDem(project, layerName);
                if ~isempty(dem)
                    geodem.view.renderer.SceneRenderer.plotSurface(view, ax, dem, result, style);
                end
            end
        end

        function plotPointCloud3D(view, ax, cloud, style)
            if nargin < 4 || isempty(style), style = geodem.model.LayerStyle(); end
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            pts = geodem.view.renderer.RendererSupport.samplePointsForDisplay(cloud.points, view.MaxSceneDisplayPoints);
            h = scatter3(ax, pts(:, 1), pts(:, 2), pts(:, 3), 3, pts(:, 3), char(style.marker), 'filled', 'HitTest', 'off');
            try
                h.MarkerFaceAlpha = style.alpha;
                h.MarkerEdgeAlpha = style.alpha;
            catch
            end
            grid(ax, 'on');
            colorbar(ax);
            title(ax, sprintf('三维点云（显示 %d / %d 点）', size(pts, 1), cloud.bounds.PointCount));
            xlabel(ax, 'X / m');
            ylabel(ax, 'Y / m');
            zlabel(ax, 'Z / m');
            feval('view', ax, 45, 35);
        end

        function plotSurface(view, ax, dem, result, style)
            if nargin < 5 || isempty(style), style = geodem.model.LayerStyle(); end
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            [XGrid, YGrid, Z, C] = geodem.view.renderer.RendererSupport.sampleGridForDisplay(dem.XGrid, dem.YGrid, dem.Z, view.MaxSurfaceDisplayCells, result.deltaZ);
            surf(ax, XGrid, YGrid, Z, C, 'EdgeColor', 'none', 'FaceAlpha', style.alpha, 'HitTest', 'off');
            colormap(ax, geodem.view.renderer.RendererSupport.blueWhiteRed(256));
            cb = colorbar(ax);
            cb.Label.String = 'ΔZ / m';
            grid(ax, 'on');
            title(ax, '三维形变地形');
            xlabel(ax, 'X / m');
            ylabel(ax, 'Y / m');
            zlabel(ax, '高程 / m');
            feval('view', ax, 45, 35);
            zscale = geodem.view.renderer.RendererSupport.zExaggeration();
            daspect(ax, [1 1 1 / max(zscale, eps)]);
        end

        function plotDemSurface(view, ax, dem, titleText, style)
            if nargin < 5 || isempty(style), style = geodem.model.LayerStyle(); end
            geodem.view.renderer.RendererSupport.resetPlotAxes(ax);
            [XGrid, YGrid, Z] = geodem.view.renderer.RendererSupport.sampleGridForDisplay(dem.XGrid, dem.YGrid, dem.Z, view.MaxSurfaceDisplayCells);
            surf(ax, XGrid, YGrid, Z, Z, 'EdgeColor', 'none', 'FaceAlpha', style.alpha, 'HitTest', 'off');
            colormap(ax, turbo(256));
            cb = colorbar(ax);
            cb.Label.String = '高程 / m';
            grid(ax, 'on');
            title(ax, titleText);
            xlabel(ax, 'X / m');
            ylabel(ax, 'Y / m');
            zlabel(ax, '高程 / m');
            axis(ax, 'tight');
            feval('view', ax, 45, 35);
            zscale = geodem.view.renderer.RendererSupport.zExaggeration();
            daspect(ax, [1 1 1 / max(zscale, eps)]);
            camlight(ax, 'headlight');
            lighting(ax, 'gouraud');
        end
    end
end
