classdef LayerTable
    %LAYERTABLE Utility functions for layer table keys, defaults, and schema.

    methods (Static)
        function layers = empty()
            layers = table(string.empty(0, 1), string.empty(0, 1), false(0, 1), string.empty(0, 1), string.empty(0, 1), ...
                'VariableNames', {'Name','Type','Visible','Group','Icon'});
        end

        function key = key(layerName)
            key = matlab.lang.makeValidName(char(string(layerName)));
        end

        function layers = normalize(layers)
            if isempty(layers)
                layers = geodem.model.LayerTable.empty();
                return;
            end
            if ~ismember('Group', layers.Properties.VariableNames)
                groups = strings(height(layers), 1);
                icons = strings(height(layers), 1);
                for i = 1:height(layers)
                    [groups(i), icons(i)] = geodem.model.LayerTable.defaults(layers.Type(i), layers.Name(i));
                end
                layers.Group = groups;
                layers.Icon = icons;
            end
            if ~ismember('Icon', layers.Properties.VariableNames)
                icons = strings(height(layers), 1);
                for i = 1:height(layers)
                    [~, icons(i)] = geodem.model.LayerTable.defaults(layers.Type(i), layers.Name(i));
                end
                layers.Icon = icons;
            end
        end

        function [groupName, iconName] = defaults(typeName, layerName)
            typeName = string(typeName);
            layerName = string(layerName);
            switch typeName
                case "pointcloud"
                    groupName = "点云图层";
                    iconName = "pointcloud";
                case "dem"
                    groupName = "DEM 图层";
                    iconName = "dem";
                case "density"
                    groupName = "点云分析图层";
                    iconName = "density";
                case "deformation"
                    groupName = "形变分析图层";
                    iconName = "diff";
                case "contour"
                    groupName = "专题制图图层";
                    iconName = "contour";
                case "classmap"
                    groupName = "形变分析图层";
                    iconName = "classmap";
                case "surface3d"
                    groupName = "三维场景图层";
                    iconName = "surface3d";
                otherwise
                    groupName = "其他图层";
                    iconName = "layer";
            end
            if contains(layerName, "等值线")
                iconName = "contour";
            elseif contains(layerName, "等级")
                iconName = "classmap";
            elseif contains(layerName, "密度")
                iconName = "density";
            elseif contains(layerName, "三维")
                iconName = "surface3d";
            end
        end
    end
end
