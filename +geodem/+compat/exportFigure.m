function exportFigure(target, filePath, varargin)
%EXPORTFIGURE Compatibility wrapper for figure export across MATLAB releases.

resolution = 150;
for i = 1:2:numel(varargin)
    if strcmpi(char(varargin{i}), 'Resolution') && i < numel(varargin)
        resolution = double(varargin{i + 1});
    end
end

filePath = char(filePath);
folder = fileparts(filePath);
if ~isempty(folder) && ~exist(folder, 'dir')
    mkdir(folder);
end

[~, ~, ext] = fileparts(filePath);
ext = lower(ext);
fig = ancestor(target, 'figure');
if isempty(fig)
    error('GeoDEM:InvalidGraphicsTarget', 'Cannot export graphics target.');
end

if isScreenCaptureFormat(ext) && (isVisible(fig) || exist('exportgraphics', 'file') ~= 2)
    try
        captureFigureImage(fig, filePath, ext);
        return;
    catch
    end
end

if exist('exportgraphics', 'file') == 2
    exportgraphics(target, filePath, varargin{:});
    return;
end

device = deviceForExtension(ext);
print(fig, filePath, device, sprintf('-r%d', round(resolution)));
end

function tf = isVisible(fig)
tf = false;
try
    tf = strcmpi(char(fig.Visible), 'on');
catch
end
end

function captureFigureImage(fig, filePath, ext)
oldVisible = "";
try
    oldVisible = string(fig.Visible);
catch
end
cleanup = onCleanup(@() restoreVisible(fig, oldVisible));
try
    fig.Visible = 'on';
catch
end
try
    figure(fig);
catch
end
drawnow;
pause(0.45);
pos = getpixelposition(fig, true);
screen = java.awt.Toolkit.getDefaultToolkit().getScreenSize();
left = max(0, round(pos(1)));
top = max(0, round(screen.height - pos(2) - pos(4)));
width = max(1, min(round(pos(3)), screen.width - left));
height = max(1, min(round(pos(4)), screen.height - top));
rect = java.awt.Rectangle(left, top, width, height);
robot = java.awt.Robot();
image = robot.createScreenCapture(rect);
javax.imageio.ImageIO.write(image, char(imageIoFormat(ext)), java.io.File(filePath));
end

function restoreVisible(fig, oldVisible)
try
    if strlength(oldVisible) > 0 && isvalid(fig)
        fig.Visible = char(oldVisible);
    end
catch
end
end

function tf = isScreenCaptureFormat(ext)
tf = any(strcmp(ext, {'.png', '.jpg', '.jpeg', '.bmp'}));
end

function fmt = imageIoFormat(ext)
switch ext
    case '.png'
        fmt = "png";
    case {'.jpg', '.jpeg'}
        fmt = "jpg";
    case '.bmp'
        fmt = "bmp";
    otherwise
        fmt = "png";
end
end

function device = deviceForExtension(ext)
switch ext
    case '.png'
        device = '-dpng';
    case {'.jpg', '.jpeg'}
        device = '-djpeg';
    case {'.tif', '.tiff'}
        device = '-dtiff';
    case '.pdf'
        device = '-dpdf';
    case '.eps'
        device = '-depsc';
    otherwise
        device = '-dpng';
end
end
