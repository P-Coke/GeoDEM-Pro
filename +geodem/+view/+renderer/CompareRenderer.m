classdef CompareRenderer
    %COMPARERENDERER Renders the multi-panel comparison view.

    methods (Static)
        function render(view, project)
            result = project.activeDeformation();
            [baseDem, monitorDem, baseName, monitorName] = geodem.view.renderer.RendererSupport.comparisonDems(project);
            if ~isempty(baseDem) && ~isempty(monitorDem)
                geodem.view.renderer.MapRenderer.plotRaster(view, view.CompareAxes(1, 1), baseDem.XGrid, baseDem.YGrid, baseDem.Z, "基准 DEM - " + string(baseName), parula(256), '高程 / m', '');
                geodem.view.renderer.MapRenderer.plotRaster(view, view.CompareAxes(1, 2), monitorDem.XGrid, monitorDem.YGrid, monitorDem.Z, "监测 DEM - " + string(monitorName), parula(256), '高程 / m', '');
                if ~isempty(result)
                    geodem.view.renderer.MapRenderer.plotRaster(view, view.CompareAxes(2, 1), result.XGrid, result.YGrid, result.deltaZ, 'DEM 差值图', geodem.view.renderer.RendererSupport.blueWhiteRed(256), 'ΔZ / m', '');
                    geodem.view.renderer.MapRenderer.plotContours(view, view.CompareAxes(2, 2), result);
                else
                    geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(2, 1), "尚未生成 DEM 差值图", "请选择“形变分析 > DEM作差”");
                    geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(2, 2), "尚未生成沉降等值线", "DEM 作差完成后自动显示");
                end
                geodem.view.renderer.RendererSupport.disableAxesChildrenHitTest(view, view.CompareAxes(:));
                return;
            end
            if ~isempty(baseDem)
                geodem.view.renderer.MapRenderer.plotRaster(view, view.CompareAxes(1, 1), baseDem.XGrid, baseDem.YGrid, baseDem.Z, "DEM - " + string(baseName), parula(256), '高程 / m', '');
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(1, 2), "需要第二个 DEM 图层", "构建或导入另一个 DEM 后可对比");
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(2, 1), "等待 DEM 作差", "请选择两个 DEM 图层运行差分");
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(2, 2), "等待等值线", "差分完成后自动显示");
                geodem.view.renderer.RendererSupport.disableAxesChildrenHitTest(view, view.CompareAxes(:));
                return;
            end
            cloudNames = project.layerNamesByType("pointcloud");
            if numel(cloudNames) >= 2
                geodem.view.renderer.MapRenderer.plotPointCloud2D(view, view.CompareAxes(1, 1), geodem.view.renderer.RendererSupport.cloudForLayer(project, cloudNames(1)), "点云 A - " + string(cloudNames(1)));
                geodem.view.renderer.MapRenderer.plotPointCloud2D(view, view.CompareAxes(1, 2), geodem.view.renderer.RendererSupport.cloudForLayer(project, cloudNames(2)), "点云 B - " + string(cloudNames(2)));
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(2, 1), "等待 DEM 差值图", "先对两个点云构建 DEM");
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(2, 2), "等待沉降等值线", "DEM 作差完成后显示");
            elseif numel(cloudNames) == 1
                geodem.view.renderer.MapRenderer.plotPointCloud2D(view, view.CompareAxes(1, 1), geodem.view.renderer.RendererSupport.cloudForLayer(project, cloudNames(1)), "点云 - " + string(cloudNames(1)));
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(1, 2), "需要第二个点云或 DEM", "导入多个图层后可对比");
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(2, 1), "等待 DEM 差值图", "完成 DEM 构建后显示");
                geodem.view.renderer.RendererSupport.plotPlaceholder(view.CompareAxes(2, 2), "等待沉降等值线", "完成 DEM 作差后显示");
            else
                geodem.view.renderer.RendererSupport.clearCompareAxes(view, "尚未导入可对比图层");
            end
            geodem.view.renderer.RendererSupport.disableAxesChildrenHitTest(view, view.CompareAxes(:));
        end
    end
end
