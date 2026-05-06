function results = runUiImportTest()
%RUNUIIMPORTTEST Exercise UI refresh after CSV/TXT point-cloud import.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
removePathIfPresent(fullfile(root, 'tests', 'ui_stubs'));
addpath(fullfile(root, 'tests', 'ui_import_stubs'), '-begin');
clear uigetfile;
configureSourceEncoding();

app = runGeoDEMPro();
cleanup = onCleanup(@() closeApp(app));

app.importCloud();
assert(numel(fieldnames(app.Project.clouds)) >= 2, 'Point-cloud import did not add the selected CSV/TXT files.');
assert(strlength(string(app.Project.activeLayer)) > 0, 'Point-cloud import did not activate an imported layer.');
assert(isfield(app.View.LayerTree.Data, 'items') && ~isempty(app.View.LayerTree.Data.items), 'Layer tree was not refreshed after import.');

uiDir = fullfile(root, 'output', 'test_run', 'ui');
if ~exist(uiDir, 'dir')
    mkdir(uiDir);
end
screenFile = fullfile(uiDir, 'GeoDEMPro_import_pointcloud.png');
maximizeFigure(app.View.UIFigure);
drawnow;
pause(1.5);
geodem.compat.exportFigure(app.View.UIFigure, screenFile, 'Resolution', 140);

results = struct();
results.Root = root;
results.Screenshot = screenFile;
results.CloudCount = numel(fieldnames(app.Project.clouds));
results.ActiveLayer = app.Project.activeLayer;
disp(results);
fprintf('UI import test finished. Screenshot: %s\n', screenFile);
end

function configureSourceEncoding()
if exist('slCharacterEncoding', 'file') == 2
    try
        slCharacterEncoding('UTF-8');
    catch
    end
end
end

function closeApp(app)
try
    if ~isempty(app) && isvalid(app) && ~isempty(app.View) && isvalid(app.View.UIFigure)
        close(app.View.UIFigure);
    end
catch
end
end

function removePathIfPresent(folder)
try
    entries = strsplit(path, pathsep);
    if any(strcmp(entries, folder))
        rmpath(folder);
    end
catch
end
end

function maximizeFigure(fig)
try
    if isprop(fig, 'WindowState')
        fig.WindowState = 'maximized';
    else
        fig.Position = [1 1 1920 1080];
    end
catch
    try
        fig.Position = [1 1 1920 1080];
    catch
    end
end
end
