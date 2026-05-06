classdef LayerStyle
    %LAYERSTYLE Visual defaults for a GIS layer.

    properties
        icon
        colormap
        alpha
        lineWidth
        marker
        labelsEnabled
    end

    methods
        function obj = LayerStyle(icon, colormapValue, alpha, lineWidth, marker, labelsEnabled)
            if nargin < 1
                icon = "";
            end
            if nargin < 2
                colormapValue = [];
            end
            if nargin < 3 || isempty(alpha)
                alpha = 1;
            end
            if nargin < 4 || isempty(lineWidth)
                lineWidth = 1;
            end
            if nargin < 5 || isempty(marker)
                marker = "o";
            end
            if nargin < 6 || isempty(labelsEnabled)
                labelsEnabled = false;
            end
            obj.icon = string(icon);
            obj.colormap = colormapValue;
            obj.alpha = alpha;
            obj.lineWidth = lineWidth;
            obj.marker = string(marker);
            obj.labelsEnabled = logical(labelsEnabled);
        end
    end
end
