classdef LayerRenderer
    %LAYERRENDERER Rendering facade for map, scene, compare and chart views.

    methods (Static)
        function renderProject(view, project)
            kind = view.currentViewKind();
            if kind == "compare"
                geodem.view.renderer.CompareRenderer.render(view, project);
                return;
            elseif kind == "charts"
                geodem.view.renderer.ChartRenderer.renderCharts(view, project);
                return;
            end
            state = project.getViewState(view.currentViewId());
            layerName = state.ActiveLayer;
            if strlength(layerName) == 0
                layerName = project.activeLayer;
            end
            if strlength(string(layerName)) > 0
                geodem.view.LayerRenderer.renderLayer(view, project, layerName);
                return;
            end
            cla(view.MapAxes);
            cla(view.SceneAxes);
            title(view.MapAxes, 'GeoDEM Pro 二维地图');
            title(view.SceneAxes, '三维场景');
        end

        function renderLayer(view, project, layerName)
            if strlength(string(layerName)) == 0
                return;
            end
            layerName = char(layerName);
            layerType = geodem.view.renderer.RendererSupport.layerType(project, layerName);
            style = geodem.view.renderer.RendererSupport.layerStyle(project, layerName);
            [targetAxes, viewKind] = geodem.view.renderer.RendererSupport.activeRenderAxes(view);
            if viewKind == "charts"
                geodem.view.renderer.ChartRenderer.renderCharts(view, project);
                return;
            elseif viewKind == "compare"
                geodem.view.renderer.CompareRenderer.render(view, project);
                return;
            end
            if viewKind == "scene" || any(strcmp(layerName, {'三维 DEM','三维形变地形','三维点云'}))
                geodem.view.renderer.SceneRenderer.renderLayer(view, project, targetAxes, layerName, layerType, style);
            else
                geodem.view.renderer.MapRenderer.renderLayer(view, project, targetAxes, layerName, layerType, style);
            end
            geodem.view.renderer.RendererSupport.disableAxesChildrenHitTest(view, targetAxes);
        end

        function [ax, kind] = activeRenderAxes(view)
            [ax, kind] = geodem.view.renderer.RendererSupport.activeRenderAxes(view);
        end

        function renderScene(view, project, mode)
            if nargin < 3
                mode = 'auto';
            end
            geodem.view.renderer.SceneRenderer.render(view, project, mode);
        end

        function renderCompare(view, project)
            geodem.view.renderer.CompareRenderer.render(view, project);
        end

        function renderCharts(view, project)
            geodem.view.renderer.ChartRenderer.renderCharts(view, project);
        end

        function renderProfile(view, profile)
            geodem.view.renderer.ChartRenderer.renderProfile(view, profile);
        end

        function bounds = layerBounds(project, layerName)
            bounds = geodem.view.renderer.RendererSupport.layerBounds(project, layerName);
        end
    end
end
