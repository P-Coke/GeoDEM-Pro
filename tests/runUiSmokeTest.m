function results = runUiSmokeTest()
%RUNUISMOKETEST Launch the app, capture a screenshot, and exercise UI buttons.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'tests', 'ui_stubs'), '-begin');
configureSourceEncoding();

projectFile = fullfile(root, 'output', 'test_run', 'GeoDEMPro_project.mat');
if ~isfile(projectFile)
    runAllTests();
end
assert(isfile(projectFile), 'Required project file is missing: %s', projectFile);

app = runGeoDEMPro();
cleanup = onCleanup(@() closeApp(app));

app.Project = geodem.service.io.loadProject(projectFile);
app.updateView();
if strlength(string(app.Project.activeLayer)) > 0
    app.renderLayer(app.Project.activeLayer);
end
maximizeFigure(app.View.UIFigure);
drawnow;
pause(1.8);

uiDir = fullfile(root, 'output', 'test_run', 'ui');
if ~exist(uiDir, 'dir')
    mkdir(uiDir);
end
screenFile = fullfile(uiDir, 'GeoDEMPro_main.png');
geodem.compat.exportFigure(app.View.UIFigure, screenFile, 'Resolution', 140);

buttons = findall(app.View.UIFigure, 'Type', 'uibutton');
descriptors = struct('Handle', num2cell(double(buttons)), 'Text', cell(size(buttons)), 'Tooltip', cell(size(buttons)), 'Icon', cell(size(buttons)));
for i = 1:numel(buttons)
    btn = buttons(i);
    descriptors(i).Text = char(stringSafe(btn, 'Text'));
    descriptors(i).Tooltip = char(stringSafe(btn, 'Tooltip'));
    descriptors(i).Icon = char(stringSafe(btn, 'Icon'));
end

buttonAudit = auditButtons(app, descriptors);
safeDescriptors = safeClickDescriptors(descriptors);
fprintf('Safe UI buttons selected: %d\n', numel(safeDescriptors));
clickLog = cell(0, 4);
for i = 1:numel(safeDescriptors)
    btn = findButtonByDescriptor(app, safeDescriptors(i));
    if isempty(btn)
        continue;
    end
    clickLog(end + 1, :) = clickButton(app, btn, buttonKey(btn)); %#ok<AGROW>
    fprintf('Clicked UI button: %s -> %s\n', clickLog{end, 1}, clickLog{end, 2});
    closeChildFigures(app);
end

restoreProject(app);
drawnow;
app.View.openQuickActions();
drawnow;
pause(1.2);
menuFile = fullfile(uiDir, 'GeoDEMPro_quick_menu.png');
geodem.compat.exportFigure(app.View.UIFigure, menuFile, 'Resolution', 140);

results = struct();
results.Root = root;
results.ProjectFile = projectFile;
results.Screenshot = screenFile;
results.MenuScreenshot = menuFile;
results.ButtonCount = numel(buttons);
results.ButtonAudit = buttonAudit;
results.AuditSummary = auditSummary(buttonAudit);
results.ClickLog = clickLog;
results.ClickStatusSummary = statusSummary(clickLog);
assert(results.AuditSummary.missingCallback == 0, 'One or more enabled UI buttons are missing callbacks.');
assert(results.ClickStatusSummary.ok > 0, 'No safe UI buttons were exercised during smoke testing.');
assert(results.ClickStatusSummary.error == 0, 'One or more UI buttons raised errors during smoke testing.');
disp(results);
fprintf('UI smoke test finished. Screenshot: %s\n', screenFile);
end

function row = clickButton(app, btn, key)
row = {key, 'skip', '', ''};
try
    if isprop(btn, 'Enable') && strcmpi(char(btn.Enable), 'off')
        row{2} = 'disabled';
        return;
    end
    if isempty(btn.ButtonPushedFcn)
        row{2} = 'no-callback';
        return;
    end
    feval(btn.ButtonPushedFcn, btn, []);
    row{2} = 'ok';
    app.updateView();
    if isprop(app.Project, 'layers') && isempty(app.Project.layers)
        restoreProject(app);
    elseif strlength(string(app.Project.activeLayer)) > 0
        app.renderLayer(app.Project.activeLayer);
    end
    drawnow;
    pause(0.15);
catch ME
    row{2} = 'error';
    row{3} = ME.identifier;
    row{4} = ME.message;
    restoreProject(app);
end
end

function audit = auditButtons(app, descriptors)
audit = cell(0, 3);
for i = 1:numel(descriptors)
    btn = findButtonByDescriptor(app, descriptors(i));
    key = descriptorKey(descriptors(i));
    if isempty(btn)
        audit(end + 1, :) = {key, 'missing-handle', ''}; %#ok<AGROW>
        continue;
    end
    try
        if isprop(btn, 'Enable') && strcmpi(char(btn.Enable), 'off')
            audit(end + 1, :) = {key, 'disabled', ''}; %#ok<AGROW>
        elseif isempty(btn.ButtonPushedFcn)
            audit(end + 1, :) = {key, 'missing-callback', ''}; %#ok<AGROW>
        else
            audit(end + 1, :) = {key, 'callback', ''}; %#ok<AGROW>
        end
    catch ME
        audit(end + 1, :) = {key, 'error', ME.message}; %#ok<AGROW>
    end
end
end

function selected = safeClickDescriptors(descriptors)
selected = descriptors([]);
seen = strings(0, 1);
for i = 1:numel(descriptors)
    key = string(descriptorKey(descriptors(i)));
    if any(seen == key) || ~isSafeCoreButton(descriptors(i))
        continue;
    end
    selected(end + 1) = descriptors(i); %#ok<AGROW>
    seen(end + 1, 1) = key; %#ok<AGROW>
    if numel(selected) >= 6
        break;
    end
end
end

function tf = isSafeCoreButton(descriptor)
label = string(descriptor.Text) + " " + string(descriptor.Tooltip);
icon = lower(string(descriptor.Icon));
iconNeedles = ["toolbox", "spark", "export", "report", "clip"];
tf = any(strlength(icon) > 0);
if tf
    tf = false;
    for i = 1:numel(iconNeedles)
        if contains(icon, iconNeedles(i))
            tf = true;
            break;
        end
    end
end
if ~tf
    textNeedles = [
        string(native2unicode(uint8([230 155 180 229 164 154 230 147 141 228 189 156]), 'UTF-8'))
        string(native2unicode(uint8([233 128 137 230 139 169 228 184 128 233 148 174 229 183 165 228 189 156 230 181 129 229 183 165 229 133 183]), 'UTF-8'))
        ];
    for i = 1:numel(textNeedles)
        if contains(label, textNeedles(i))
            tf = true;
            break;
        end
    end
end
tf = tf && ~contains(icon, "clean") && ~contains(icon, "delete");
if tf
    blockedText = [
        string(native2unicode(uint8([232 191 144 232 161 140 229 183 165 229 133 183]), 'UTF-8'))
        string(native2unicode(uint8([230 184 133 231 169 186]), 'UTF-8'))
        string(native2unicode(uint8([232 167 134 229 155 190 229 175 188 229 135 186]), 'UTF-8'))
        string(native2unicode(uint8([229 175 188 229 135 186 229 133 168 233 131 168 230 136 144 230 158 156 229 155 190 228 187 182]), 'UTF-8'))
        ];
    for i = 1:numel(blockedText)
        if contains(label, blockedText(i))
            tf = false;
            break;
        end
    end
end
end

function btn = findButton(app, label)
buttons = findall(app.View.UIFigure, 'Type', 'uibutton');
btn = [];
for i = 1:numel(buttons)
    btn = buttons(i);
    if isvalid(btn) && strcmp(string(btn.Text), string(label))
        return;
    end
end
btn = [];
end

function btn = findButtonByDescriptor(app, descriptor)
btn = [];
buttons = findall(app.View.UIFigure, 'Type', 'uibutton');
for i = 1:numel(buttons)
    candidate = buttons(i);
    if ~isvalid(candidate)
        continue;
    end
    if strcmp(char(stringSafe(candidate, 'Text')), descriptor.Text) && strcmp(char(stringSafe(candidate, 'Tooltip')), descriptor.Tooltip)
        btn = candidate;
        return;
    end
end
end

function key = buttonKey(btn)
text = "";
tooltip = "";
try
    text = string(btn.Text);
catch
end
try
    tooltip = string(btn.Tooltip);
catch
end
key = char(text + "|" + tooltip);
end

function key = descriptorKey(descriptor)
key = char(string(descriptor.Text) + "|" + string(descriptor.Tooltip) + "|" + string(descriptor.Icon));
end

function value = stringSafe(obj, propertyName)
value = "";
try
    value = string(obj.(propertyName));
catch
end
end

function summary = statusSummary(clickLog)
if isempty(clickLog)
    summary = struct('ok', 0, 'disabled', 0, 'noCallback', 0, 'skip', 0, 'error', 0);
    return;
end
statuses = string(clickLog(:, 2));
summary = struct( ...
    'ok', sum(statuses == "ok"), ...
    'disabled', sum(statuses == "disabled"), ...
    'noCallback', sum(statuses == "no-callback"), ...
    'skip', sum(statuses == "skip"), ...
    'error', sum(statuses == "error"));
end

function summary = auditSummary(buttonAudit)
if isempty(buttonAudit)
    summary = struct('callback', 0, 'disabled', 0, 'missingCallback', 0, 'missingHandle', 0, 'error', 0);
    return;
end
statuses = string(buttonAudit(:, 2));
summary = struct( ...
    'callback', sum(statuses == "callback"), ...
    'disabled', sum(statuses == "disabled"), ...
    'missingCallback', sum(statuses == "missing-callback"), ...
    'missingHandle', sum(statuses == "missing-handle"), ...
    'error', sum(statuses == "error"));
end

function closeChildFigures(app)
try
    figs = findall(groot, 'Type', 'figure');
    for i = 1:numel(figs)
        try
            if figs(i) ~= app.View.UIFigure
                close(figs(i));
            end
        catch
        end
    end
catch
end
end

function restoreProject(app)
root = app.ProjectRoot;
projectFile = fullfile(root, 'output', 'test_run', 'GeoDEMPro_project.mat');
if isfile(projectFile)
    app.Project = geodem.service.io.loadProject(projectFile);
    app.updateView();
    if strlength(string(app.Project.activeLayer)) > 0
        app.renderLayer(app.Project.activeLayer);
    end
end
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
