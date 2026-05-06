classdef IconFactory
    %ICONFACTORY Generates original PNG UI icons for GeoDEM Pro.

    methods (Static)
        function iconDir = ensureIcons(projectRoot)
            if nargin < 1 || isempty(projectRoot)
                projectRoot = pwd;
            end
            iconDir = fullfile(projectRoot, 'assets', 'icons');
            persistent preparedRoots
            rootKey = char(string(iconDir));
            if ~isempty(preparedRoots) && isKey(preparedRoots, rootKey)
                return;
            end
            if ~exist(iconDir, 'dir')
                mkdir(iconDir);
            end
            specs = geodem.view.IconFactory.iconSpecs();
            names = fieldnames(specs);
            for i = 1:numel(names)
                spec = specs.(names{i});
                for sizePx = [24 32 48]
                    sizeDir = fullfile(iconDir, string(sizePx));
                    if ~exist(sizeDir, 'dir')
                        mkdir(sizeDir);
                    end
                    file = fullfile(sizeDir, sprintf('%s.png', names{i}));
                    img = geodem.view.IconFactory.drawIcon(spec, sizePx);
                    geodem.view.IconFactory.writeIconIfChanged(file, img);
                end
            end
            if isempty(preparedRoots)
                preparedRoots = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            end
            preparedRoots(rootKey) = true;
        end

        function file = getIcon(projectRoot, name, sizePx)
            if nargin < 3 || isempty(sizePx)
                sizePx = 32;
            end
            iconDir = geodem.view.IconFactory.ensureIcons(projectRoot);
            file = fullfile(iconDir, string(sizePx), sprintf('%s.png', char(name)));
            if ~isfile(file)
                file = fullfile(iconDir, string(sizePx), 'layer.png');
            end
        end

        function icons = iconMap(projectRoot, sizePx)
            if nargin < 2
                sizePx = 32;
            end
            geodem.view.IconFactory.ensureIcons(projectRoot);
            specs = geodem.view.IconFactory.iconSpecs();
            names = fieldnames(specs);
            icons = struct();
            for i = 1:numel(names)
                icons.(names{i}) = geodem.view.IconFactory.getIcon(projectRoot, names{i}, sizePx);
            end
        end

        function specs = iconSpecs()
            specs = struct();
            specs.project = struct('Glyph', 'folder', 'Color', [0.15 0.33 0.56]);
            specs.open = struct('Glyph', 'folderOpen', 'Color', [0.14 0.44 0.70]);
            specs.save = struct('Glyph', 'disk', 'Color', [0.16 0.47 0.31]);
            specs.import = struct('Glyph', 'arrowDown', 'Color', [0.13 0.42 0.70]);
            specs.las = struct('Glyph', 'points', 'Color', [0.38 0.35 0.67]);
            specs.pointcloud = struct('Glyph', 'points', 'Color', [0.15 0.39 0.61]);
            specs.clean = struct('Glyph', 'spark', 'Color', [0.10 0.49 0.46]);
            specs.density = struct('Glyph', 'grid', 'Color', [0.20 0.50 0.62]);
            specs.grid = struct('Glyph', 'grid', 'Color', [0.18 0.42 0.58]);
            specs.clip = struct('Glyph', 'crop', 'Color', [0.10 0.46 0.54]);
            specs.dem = struct('Glyph', 'terrain', 'Color', [0.22 0.55 0.25]);
            specs.interpolate = struct('Glyph', 'mesh', 'Color', [0.28 0.49 0.26]);
            specs.diff = struct('Glyph', 'delta', 'Color', [0.44 0.36 0.72]);
            specs.contour = struct('Glyph', 'contour', 'Color', [0.13 0.34 0.64]);
            specs.classmap = struct('Glyph', 'classes', 'Color', [0.55 0.32 0.16]);
            specs.profile = struct('Glyph', 'profile', 'Color', [0.60 0.29 0.27]);
            specs.surface3d = struct('Glyph', 'cube', 'Color', [0.24 0.41 0.70]);
            specs.export = struct('Glyph', 'arrowUp', 'Color', [0.19 0.52 0.28]);
            specs.report = struct('Glyph', 'doc', 'Color', [0.52 0.33 0.16]);
            specs.geotiff = struct('Glyph', 'raster', 'Color', [0.18 0.50 0.35]);
            specs.shape = struct('Glyph', 'polyline', 'Color', [0.48 0.29 0.63]);
            specs.zoom = struct('Glyph', 'magnifier', 'Color', [0.16 0.35 0.57]);
            specs.pan = struct('Glyph', 'hand', 'Color', [0.21 0.44 0.54]);
            specs.identify = struct('Glyph', 'info', 'Color', [0.19 0.42 0.70]);
            specs.measure = struct('Glyph', 'measure', 'Color', [0.32 0.47 0.52]);
            specs.attribute = struct('Glyph', 'table', 'Color', [0.30 0.38 0.48]);
            specs.fullExtent = struct('Glyph', 'extent', 'Color', [0.17 0.43 0.55]);
            specs.layer = struct('Glyph', 'layer', 'Color', [0.25 0.34 0.46]);
            specs.chart = struct('Glyph', 'chart', 'Color', [0.50 0.35 0.68]);
            specs.map = struct('Glyph', 'map', 'Color', [0.17 0.43 0.60]);
            specs.compare = struct('Glyph', 'classes', 'Color', [0.22 0.42 0.64]);
            specs.spark = struct('Glyph', 'spark', 'Color', [0.10 0.49 0.46]);
            specs.workflow = struct('Glyph', 'workflow', 'Color', [0.14 0.42 0.70]);
            specs.toolbox = struct('Glyph', 'toolbox', 'Color', [0.28 0.43 0.58]);
            specs.quality = struct('Glyph', 'quality', 'Color', [0.10 0.47 0.45]);
            specs.exportData = struct('Glyph', 'exportData', 'Color', [0.19 0.52 0.28]);
        end

        function img = drawIcon(spec, sizePx)
            scale = 3;
            raw = geodem.view.IconFactory.drawIconCore(spec, sizePx * scale);
            img = downsampleIcon(raw, scale);
        end

        function writeIconIfChanged(file, img)
            % Avoid rewriting tracked generated PNGs when pixel data is unchanged.
            rgb = uint8(round(255 * min(max(img(:, :, 1:3), 0), 1)));
            alpha = uint8(round(255 * min(max(img(:, :, 4), 0), 1)));
            if isfile(file)
                try
                    [existingRgb, ~, existingAlpha] = imread(file);
                    if isempty(existingAlpha)
                        existingAlpha = uint8(255 * ones(size(existingRgb, 1), size(existingRgb, 2)));
                    end
                    if isequal(existingRgb, rgb) && isequal(existingAlpha, alpha)
                        return;
                    end
                catch
                    % Fall through and rewrite corrupt or unreadable icon files.
                end
            end
            imwrite(rgb, file, 'Alpha', alpha);
        end

        function img = drawIconCore(spec, sizePx)
            bg = ones(sizePx, sizePx, 4);
            bg(:, :, 4) = 0;
            color = spec.Color;
            glyph = spec.Glyph;
            img = bg;
            [X, Y] = meshgrid(1:sizePx, 1:sizePx);
            pad = max(2, round(sizePx * 0.12));
            img = rect(img, round(sizePx*.08), round(sizePx*.08), round(sizePx*.92), round(sizePx*.92), [0.95 0.97 0.99], .72);
            img = rectLine(img, round(sizePx*.08), round(sizePx*.08), round(sizePx*.92), round(sizePx*.92), color*.70 + [0.18 0.18 0.18], max(1, sizePx*.015), .55);
            switch glyph
                case 'folder'
                    img = rect(img, pad, round(sizePx*.34), sizePx-pad, sizePx-pad, color, .95);
                    img = rect(img, pad+2, round(sizePx*.24), round(sizePx*.52), round(sizePx*.40), color*.85, .95);
                case 'folderOpen'
                    img = rect(img, pad, round(sizePx*.36), sizePx-pad, sizePx-pad, color, .95);
                    img = poly(img, [pad sizePx-pad sizePx-round(pad*.7) round(pad*1.5)], [round(sizePx*.45) round(sizePx*.45) sizePx-pad sizePx-pad], color*1.08, .95);
                case 'disk'
                    img = rect(img, pad, pad, sizePx-pad, sizePx-pad, color, .95);
                    img = rect(img, round(sizePx*.34), pad+2, sizePx-pad-2, round(sizePx*.38), [0.90 0.94 0.98], 1);
                    img = rect(img, round(sizePx*.28), round(sizePx*.64), round(sizePx*.72), sizePx-pad, [0.86 0.91 0.95], 1);
                case 'arrowDown'
                    img = arrow(img, sizePx, color, 'down');
                case 'arrowUp'
                    img = arrow(img, sizePx, color, 'up');
                case 'points'
                    rng(7);
                    centers = pad + rand(18, 2) * (sizePx - 2*pad);
                    for k = 1:size(centers, 1)
                        img = circle(img, centers(k,1), centers(k,2), max(1.5, sizePx*.045), color*(.75+0.4*rand), .95);
                    end
                case 'spark'
                    img = circle(img, sizePx*.5, sizePx*.5, sizePx*.22, color, .95);
                    img = lineIcon(img, [sizePx*.20 sizePx*.80], [sizePx*.75 sizePx*.25], [1 1 1], max(2,sizePx*.08), 1);
                    img = lineIcon(img, [sizePx*.22 sizePx*.46], [sizePx*.30 sizePx*.54], [1 1 1], max(2,sizePx*.06), 1);
                case 'grid'
                    img = rect(img, pad, pad, sizePx-pad, sizePx-pad, color, .18);
                    for t = linspace(pad, sizePx-pad, 5)
                        img = lineIcon(img, [pad sizePx-pad], [t t], color, 1.3, .9);
                        img = lineIcon(img, [t t], [pad sizePx-pad], color, 1.3, .9);
                    end
                case 'crop'
                    img = lineIcon(img, [sizePx*.25 sizePx*.25 sizePx*.74], [sizePx*.12 sizePx*.74 sizePx*.74], color, max(2,sizePx*.08), 1);
                    img = lineIcon(img, [sizePx*.75 sizePx*.75 sizePx*.26], [sizePx*.88 sizePx*.26 sizePx*.26], color, max(2,sizePx*.08), 1);
                case 'terrain'
                    img = poly(img, [pad sizePx*.35 sizePx*.53 sizePx-pad], [sizePx-pad sizePx*.44 sizePx*.62 sizePx-pad], color, .95);
                    img = lineIcon(img, [pad sizePx-pad], [sizePx*.70 sizePx*.70], color*.75, 1.5, 1);
                    img = lineIcon(img, [pad sizePx-pad], [sizePx*.82 sizePx*.82], color*.65, 1.5, 1);
                case 'mesh'
                    for t = linspace(sizePx*.25, sizePx*.75, 4)
                        img = lineIcon(img, [sizePx*.16 sizePx*.84], [t sizePx-t], color, 1.4, .95);
                        img = lineIcon(img, [sizePx*.16 sizePx*.84], [sizePx-t t], color, 1.4, .95);
                    end
                case 'delta'
                    img = poly(img, [sizePx*.50 sizePx*.18 sizePx*.82], [sizePx*.18 sizePx*.82 sizePx*.82], color, .95);
                    img = poly(img, [sizePx*.50 sizePx*.36 sizePx*.64], [sizePx*.42 sizePx*.72 sizePx*.72], [1 1 1], 1);
                case 'contour'
                    for r = [.18 .31 .44]
                        img = ellipseLine(img, sizePx*.50, sizePx*.50, sizePx*r, sizePx*(r*.63), color, 1.5, 1);
                    end
                case 'classes'
                    colors = [0.10 0.31 0.74; 0.62 0.75 0.95; 0.92 0.92 0.92; 0.95 0.45 0.22];
                    for k = 1:4
                        x1 = pad + mod(k-1,2)*(sizePx*.36);
                        y1 = pad + floor((k-1)/2)*(sizePx*.36);
                        img = rect(img, x1, y1, x1+sizePx*.28, y1+sizePx*.28, colors(k,:), .95);
                    end
                case 'profile'
                    xs = linspace(pad, sizePx-pad, 7);
                    ys = [0.73 0.58 0.64 0.36 0.44 0.30 0.46] * sizePx;
                    img = lineIcon(img, xs, ys, color, max(2,sizePx*.08), 1);
                case 'cube'
                    img = poly(img, [sizePx*.30 sizePx*.55 sizePx*.78 sizePx*.52], [sizePx*.30 sizePx*.18 sizePx*.34 sizePx*.48], color*1.15, .95);
                    img = poly(img, [sizePx*.30 sizePx*.52 sizePx*.52 sizePx*.30], [sizePx*.30 sizePx*.48 sizePx*.78 sizePx*.62], color*.85, .95);
                    img = poly(img, [sizePx*.52 sizePx*.78 sizePx*.78 sizePx*.52], [sizePx*.48 sizePx*.34 sizePx*.64 sizePx*.78], color, .95);
                case 'doc'
                    img = rect(img, sizePx*.25, pad, sizePx*.75, sizePx-pad, [0.96 0.97 0.98], 1);
                    img = lineIcon(img, [sizePx*.35 sizePx*.66], [sizePx*.38 sizePx*.38], color, 1.4, 1);
                    img = lineIcon(img, [sizePx*.35 sizePx*.66], [sizePx*.52 sizePx*.52], color, 1.4, 1);
                    img = lineIcon(img, [sizePx*.35 sizePx*.56], [sizePx*.66 sizePx*.66], color, 1.4, 1);
                case 'raster'
                    img = rect(img, pad, pad, sizePx-pad, sizePx-pad, color, .12);
                    for k = 0:3
                        img = rect(img, pad+k*sizePx*.18, pad+k*sizePx*.10, pad+(k+1)*sizePx*.18, sizePx-pad, color*(1-.07*k), .72);
                    end
                case 'polyline'
                    xs = [sizePx*.18 sizePx*.36 sizePx*.58 sizePx*.80];
                    ys = [sizePx*.70 sizePx*.36 sizePx*.58 sizePx*.24];
                    img = lineIcon(img, xs, ys, color, max(2,sizePx*.08), 1);
                    for k=1:numel(xs), img = circle(img, xs(k), ys(k), sizePx*.055, [1 1 1], 1); end
                case 'magnifier'
                    img = ellipseLine(img, sizePx*.42, sizePx*.40, sizePx*.20, sizePx*.20, color, max(2,sizePx*.07), 1);
                    img = lineIcon(img, [sizePx*.57 sizePx*.80], [sizePx*.58 sizePx*.82], color, max(2,sizePx*.08), 1);
                case 'hand'
                    img = rect(img, sizePx*.34, sizePx*.35, sizePx*.70, sizePx*.76, color, .95);
                    for k = 0:3
                        img = rect(img, sizePx*(.28+.10*k), sizePx*.20, sizePx*(.36+.10*k), sizePx*.48, color, .95);
                    end
                case 'info'
                    img = circle(img, sizePx*.5, sizePx*.5, sizePx*.36, color, .95);
                    img = circle(img, sizePx*.5, sizePx*.32, sizePx*.045, [1 1 1], 1);
                    img = lineIcon(img, [sizePx*.5 sizePx*.5], [sizePx*.43 sizePx*.68], [1 1 1], max(2,sizePx*.08), 1);
                case 'measure'
                    img = lineIcon(img, [sizePx*.18 sizePx*.82], [sizePx*.72 sizePx*.28], color, max(3,sizePx*.09), 1);
                    for k=0:4
                        t = k/4; x = sizePx*(.18 + .64*t); y = sizePx*(.72 - .44*t);
                        img = lineIcon(img, [x x+sizePx*.05], [y y+sizePx*.08], [1 1 1], 1.2, 1);
                    end
                case 'table'
                    img = rect(img, pad, pad, sizePx-pad, sizePx-pad, color, .12);
                    for t = linspace(pad, sizePx-pad, 4)
                        img = lineIcon(img, [pad sizePx-pad], [t t], color, 1.4, 1);
                        img = lineIcon(img, [t t], [pad sizePx-pad], color, 1.4, 1);
                    end
                case 'extent'
                    img = rectLine(img, pad, pad, sizePx-pad, sizePx-pad, color, max(2,sizePx*.07), 1);
                    img = lineIcon(img, [sizePx*.32 sizePx*.68], [sizePx*.50 sizePx*.50], color, 1.4, 1);
                    img = lineIcon(img, [sizePx*.50 sizePx*.50], [sizePx*.32 sizePx*.68], color, 1.4, 1);
                case 'layer'
                    img = poly(img, [sizePx*.20 sizePx*.50 sizePx*.80 sizePx*.50], [sizePx*.38 sizePx*.20 sizePx*.38 sizePx*.56], color*1.1, .95);
                    img = poly(img, [sizePx*.20 sizePx*.50 sizePx*.80 sizePx*.50], [sizePx*.52 sizePx*.34 sizePx*.52 sizePx*.70], color*.9, .75);
                    img = poly(img, [sizePx*.20 sizePx*.50 sizePx*.80 sizePx*.50], [sizePx*.66 sizePx*.48 sizePx*.66 sizePx*.84], color*.75, .65);
                case 'chart'
                    for k=1:4
                        img = rect(img, sizePx*(.18+.15*(k-1)), sizePx*(.78-.11*k), sizePx*(.28+.15*(k-1)), sizePx*.80, color*(.75+.08*k), .95);
                    end
                case 'map'
                    img = rect(img, pad, pad, sizePx-pad, sizePx-pad, color, .15);
                    img = lineIcon(img, [sizePx*.28 sizePx*.42 sizePx*.55 sizePx*.72], [sizePx*.80 sizePx*.28 sizePx*.70 sizePx*.22], color, 1.8, 1);
                case 'workflow'
                    nodes = [sizePx*.24 sizePx*.32; sizePx*.50 sizePx*.50; sizePx*.76 sizePx*.32; sizePx*.76 sizePx*.72];
                    img = lineIcon(img, nodes([1 2 3 4],1), nodes([1 2 3 4],2), color, max(2,sizePx*.06), .95);
                    for k = 1:size(nodes, 1)
                        img = circle(img, nodes(k,1), nodes(k,2), sizePx*.075, [0.96 0.98 1.00], 1);
                        img = circle(img, nodes(k,1), nodes(k,2), sizePx*.045, color, 1);
                    end
                case 'toolbox'
                    img = rect(img, sizePx*.22, sizePx*.34, sizePx*.78, sizePx*.74, color, .92);
                    img = rectLine(img, sizePx*.38, sizePx*.24, sizePx*.62, sizePx*.38, color, max(2,sizePx*.045), 1);
                    img = lineIcon(img, [sizePx*.22 sizePx*.78], [sizePx*.48 sizePx*.48], [0.96 0.98 1], max(1.5,sizePx*.04), .9);
                case 'quality'
                    img = circle(img, sizePx*.50, sizePx*.50, sizePx*.30, color, .92);
                    img = lineIcon(img, [sizePx*.35 sizePx*.47 sizePx*.68], [sizePx*.52 sizePx*.65 sizePx*.36], [1 1 1], max(2,sizePx*.07), 1);
                case 'exportData'
                    img = rect(img, sizePx*.24, sizePx*.28, sizePx*.76, sizePx*.78, color, .12);
                    img = lineIcon(img, [sizePx*.50 sizePx*.50], [sizePx*.22 sizePx*.58], color, max(2,sizePx*.075), 1);
                    img = poly(img, [sizePx*.34 sizePx*.66 sizePx*.50], [sizePx*.38 sizePx*.38 sizePx*.20], color, .95);
                    img = rectLine(img, sizePx*.28, sizePx*.58, sizePx*.72, sizePx*.78, color, max(1.5,sizePx*.045), 1);
                otherwise
                    img = circle(img, sizePx*.5, sizePx*.5, sizePx*.30, color, .95);
            end
            img = min(max(img, 0), 1);
        end
    end
end

function out = downsampleIcon(img, scale)
[h, w, c] = size(img);
hh = floor(h / scale);
ww = floor(w / scale);
out = zeros(hh, ww, c);
for r = 1:hh
    rows = (r - 1) * scale + (1:scale);
    for col = 1:ww
        cols = (col - 1) * scale + (1:scale);
        block = img(rows, cols, :);
        out(r, col, :) = mean(reshape(block, [], c), 1);
    end
end
out = min(max(out, 0), 1);
end

function img = rect(img, x1, y1, x2, y2, color, alpha)
[X,Y] = meshgrid(1:size(img,2), 1:size(img,1));
mask = X>=round(x1) & X<=round(x2) & Y>=round(y1) & Y<=round(y2);
img = paint(img, mask, color, alpha);
end

function img = rectLine(img, x1, y1, x2, y2, color, width, alpha)
img = lineIcon(img, [x1 x2 x2 x1 x1], [y1 y1 y2 y2 y1], color, width, alpha);
end

function img = poly(img, x, y, color, alpha)
[X,Y] = meshgrid(1:size(img,2), 1:size(img,1));
mask = inpolygon(X, Y, x, y);
img = paint(img, mask, color, alpha);
end

function img = circle(img, cx, cy, r, color, alpha)
[X,Y] = meshgrid(1:size(img,2), 1:size(img,1));
mask = (X-cx).^2 + (Y-cy).^2 <= r.^2;
img = paint(img, mask, color, alpha);
end

function img = ellipseLine(img, cx, cy, rx, ry, color, width, alpha)
t = linspace(0, 2*pi, 120);
img = lineIcon(img, cx + rx*cos(t), cy + ry*sin(t), color, width, alpha);
end

function img = lineIcon(img, x, y, color, width, alpha)
[X,Y] = meshgrid(1:size(img,2), 1:size(img,1));
mask = false(size(X));
for i = 1:numel(x)-1
    x1 = x(i); x2 = x(i+1); y1 = y(i); y2 = y(i+1);
    dx = x2-x1; dy = y2-y1;
    denom = max(dx*dx + dy*dy, eps);
    t = max(0, min(1, ((X-x1)*dx + (Y-y1)*dy) ./ denom));
    dist = sqrt((X-(x1+t*dx)).^2 + (Y-(y1+t*dy)).^2);
    mask = mask | dist <= width/2;
end
img = paint(img, mask, color, alpha);
end

function img = arrow(img, sizePx, color, direction)
if strcmp(direction, 'down')
    img = rect(img, sizePx*.44, sizePx*.18, sizePx*.56, sizePx*.58, color, .95);
    img = poly(img, [sizePx*.25 sizePx*.75 sizePx*.50], [sizePx*.54 sizePx*.54 sizePx*.82], color, .95);
else
    img = rect(img, sizePx*.44, sizePx*.42, sizePx*.56, sizePx*.82, color, .95);
    img = poly(img, [sizePx*.25 sizePx*.75 sizePx*.50], [sizePx*.46 sizePx*.46 sizePx*.18], color, .95);
end
end

function img = paint(img, mask, color, alpha)
for c = 1:3
    layer = img(:,:,c);
    layer(mask) = color(c);
    img(:,:,c) = layer;
end
layer = img(:,:,4);
layer(mask) = alpha;
img(:,:,4) = layer;
end
