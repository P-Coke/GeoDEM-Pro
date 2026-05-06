classdef LayerTreeView < handle
    %LAYERTREEVIEW Owns the layer tree data and interactions.

    properties
        View
        Tree
        Data
        SelectedLayerName = ""
        LastLayerSignature = ""
        IsHtmlTree = true
        ListLayerNames = strings(0, 1)
    end

    methods
        function obj = LayerTreeView(view, tree)
            obj.View = view;
            obj.Tree = tree;
            obj.IsHtmlTree = ~isempty(tree) && isvalid(tree) && isprop(tree, 'Data');
        end

        function setLayers(obj, layers)
            layers = geodem.model.ProjectState.normalizeLayerTable(layers);
            sig = obj.layerTableSignature(layers);
            if obj.LastLayerSignature == sig && ~isempty(obj.Tree) && isvalid(obj.Tree)
                return;
            end
            obj.LastLayerSignature = sig;
            obj.updateTree(layers);
        end

        function updateTree(obj, layers)
            if isempty(obj.Tree) || ~isvalid(obj.Tree)
                return;
            end
            if ~obj.IsHtmlTree
                obj.updateList(layers);
                return;
            end
            items = struct('type', {}, 'text', {}, 'layer', {}, 'icon', {}, 'visible', {}, 'selected', {});
            activeLayer = string(obj.View.Controller.Project.activeLayer);
            obj.SelectedLayerName = activeLayer;
            if ~isempty(layers)
                groups = unique(layers.Group, 'stable');
                for i = 1:numel(groups)
                    items(end + 1) = struct('type', 'group', 'text', char("▾  " + string(groups(i))), ...
                        'layer', '', 'icon', '', 'visible', true, 'selected', false); %#ok<AGROW>
                    rows = find(layers.Group == groups(i));
                    for j = 1:numel(rows)
                        row = rows(j);
                        layerName = string(layers.Name(row));
                        iconName = string(layers.Icon(row));
                        if strlength(iconName) == 0
                            iconName = "layer";
                        end
                        items(end + 1) = struct('type', 'layer', 'text', char(layerName), ...
                            'layer', char(layerName), 'icon', geodem.compat.localPngDataUri(obj.View.iconPath(iconName, 24)), ...
                            'visible', logical(layers.Visible(row)), ...
                            'selected', layerName == activeLayer); %#ok<AGROW>
                    end
                end
            end
            obj.Data = struct('kind', 'layers', 'activeLayer', char(activeLayer), 'items', items);
            try
                obj.Tree.Data = obj.Data;
            catch
                obj.switchToListFallback(layers);
            end
        end

        function onHtmlEvent(obj, src)
            if ~obj.IsHtmlTree
                obj.onListEvent(src);
                return;
            end
            data = src.Data;
            if ~isstruct(data) || ~isfield(data, 'action')
                return;
            end
            action = string(data.action);
            layerName = "";
            if isfield(data, 'layer')
                layerName = string(data.layer);
            end
            if strlength(layerName) == 0
                return;
            end
            obj.SelectedLayerName = layerName;
            switch action
                case "select"
                    obj.View.Controller.renderLayer(layerName);
                case "context"
                    obj.View.ActionPopup.showLayerMenu(layerName, obj.menuAnchor(data));
                    obj.restoreData();
            end
        end

        function onListEvent(obj, src)
            try
                value = string(src.Value);
                items = string(src.Items);
                idx = find(items == value, 1);
                if isempty(idx) || idx > numel(obj.ListLayerNames)
                    return;
                end
                layerName = string(obj.ListLayerNames(idx));
                if strlength(layerName) == 0
                    return;
                end
                obj.SelectedLayerName = layerName;
                obj.View.Controller.renderLayer(layerName);
            catch
            end
        end

        function restoreData(obj)
            try
                if ~isempty(obj.Data)
                    obj.Tree.Data = obj.Data;
                end
            catch
            end
        end

        function anchorPoint = menuAnchor(obj, data)
            anchorPoint = obj.View.UIFigure.CurrentPoint;
            try
                x = double(data.x);
                y = double(data.y);
                figHeight = obj.View.UIFigure.Position(4);
                anchorPoint = [18 + x, figHeight - 38 - 138 - y];
            catch
            end
        end

        function layerName = contextLayerName(obj)
            layerName = obj.SelectedLayerName;
            if strlength(layerName) == 0
                layerName = string(obj.View.Controller.Project.activeLayer);
            end
        end
    end

    methods (Access = private)
        function updateList(obj, layers)
            items = strings(0, 1);
            layerNames = strings(0, 1);
            activeLayer = string(obj.View.Controller.Project.activeLayer);
            obj.SelectedLayerName = activeLayer;
            if ~isempty(layers)
                groups = unique(layers.Group, 'stable');
                for i = 1:numel(groups)
                    items(end + 1, 1) = "▾  " + string(groups(i)); %#ok<AGROW>
                    layerNames(end + 1, 1) = ""; %#ok<AGROW>
                    rows = find(layers.Group == groups(i));
                    for j = 1:numel(rows)
                        row = rows(j);
                        layerName = string(layers.Name(row));
                        visibleMark = " ";
                        if logical(layers.Visible(row))
                            visibleMark = "✓";
                        end
                        iconText = obj.fallbackIconText(string(layers.Icon(row)), string(layers.Type(row)));
                        items(end + 1, 1) = "   " + visibleMark + " " + iconText + " " + layerName; %#ok<AGROW>
                        layerNames(end + 1, 1) = layerName; %#ok<AGROW>
                    end
                end
            end
            obj.ListLayerNames = layerNames;
            obj.Tree.Items = cellstr(items);
            activeIdx = find(layerNames == activeLayer, 1);
            if ~isempty(activeIdx)
                obj.Tree.Value = char(items(activeIdx));
            elseif ~isempty(items)
                obj.Tree.Value = char(items(1));
            end
        end

        function switchToListFallback(obj, layers)
            try
                parent = obj.Tree.Parent;
                row = obj.Tree.Layout.Row;
                delete(obj.Tree);
                obj.Tree = uilistbox(parent, 'Items', {}, ...
                    'ValueChangedFcn', @(src, ~) obj.onHtmlEvent(src));
                obj.Tree.Layout.Row = row;
                geodem.compat.setUiProperty(obj.Tree, 'Tooltip', 'HTML 图层树通信失败，已切换到兼容列表模式。');
                obj.View.LayerTree = obj.Tree;
                obj.IsHtmlTree = false;
                obj.updateList(layers);
            catch
            end
        end

        function text = fallbackIconText(~, iconName, typeName)
            key = string(iconName);
            if strlength(key) == 0
                key = string(typeName);
            end
            switch key
                case {"pointcloud","las"}
                    text = "·";
                case {"dem","geotiff"}
                    text = "▲";
                case "density"
                    text = "▦";
                case {"diff","deformation"}
                    text = "△";
                case "classmap"
                    text = "▣";
                case "contour"
                    text = "◎";
                otherwise
                    text = "■";
            end
        end

        function sig = layerTableSignature(~, layers)
            if isempty(layers)
                sig = "";
                return;
            end
            try
                parts = string(layers.Name) + "|" + string(layers.Type) + "|" + string(layers.Visible) + "|" + string(layers.Group) + "|" + string(layers.Icon);
                sig = strjoin(parts, ";;");
            catch
                sig = string(height(layers)) + "_" + string(datetime('now', 'Format', 'HHmmssSSS'));
            end
        end
    end
end
