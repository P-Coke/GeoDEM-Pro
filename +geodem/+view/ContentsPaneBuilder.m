classdef ContentsPaneBuilder
    %CONTENTSPANEBUILDER Builds the layer tree and its GIS-style menu.

    methods (Static)
        function create(view, parent)
            panel = uipanel(parent, 'Title', '图层管理');
            geodem.compat.setUiProperty(panel, 'FontWeight', 'bold');
            geodem.compat.setUiProperty(panel, 'BackgroundColor', [0.985 0.99 0.995]);
            layout = uigridlayout(panel, [2 1]);
            layout.RowHeight = {34, '1x'};
            layout.Padding = [6 6 6 6];

            toolbar = uigridlayout(layout, [1 5]);
            toolbar.ColumnWidth = {34, 34, 34, 34, 34};
            toolbar.Padding = [0 0 0 0];
            view.iconButton(toolbar, '', 'fullExtent', '缩放至当前图层', @() view.Controller.zoomToLayer(), 'small');
            view.iconButton(toolbar, '', 'attribute', '打开属性表', @() view.Controller.openAttributeTable(), 'small');
            view.iconButton(toolbar, '', 'layer', '显示当前图层', @() view.Controller.renderLayer(view.Controller.Project.activeLayer), 'small');
            view.iconButton(toolbar, '', 'chart', '显示统计图表', @() view.selectViewMode('charts'), 'small');
            view.iconButton(toolbar, '', 'toolbox', '更多图层操作', @() view.openLayerActions(view.contextLayerName()), 'small');

            view.LayerTree = geodem.view.ContentsPaneBuilder.createLayerTree(view, layout);
            view.LayerTree.Layout.Row = 2;
        end

        function tree = createLayerTree(view, parent)
            htmlFile = fullfile(view.ProjectRoot, 'assets', 'layer-tree.html');
            try
                if exist('uihtml', 'file') ~= 2 || ~isfile(htmlFile)
                    error('GeoDEM:LayerTreeHtmlUnavailable', 'HTML layer tree is unavailable.');
                end
                tree = uihtml(parent, 'HTMLSource', htmlFile, ...
                    'DataChangedFcn', @(src, ~) view.onLayerTreeHtmlEvent(src));
                return;
            catch
            end
            tree = uilistbox(parent, 'Items', {}, ...
                'ValueChangedFcn', @(src, ~) view.onLayerTreeHtmlEvent(src));
            geodem.compat.setUiProperty(tree, 'Tooltip', 'HTML 图层树不可用，已切换到兼容列表模式。');
        end
    end
end
