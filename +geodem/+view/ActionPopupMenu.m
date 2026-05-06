classdef ActionPopupMenu < handle
    properties
        View
        Panel
        Layout
        Items
        HitRows
    end

    methods
        function obj = ActionPopupMenu(view)
            obj.View = view;
            obj.Panel = uipanel(view.UIFigure, 'Visible', 'off', 'BorderType', 'line');
            geodem.compat.setUiProperty(obj.Panel, 'BackgroundColor', [1 1 1]);
            obj.Panel.AutoResizeChildren = 'off';
            obj.Panel.Position = [20 20 210 200];
            obj.Layout = uigridlayout(obj.Panel, [1 1]);
            obj.Layout.Padding = [1 1 1 1];
            obj.Layout.RowSpacing = 0;
            obj.Layout.ColumnSpacing = 0;
            geodem.compat.setUiProperty(obj.Layout, 'BackgroundColor', [1 1 1]);
        end

        function showLayerMenu(obj, layerName, anchorPoint)
            if nargin < 2 || strlength(string(layerName)) == 0
                layerName = obj.View.contextLayerName();
            end
            if strlength(string(layerName)) == 0
                layerName = obj.View.Controller.Project.activeLayer;
            end
            if nargin < 3 || isempty(anchorPoint)
                anchorPoint = obj.View.UIFigure.CurrentPoint;
            end
            obj.populate(obj.layerItems(string(layerName)));
            obj.placeNear(anchorPoint, [210, obj.menuHeight()]);
            obj.Panel.Visible = 'on';
            try, uistack(obj.Panel, 'top'); catch, end
        end

        function showViewMenu(obj, anchorPoint)
            if nargin < 2 || isempty(anchorPoint)
                anchorPoint = obj.View.UIFigure.CurrentPoint;
            end
            obj.populate(obj.viewItems());
            obj.placeNear(anchorPoint, [210, obj.menuHeight()]);
            obj.Panel.Visible = 'on';
            try, uistack(obj.Panel, 'top'); catch, end
        end

        function hide(obj)
            if ~isempty(obj.Panel) && isvalid(obj.Panel)
                obj.Panel.Visible = 'off';
            end
        end

        function tf = isVisible(obj)
            tf = ~isempty(obj.Panel) && isvalid(obj.Panel) && strcmpi(char(obj.Panel.Visible), 'on');
        end

        function tf = containsHandle(obj, h)
            tf = false;
            if isempty(h) || ~obj.isVisible()
                return;
            end
            try
                tf = any(findall(obj.Panel) == h);
            catch
            end
        end

        function tf = handleClick(obj, point)
            tf = false;
            if ~obj.isVisible() || isempty(obj.HitRows)
                return;
            end
            pos = obj.Panel.Position;
            if point(1) < pos(1) || point(1) > pos(1) + pos(3) || point(2) < pos(2) || point(2) > pos(2) + pos(4)
                return;
            end
            yFromTop = pos(4) - (point(2) - pos(2));
            for i = 1:numel(obj.HitRows)
                row = obj.HitRows(i);
                if yFromTop >= row.Top && yFromTop <= row.Bottom
                    tf = true;
                    obj.runItem(row.Callback);
                    return;
                end
            end
            tf = true;
        end
    end

    methods (Access = private)
        function populate(obj, items)
            obj.Items = items;
            obj.HitRows = struct('Top', {}, 'Bottom', {}, 'Callback', {});
            delete(obj.Layout.Children);
            rowHeights = {};
            for i = 1:numel(items)
                if isfield(items{i}, 'SeparatorBefore') && items{i}.SeparatorBefore
                    rowHeights{end + 1} = 5; %#ok<AGROW>
                end
                rowHeights{end + 1} = 20; %#ok<AGROW>
            end
            obj.Layout.RowHeight = rowHeights;
            row = 1;
            yTop = 1;
            for i = 1:numel(items)
                item = items{i};
                if isfield(item, 'SeparatorBefore') && item.SeparatorBefore
                    sep = uipanel(obj.Layout, 'BorderType', 'none', 'BackgroundColor', [1 1 1]);
                    sep.Layout.Row = row;
                    sep.Layout.Column = 1;
                    lineGrid = uigridlayout(sep, [1 1]);
                    lineGrid.Padding = [6 2 6 2];
                    lineGrid.RowSpacing = 0;
                    lineGrid.ColumnSpacing = 0;
                    geodem.compat.setUiProperty(lineGrid, 'BackgroundColor', [1 1 1]);
                    uipanel(lineGrid, 'BorderType', 'none', 'BackgroundColor', [0.84 0.84 0.84]);
                    row = row + 1;
                    yTop = yTop + 5;
                end
                itemPanel = obj.menuRow(item);
                itemPanel.Layout.Row = row;
                itemPanel.Layout.Column = 1;
                obj.HitRows(end + 1) = struct('Top', yTop, 'Bottom', yTop + 20, 'Callback', item.Callback); %#ok<AGROW>
                row = row + 1;
                yTop = yTop + 20;
            end
        end

        function itemPanel = menuRow(obj, item)
            itemPanel = uipanel(obj.Layout, 'BorderType', 'none', 'BackgroundColor', [1 1 1]);
            grid = uigridlayout(itemPanel, [1 1]);
            grid.Padding = [8 0 8 0];
            grid.ColumnSpacing = 0;
            geodem.compat.setUiProperty(grid, 'BackgroundColor', [1 1 1]);

            textLabel = uilabel(grid, 'Text', char(item.Text), 'FontSize', 11, ...
                'FontColor', [0.08 0.08 0.08], 'HorizontalAlignment', 'left');
            textLabel.Layout.Column = 1;

            geodem.compat.setUiProperty(itemPanel, 'Tooltip', item.Tooltip);
            geodem.compat.setUiProperty(grid, 'Tooltip', item.Tooltip);
            geodem.compat.setUiProperty(textLabel, 'Tooltip', item.Tooltip);
        end

        function runItem(obj, callback)
            obj.hide();
            try
                callback();
            catch ME
                obj.View.Controller.log(['错误：' ME.message]);
            end
        end

        function h = menuHeight(obj)
            h = 2;
            for i = 1:numel(obj.Items)
                if isfield(obj.Items{i}, 'SeparatorBefore') && obj.Items{i}.SeparatorBefore
                    h = h + 5;
                end
                h = h + 20;
            end
        end

        function placeNear(obj, anchorPoint, sizePx)
            figPos = obj.View.UIFigure.Position;
            w = sizePx(1);
            h = sizePx(2);
            x = max(8, min(figPos(3) - w - 8, round(anchorPoint(1))));
            y = max(8, min(figPos(4) - h - 8, round(anchorPoint(2) - h)));
            obj.Panel.Position = [x y w h];
        end

        function items = layerItems(obj, layerName)
            items = {
                obj.item('显示图层', '显示并设为当前激活图层', @() obj.View.Controller.renderLayer(layerName))
                obj.item('仅显示此图层', '仅显示当前图层', @() obj.View.Controller.showOnlyLayer(layerName))
                obj.item('隐藏图层', '隐藏当前图层', @() obj.View.Controller.hideLayer(layerName))
                obj.item('缩放至图层', '缩放到当前图层范围', @() obj.View.Controller.zoomToLayer(layerName), true)
                obj.item('打开属性表', '查看当前图层属性表', @() obj.View.Controller.openAttributeTable(layerName))
                obj.item('属性', '查看图层详细属性与来源', @() obj.View.Controller.showLayerInfo(layerName), true)
                obj.item('重命名', '重命名当前图层', @() obj.View.Controller.renameLayer(layerName))
                obj.item('导出', '导出图层数据文件', @() obj.View.Controller.exportLayer(layerName), true)
                obj.item('删除', '删除当前图层', @() obj.View.Controller.deleteLayer(layerName))
                };
        end

        function items = viewItems(obj)
            items = {
                obj.item('新建二维地图标签页', '新建一个二维地图标签页', @() obj.View.addCustomViewTab('map'))
                obj.item('新建三维场景标签页', '新建一个三维场景标签页', @() obj.View.addCustomViewTab('scene'))
                obj.item('重命名当前标签页', '重命名当前标签页', @() obj.View.renameCurrentViewTab(), true)
                obj.item('关闭当前标签页', '关闭当前自定义标签页', @() obj.View.closeCurrentViewTab())
                };
        end

        function item = item(~, text, tooltip, callback, separatorBefore)
            if nargin < 5
                separatorBefore = false;
            end
            item = struct('Text', text, 'Tooltip', tooltip, ...
                'Callback', callback, 'SeparatorBefore', separatorBefore);
        end
    end
end
