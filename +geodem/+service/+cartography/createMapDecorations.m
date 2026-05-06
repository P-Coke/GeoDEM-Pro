function createMapDecorations(ax, titleText, paramsText)
%CREATEMAPDECORATIONS Add GIS-style map finishing elements to axes.

if nargin < 2
    titleText = "";
end
if nargin < 3
    paramsText = "";
end
title(ax, titleText, 'FontWeight', 'bold', 'Interpreter', 'none');
grid(ax, 'on');
ax.Layer = 'top';
try
    ax.XMinorGrid = 'off';
    ax.YMinorGrid = 'off';
    ax.GridLineStyle = '-';
    ax.GridColor = [0.64 0.68 0.72];
    ax.GridAlpha = 0.28;
    ax.MinorGridAlpha = 0;
    ax.XAxis.Exponent = 0;
    ax.YAxis.Exponent = 0;
    xtickformat(ax, '%.0f');
    ytickformat(ax, '%.0f');
catch
end
xlabel(ax, 'X / m');
ylabel(ax, 'Y / m');

xl = xlim(ax);
yl = ylim(ax);
width = diff(xl);
height = diff(yl);
if width <= 0 || height <= 0
    return;
end

holdState = ishold(ax);
hold(ax, 'on');
scaleLen = niceScale(width * 0.18);
x0 = xl(1) + width * 0.06;
y0 = yl(1) + height * 0.07;
plot(ax, [x0 x0+scaleLen], [y0 y0], 'k-', 'LineWidth', 3, 'Tag', 'MapDecoration');
text(ax, x0 + scaleLen/2, y0 + height*0.025, sprintf('%.0f m', scaleLen), ...
    'HorizontalAlignment', 'center', 'FontSize', 8, 'BackgroundColor', 'w', 'Margin', 1, 'Tag', 'MapDecoration', 'Interpreter', 'none');

nx = xl(2) - width * 0.08;
ny = yl(2) - height * 0.12;
plot(ax, [nx nx], [ny-height*.055 ny+height*.055], 'k-', 'LineWidth', 1.6, 'Tag', 'MapDecoration');
plot(ax, [nx-width*.025 nx nx+width*.025], [ny+height*.025 ny+height*.055 ny+height*.025], 'k-', 'LineWidth', 1.6, 'Tag', 'MapDecoration');
text(ax, nx, ny+height*.075, 'N', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 8, 'Tag', 'MapDecoration', 'Interpreter', 'none');

if strlength(string(paramsText)) > 0
    text(ax, xl(1)+width*.02, yl(2)-height*.05, char(paramsText), 'FontSize', 8, ...
        'VerticalAlignment', 'top', 'BackgroundColor', [1 1 1], 'Margin', 4, 'Tag', 'MapDecoration', 'Interpreter', 'none');
end
if ~holdState
    hold(ax, 'off');
end
end

function value = niceScale(value)
base = 10 ^ floor(log10(max(value, eps)));
candidates = base .* [1 2 5 10];
[~, idx] = min(abs(candidates - value));
value = candidates(idx);
end
