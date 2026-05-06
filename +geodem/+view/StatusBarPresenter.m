classdef StatusBarPresenter
    %STATUSBARPRESENTER Owns the bottom status bar and progress display.

    methods (Static)
        function create(view, parent)
            bar = uigridlayout(parent, [1 2]);
            bar.ColumnWidth = {'1x', 300};
            bar.ColumnSpacing = 10;
            bar.Padding = [10 2 10 2];
            geodem.compat.setUiProperty(bar, 'BackgroundColor', [0.90 0.93 0.96]);

            view.BottomStatusLabel = uilabel(bar, ...
                'Text', '就绪 | 当前工程：-- | 坐标 X=-- Y=-- Z=-- | 比例尺 1:2000', ...
                'FontSize', 11, 'FontColor', [0.18 0.25 0.34], 'HorizontalAlignment', 'left');
            view.BottomStatusLabel.Layout.Column = 1;

            view.BottomProgressPanel = uipanel(bar, 'BorderType', 'line', 'BackgroundColor', [0.80 0.85 0.88]);
            view.BottomProgressPanel.Layout.Column = 2;
            view.BottomProgressGrid = uigridlayout(view.BottomProgressPanel, [1 2]);
            view.BottomProgressGrid.ColumnWidth = {'0.001x', '1x'};
            view.BottomProgressGrid.Padding = [1 1 1 1];
            view.BottomProgressGrid.ColumnSpacing = 0;
            view.BottomProgressFill = uipanel(view.BottomProgressGrid, 'BorderType', 'none', 'BackgroundColor', [0.12 0.68 0.32]);
            view.BottomProgressFill.Layout.Column = 1;
            spacer = uipanel(view.BottomProgressGrid, 'BorderType', 'none', 'BackgroundColor', [0.94 0.97 0.95]);
            spacer.Layout.Column = 2;
            view.BottomProgressText = uilabel(view.BottomProgressPanel, 'Text', '', ...
                'FontSize', 10, 'FontColor', [0.08 0.28 0.14], ...
                'HorizontalAlignment', 'center', 'Position', [1 1 298 18]);
            geodem.compat.setUiProperty(view.BottomProgressText, 'FontWeight', 'bold');
            view.BottomProgressPanel.Visible = 'off';
            if ~isempty(view.Controller) && ~isempty(view.Controller.Project)
                geodem.view.StatusBarPresenter.update(view, view.Controller.Project, [], "就绪");
            end
        end

        function setBusy(view, isBusy)
            if isBusy
                view.StatusLabel.Text = '运行中...';
                geodem.compat.setUiProperty(view.UIFigure, 'Pointer', 'watch');
                geodem.view.StatusBarPresenter.updateProgress(view, 0.08, "准备中...");
                if ~isempty(view.Controller) && ~isempty(view.Controller.Project)
                    geodem.view.StatusBarPresenter.update(view, view.Controller.Project, [], "运行中...");
                end
            else
                view.StatusLabel.Text = '就绪';
                geodem.compat.setUiProperty(view.UIFigure, 'Pointer', 'arrow');
                geodem.view.StatusBarPresenter.updateProgress(view, 1.00, "完成");
                if ~isempty(view.Controller) && ~isempty(view.Controller.Project)
                    geodem.view.StatusBarPresenter.update(view, view.Controller.Project, [], "就绪");
                end
                geodem.view.StatusBarPresenter.hideProgressDelayed(view);
            end
            drawnow limitrate;
        end

        function updateProgress(view, fraction, message)
            if isempty(view.BottomProgressPanel) || ~isvalid(view.BottomProgressPanel)
                return;
            end
            fraction = max(0, min(1, double(fraction)));
            view.BottomProgressPanel.Visible = 'on';
            fillWeight = max(0.001, fraction);
            restWeight = max(0.001, 1 - fraction);
            view.BottomProgressGrid.ColumnWidth = {sprintf('%.4fx', fillWeight), sprintf('%.4fx', restWeight)};
            if nargin < 3 || strlength(string(message)) == 0
                message = sprintf('%.0f%%', 100 * fraction);
            else
                message = string(message) + "  " + sprintf('%.0f%%', 100 * fraction);
            end
            view.BottomProgressText.Text = char(message);
            drawnow;
        end

        function hideProgressDelayed(view)
            if isempty(view.BottomProgressPanel) || ~isvalid(view.BottomProgressPanel)
                return;
            end
            drawnow;
            pause(0.08);
            if isvalid(view.BottomProgressPanel)
                view.BottomProgressPanel.Visible = 'off';
                view.BottomProgressGrid.ColumnWidth = {'0.001x', '1x'};
                view.BottomProgressText.Text = '';
            end
        end

        function update(view, project, coordinate, stateText)
            if isempty(view.BottomStatusLabel) || ~isvalid(view.BottomStatusLabel)
                return;
            end
            if nargin < 2 || isempty(project)
                if isempty(view.Controller) || isempty(view.Controller.Project)
                    project = [];
                else
                    project = view.Controller.Project;
                end
            end
            if nargin < 3
                coordinate = [];
            end
            if nargin < 4 || strlength(string(stateText)) == 0
                if ~isempty(view.StatusLabel) && isvalid(view.StatusLabel)
                    stateText = string(view.StatusLabel.Text);
                else
                    stateText = "就绪";
                end
            end
            projectText = geodem.view.StatusBarPresenter.projectName(project);
            coordText = geodem.view.StatusBarPresenter.coordinateText(project, coordinate);
            scaleText = geodem.view.StatusBarPresenter.scaleText(view);
            view.BottomStatusLabel.Text = char(string(stateText) + " | 当前工程：" + projectText + " | 坐标 " + coordText + " | 比例尺 " + scaleText);
        end

        function name = projectName(project)
            name = "--";
            if isempty(project)
                return;
            end
            try
                if strlength(string(project.projectPath)) > 0
                    [~, base, ext] = fileparts(char(project.projectPath));
                    name = string(base) + string(ext);
                    return;
                end
                if strlength(string(project.name)) > 0
                    name = string(project.name);
                end
            catch
            end
        end

        function text = coordinateText(project, coordinate)
            if nargin < 2 || isempty(coordinate)
                coordinate = [];
                try
                    if ~isempty(project) && ~isempty(project.mapToolState.lastIdentifyResult)
                        coordinate = project.mapToolState.lastIdentifyResult;
                    end
                catch
                end
            end
            if isempty(coordinate)
                text = "X=-- Y=-- Z=--";
                return;
            end
            x = getCoordValue(coordinate, 'X');
            y = getCoordValue(coordinate, 'Y');
            z = getCoordValue(coordinate, 'Z');
            if ~isfinite(z)
                z = getCoordValue(coordinate, 'MonitorDEM');
            end
            if ~isfinite(z)
                z = getCoordValue(coordinate, 'BaseDEM');
            end
            if ~isfinite(z)
                z = getCoordValue(coordinate, 'DeltaZ');
            end
            text = "X=" + formatStatusNumber(x) + " Y=" + formatStatusNumber(y) + " Z=" + formatStatusNumber(z);
        end

        function text = scaleText(view)
            denom = 2000;
            try
                if ~isempty(view.MapAxes) && isvalid(view.MapAxes)
                    width = diff(view.MapAxes.XLim);
                    if isfinite(width) && width > 0
                        denom = geodem.view.StatusBarPresenter.niceScaleDenominator(width / 0.20);
                    end
                end
            catch
            end
            text = "1:" + string(denom);
        end

        function denom = niceScaleDenominator(rawValue)
            rawValue = max(1, double(rawValue));
            base = 10 ^ floor(log10(rawValue));
            candidates = [1 2 5 10] * base;
            [~, idx] = min(abs(candidates - rawValue));
            denom = max(1, round(candidates(idx)));
        end
    end
end

function value = getCoordValue(s, fieldName)
value = NaN;
try
    if isstruct(s) && isfield(s, fieldName)
        value = double(s.(fieldName));
    end
catch
    value = NaN;
end
end

function text = formatStatusNumber(value)
if isfinite(value)
    text = string(sprintf('%.3f', value));
else
    text = "--";
end
end
