classdef MainView < handle
    %MAINVIEW ArcGIS Pro-style UIFigure workspace for GeoDEM Pro.

    properties
        Controller
        ProjectRoot
        Icons

        UIFigure
        TitleLabel
        ActiveToolLabel
        RibbonTabGroup
        LayerTree
        LayerTreeView
        MainLayout
        DragPane = ""
        LastDragPoint = []
        CustomTabCounter = 0
        MainTabGroup
        MapTab
        SceneTab
        CompareTab
        ChartTab
        MapAxes
        SceneAxes
        CompareAxes
        HistogramAxes
        ClassBarAxes
        LogTextArea
        ProgressTable
        StatusLabel
        ResultsTextArea
        GeoprocessingPanel
        ToolParameterHost
        CurrentToolSpec
        HistoryTable
        BottomStatusLabel
        BottomProgressPanel
        BottomProgressGrid
        BottomProgressFill
        BottomProgressText
        ActionPopup
        MaxMapDisplayPoints = 60000
        MaxSceneDisplayPoints = 40000
        MaxSurfaceDisplayCells = 120000
        MaxChartSamples = 200000
    end

    methods
        function obj = MainView(controller)
            obj.Controller = controller;
            obj.ProjectRoot = controller.ProjectRoot;
            geodem.view.IconFactory.ensureIcons(obj.ProjectRoot);
            obj.Icons = geodem.view.IconFactory.iconMap(obj.ProjectRoot, 32);
            obj.createUi();
            obj.ActionPopup = geodem.view.ActionPopupMenu(obj);
        end

        function createUi(obj)
            obj.UIFigure = uifigure('Name', 'GeoDEM Pro - 专业点云 GIS 平台', ...
                'Position', [40 40 1580 940], 'Color', [0.945 0.955 0.965]);

            root = uigridlayout(obj.UIFigure, [5 1]);
            root.RowHeight = {38, 138, '1x', 132, 24};
            root.Padding = [0 0 0 0];
            root.RowSpacing = 0;

            obj.createTitleBar(root);
            obj.createArcRibbon(root);

            middle = uigridlayout(root, [1 5]);
            middle.ColumnWidth = {300, 6, '1x', 6, 500};
            middle.Padding = [8 8 8 6];
            middle.ColumnSpacing = 4;
            obj.MainLayout = middle;

            leftHost = uipanel(middle, 'BorderType', 'none');
            leftHost.Layout.Column = 1;
            leftGrid = uigridlayout(leftHost, [1 1]);
            leftGrid.Padding = [0 0 0 0];
            obj.createContentsPane(leftGrid);

            leftSplitter = uipanel(middle, 'BorderType', 'none', 'BackgroundColor', [0.72 0.78 0.86]);
            leftSplitter.Layout.Column = 2;
            geodem.compat.setUiProperty(leftSplitter, 'Tooltip', '拖动调整图层面板宽度');
            geodem.compat.setUiCallback(leftSplitter, 'ButtonDownFcn', @(~, ~) obj.startSplitterDrag("left"));

            centerHost = uipanel(middle, 'BorderType', 'none');
            centerHost.Layout.Column = 3;
            centerGrid = uigridlayout(centerHost, [1 1]);
            centerGrid.Padding = [0 0 0 0];
            obj.createMainViews(centerGrid);

            rightSplitter = uipanel(middle, 'BorderType', 'none', 'BackgroundColor', [0.72 0.78 0.86]);
            rightSplitter.Layout.Column = 4;
            geodem.compat.setUiProperty(rightSplitter, 'Tooltip', '拖动调整参数面板宽度');
            geodem.compat.setUiCallback(rightSplitter, 'ButtonDownFcn', @(~, ~) obj.startSplitterDrag("right"));

            rightHost = uipanel(middle, 'BorderType', 'none');
            rightHost.Layout.Column = 5;
            rightGrid = uigridlayout(rightHost, [1 1]);
            rightGrid.Padding = [0 0 0 0];
            obj.createGeoprocessingPane(rightGrid);

            obj.createLogPanel(root);
            obj.createBottomStatusBar(root);
            obj.UIFigure.WindowButtonDownFcn = @(~, ~) obj.onWindowMouseDown();
        end

        function createTitleBar(obj, parent)
            host = uipanel(parent, 'BorderType', 'none', 'BackgroundColor', [0.10 0.22 0.36]);
            bar = uigridlayout(host, [1 7]);
            bar.ColumnWidth = {38, 38, 38, 38, '1x', 240, 110};
            bar.Padding = [8 4 8 4];
            bar.ColumnSpacing = 4;
            geodem.compat.setUiProperty(bar, 'BackgroundColor', [0.10 0.22 0.36]);

            obj.iconButton(bar, '', 'project', '新建工程', @() obj.Controller.newProject(), 'small');
            obj.iconButton(bar, '', 'open', '打开工程', @() obj.Controller.openProject(), 'small');
            obj.iconButton(bar, '', 'save', '保存工程', @() obj.Controller.saveProject(), 'small');
            obj.iconButton(bar, '', 'toolbox', '更多操作', @() obj.openQuickActions(), 'small');
            obj.TitleLabel = uilabel(bar, 'Text', 'MATLAB GeoDEM Pro    多期点云 DEM 构建与地形形变分析系统', ...
                'FontColor', [1 1 1], 'FontSize', 15);
            geodem.compat.setUiProperty(obj.TitleLabel, 'FontWeight', 'bold');
            obj.TitleLabel.Layout.Column = 5;
            obj.ActiveToolLabel = uilabel(bar, 'Text', '地图工具：识别', 'FontColor', [0.82 0.90 1], 'HorizontalAlignment', 'right');
            obj.ActiveToolLabel.Layout.Column = 6;
            obj.StatusLabel = uilabel(bar, 'Text', '就绪', 'FontColor', [1 1 1], 'HorizontalAlignment', 'center');
            geodem.compat.setUiProperty(obj.StatusLabel, 'FontWeight', 'bold');
            obj.StatusLabel.Layout.Column = 7;
        end

        function createArcRibbon(obj, parent)
            geodem.view.RibbonBuilder.create(obj, parent);
        end

        function createContentsPane(obj, parent)
            geodem.view.ContentsPaneBuilder.create(obj, parent);
            obj.LayerTreeView = geodem.view.LayerTreeView(obj, obj.LayerTree);
        end

        function createMainViews(obj, parent)
            geodem.view.WorkspaceViewBuilder.create(obj, parent);
        end

        function addCustomViewTab(obj, kind)
            geodem.view.WorkspaceViewBuilder.addCustomViewTab(obj, kind);
        end

        function renameCurrentViewTab(obj)
            geodem.view.WorkspaceViewBuilder.renameCurrentViewTab(obj);
        end

        function closeCurrentViewTab(obj)
            geodem.view.WorkspaceViewBuilder.closeCurrentViewTab(obj);
        end

        function onViewTabChanged(obj)
            geodem.view.WorkspaceViewBuilder.onViewTabChanged(obj);
        end

        function viewId = currentViewId(obj)
            viewId = geodem.view.WorkspaceViewBuilder.currentViewId(obj);
        end

        function kind = currentViewKind(obj)
            kind = geodem.view.WorkspaceViewBuilder.currentViewKind(obj);
        end

        function createMapTab(obj)
            geodem.view.WorkspaceViewBuilder.createMapTab(obj);
        end

        function createSceneTab(obj)
            geodem.view.WorkspaceViewBuilder.createSceneTab(obj);
        end

        function createCompareTab(obj)
            geodem.view.WorkspaceViewBuilder.createCompareTab(obj);
        end

        function createChartTab(obj)
            geodem.view.WorkspaceViewBuilder.createChartTab(obj);
        end

        function createGeoprocessingPane(obj, parent)
            outer = uigridlayout(parent, [2 1]);
            outer.RowHeight = {'1x', 150};
            outer.RowSpacing = 8;
            outer.Padding = [0 0 0 0];

            obj.GeoprocessingPanel = uipanel(outer, 'Title', '地理处理');
            geodem.compat.setUiProperty(obj.GeoprocessingPanel, 'FontWeight', 'bold');
            geodem.compat.setUiProperty(obj.GeoprocessingPanel, 'BackgroundColor', [0.985 0.99 0.995]);
            hostLayout = uigridlayout(obj.GeoprocessingPanel, [1 1]);
            hostLayout.Padding = [0 0 0 0];
            obj.ToolParameterHost = uipanel(hostLayout, 'BorderType', 'none', 'BackgroundColor', [0.985 0.99 0.995]);
            try
                geodem.compat.setUiProperty(obj.ToolParameterHost, 'Scrollable', 'on');
            catch
            end
            blank = uigridlayout(obj.ToolParameterHost, [2 1]);
            blank.Padding = [10 10 10 10];
            blankTitle = uilabel(blank, 'Text', '请选择 Ribbon 工具', 'FontSize', 15, 'FontColor', [0.10 0.22 0.36]);
            geodem.compat.setUiProperty(blankTitle, 'FontWeight', 'bold');
            uitextarea(blank, 'Editable', 'off', 'Value', {'点击上方 Ribbon 中的工具后，这里会显示该工具自己的输入、参数和输出设置。'}, 'BackgroundColor', [0.985 0.99 0.995]);

            resultPanel = uipanel(outer, 'Title', '工具结果');
            geodem.compat.setUiProperty(resultPanel, 'FontWeight', 'bold');
            geodem.compat.setUiProperty(resultPanel, 'BackgroundColor', [0.985 0.99 0.995]);
            resGrid = uigridlayout(resultPanel, [1 1]);
            resGrid.Padding = [6 6 6 6];
            obj.ResultsTextArea = uitextarea(resGrid, 'Editable', 'off', 'Value', {'统计结果将在这里显示。'});
        end

        function createLogPanel(obj, parent)
            bottom = uigridlayout(parent, [1 3]);
            bottom.ColumnWidth = {'1.35x', 310, '1x'};
            bottom.Padding = [8 2 8 8];
            bottom.ColumnSpacing = 8;

            historyPanel = uipanel(bottom, 'Title', '作业历史');
            geodem.compat.setUiProperty(historyPanel, 'FontWeight', 'bold');
            geodem.compat.setUiProperty(historyPanel, 'BackgroundColor', [0.985 0.99 0.995]);
            historyLayout = uigridlayout(historyPanel, [1 1]);
            historyLayout.Padding = [6 4 6 6];
            obj.HistoryTable = uitable(historyLayout, 'Data', {}, ...
                'ColumnName', {'工具','状态','输出','耗时/s'}, 'RowName', {});

            progressPanel = uipanel(bottom, 'Title', '进度');
            geodem.compat.setUiProperty(progressPanel, 'FontWeight', 'bold');
            geodem.compat.setUiProperty(progressPanel, 'BackgroundColor', [0.985 0.99 0.995]);
            progressLayout = uigridlayout(progressPanel, [1 1]);
            progressLayout.Padding = [6 4 6 6];
            obj.ProgressTable = uitable(progressLayout, 'Data', obj.defaultProgressData(), ...
                'ColumnName', {'任务','状态','耗时'}, 'RowName', {});

            messagePanel = uipanel(bottom, 'Title', '消息');
            geodem.compat.setUiProperty(messagePanel, 'FontWeight', 'bold');
            geodem.compat.setUiProperty(messagePanel, 'BackgroundColor', [0.985 0.99 0.995]);
            messageLayout = uigridlayout(messagePanel, [1 1]);
            messageLayout.Padding = [6 4 6 6];
            obj.LogTextArea = uitextarea(messageLayout, 'Editable', 'off', 'Value', {'暂无消息'});
        end

        function createBottomStatusBar(obj, parent)
            geodem.view.StatusBarPresenter.create(obj, parent);
        end

        function startSplitterDrag(obj, paneName)
            obj.DragPane = string(paneName);
            obj.LastDragPoint = obj.UIFigure.CurrentPoint;
            geodem.compat.setUiProperty(obj.UIFigure, 'Pointer', 'left');
            obj.UIFigure.WindowButtonMotionFcn = @(~, ~) obj.dragSplitter();
            obj.UIFigure.WindowButtonUpFcn = @(~, ~) obj.stopSplitterDrag();
        end

        function dragSplitter(obj)
            if strlength(obj.DragPane) == 0 || isempty(obj.LastDragPoint)
                return;
            end
            cp = obj.UIFigure.CurrentPoint;
            dx = cp(1) - obj.LastDragPoint(1);
            widths = obj.MainLayout.ColumnWidth;
            if obj.DragPane == "left"
                widths{1} = max(180, min(520, widths{1} + dx));
            else
                widths{5} = max(340, min(780, widths{5} - dx));
            end
            obj.MainLayout.ColumnWidth = widths;
            obj.LastDragPoint = cp;
        end

        function stopSplitterDrag(obj)
            obj.DragPane = "";
            obj.LastDragPoint = [];
            geodem.compat.setUiProperty(obj.UIFigure, 'Pointer', 'arrow');
            obj.UIFigure.WindowButtonMotionFcn = [];
            obj.UIFigure.WindowButtonUpFcn = [];
        end

        function data = defaultProgressData(~)
            data = {
                '数据加载', '等待', '--'
                '点云预处理', '等待', '--'
                'DEM构建', '等待', '--'
                '差值计算', '等待', '--'
                '专题图生成', '等待', '--'
                };
        end

        function name = localizedMapToolName(~, toolName)
            switch string(toolName)
                case "identify"
                    name = "识别";
                case "measure"
                    name = "测距";
                case "profile"
                    name = "剖面";
                case "pan"
                    name = "平移";
                otherwise
                    name = string(toolName);
            end
        end

        function btn = iconButton(obj, parent, text, iconName, tooltip, callback, sizeMode)
            if nargin < 7
                sizeMode = 'normal';
            end
            iconSize = 32;
            if strcmp(sizeMode, 'small')
                iconSize = 24;
            end
            btn = uibutton(parent, 'Text', text, 'ButtonPushedFcn', @(~, ~) callback());
            geodem.compat.setUiProperty(btn, 'Icon', obj.iconPath(iconName, iconSize));
            geodem.compat.setUiProperty(btn, 'Tooltip', tooltip);
            geodem.compat.setUiProperty(btn, 'IconAlignment', 'top');
        end

        function label = addParam(~, parent, text)
            label = uilabel(parent, 'Text', text, 'FontColor', [0.25 0.33 0.42]);
        end

        function path = iconPath(obj, iconName, sizePx)
            path = geodem.view.IconFactory.getIcon(obj.ProjectRoot, iconName, sizePx);
        end

        function showTool(obj, toolSpec, defaults, project)
            obj.CurrentToolSpec = toolSpec;
            if ~isempty(obj.GeoprocessingPanel) && isvalid(obj.GeoprocessingPanel)
                obj.GeoprocessingPanel.Title = "地理处理 - " + string(toolSpec.Name);
            end
            geodem.view.ParameterPanelBuilder.render(obj.ToolParameterHost, toolSpec, defaults, project, ...
                @() obj.Controller.runSelectedTool(), @() obj.Controller.resetSelectedToolDefaults());
            obj.ActiveToolLabel.Text = "工具：" + string(toolSpec.Name);
            obj.setStats([
                string(toolSpec.Name)
                string(toolSpec.Description)
                "输入和输出参数已在地理处理面板中独立配置。"
                ]);
        end

        function params = readToolParameters(obj)
            params = geodem.view.ParameterPanelBuilder.read(obj.ToolParameterHost);
        end

        function setLayers(obj, layers)
            obj.LayerTreeView.setLayers(layers);
        end

        function onLayerTreeHtmlEvent(obj, src)
            obj.LayerTreeView.onHtmlEvent(src);
        end

        function restoreLayerTreeData(obj)
            obj.LayerTreeView.restoreData();
        end

        function anchorPoint = layerTreeMenuAnchor(obj, data)
            anchorPoint = obj.LayerTreeView.menuAnchor(data);
        end

        function layerName = contextLayerName(obj)
            layerName = obj.LayerTreeView.contextLayerName();
        end

        function setLog(obj, messages)
            if isempty(messages)
                obj.LogTextArea.Value = {'暂无消息'};
            else
                displayMessages = obj.compactMessages(messages, 10);
                obj.LogTextArea.Value = cellstr(displayMessages);
            end
        end

        function displayMessages = compactMessages(~, messages, maxCount)
            if nargin < 3
                maxCount = 10;
            end
            messages = string(messages(:));
            messages = messages(strlength(strtrim(messages)) > 0);
            if isempty(messages)
                displayMessages = "暂无消息";
                return;
            end
            compact = strings(0, 1);
            lastBody = "";
            for i = 1:numel(messages)
                body = regexprep(messages(i), '^\[\d{2}:\d{2}:\d{2}\]\s*', '');
                body = regexprep(body, '\s+', ' ');
                body = strtrim(body);
                if strlength(body) == 0 || body == lastBody
                    continue;
                end
                lastBody = body;
                compact(end + 1, 1) = messages(i); %#ok<AGROW>
            end
            if isempty(compact)
                displayMessages = "暂无消息";
                return;
            end
            displayMessages = compact(max(1, end - maxCount + 1):end);
        end

        function updateToolHistory(obj, project)
            if isempty(obj.HistoryTable) || ~isvalid(obj.HistoryTable)
                return;
            end
            if isempty(project.toolHistory)
                obj.HistoryTable.Data = {};
                return;
            end
            n = numel(project.toolHistory);
            data = cell(n, 4);
            for i = 1:n
                rec = project.toolHistory(i);
                data{i, 1} = char(rec.ToolName);
                data{i, 2} = char(rec.Status);
                data{i, 3} = char(strjoin(rec.OutputLayers, ", "));
                data{i, 4} = sprintf('%.2f', rec.DurationSeconds);
            end
            obj.HistoryTable.Data = data;
        end

        function setStats(obj, lines)
            if isstring(lines)
                obj.ResultsTextArea.Value = cellstr(lines);
            elseif iscell(lines)
                obj.ResultsTextArea.Value = lines;
            else
                obj.ResultsTextArea.Value = cellstr(string(lines));
            end
        end

        function updateStatsFromProject(obj, project)
            result = project.activeDeformation();
            if isempty(result)
                obj.setStats("尚未生成形变统计。");
                if ~isempty(obj.ProgressTable) && isvalid(obj.ProgressTable)
                    obj.ProgressTable.Data = obj.defaultProgressData();
                end
                return;
            end
            s = result.stats;
            v = result.volumeStats;
            p = result.maxSubsidencePoint;
            obj.setStats([
                "最大沉降：" + sprintf('%.3f m', s.MaxSubsidence)
                "最大抬升：" + sprintf('%.3f m', s.MaxUplift)
                "平均变形：" + sprintf('%.3f m', s.MeanChange)
                "沉降面积：" + sprintf('%.2f m²', s.SubsidenceArea)
                "抬升面积：" + sprintf('%.2f m²', s.UpliftArea)
                "稳定区域比例：" + sprintf('%.2f%%', 100 * s.StableRatio)
                "沉降体积：" + sprintf('%.2f m³', v.SubsidenceVolume)
                "净体积变化：" + sprintf('%.2f m³', v.NetVolumeChange)
                "最大沉降点：" + sprintf('X=%.3f, Y=%.3f', p.X, p.Y)
                ]);
            if obj.currentViewKind() == "charts"
                obj.renderCharts(project);
            end
            if ~isempty(obj.ProgressTable) && isvalid(obj.ProgressTable)
                obj.ProgressTable.Data = {
                    '数据加载', '完成', 'OK'
                    '点云预处理', '完成', 'OK'
                    'DEM构建', '完成', sprintf('%dx%d', size(result.deltaZ, 2), size(result.deltaZ, 1))
                    '差值计算', '完成', sprintf('%.3f m', s.MaxSubsidence)
                    '专题图生成', '完成', 'OK'
                    };
            end
        end

        function renderProject(obj, project)
            geodem.view.LayerRenderer.renderProject(obj, project);
        end

        function renderLayer(obj, project, layerName)
            geodem.view.LayerRenderer.renderLayer(obj, project, layerName);
        end

        function [ax, kind] = activeRenderAxes(obj)
            [ax, kind] = geodem.view.LayerRenderer.activeRenderAxes(obj);
        end

        function captureCurrentViewState(obj, project)
            viewId = obj.currentViewId();
            state = project.getViewState(viewId);
            state.Kind = obj.currentViewKind();
            [ax, kind] = obj.activeRenderAxes();
            if ~isempty(ax) && isvalid(ax) && any(kind == ["map","scene"])
                try
                    state.XLim = ax.XLim;
                    state.YLim = ax.YLim;
                    state.ZLim = ax.ZLim;
                    state.CameraView = view(ax);
                catch
                end
            end
            state = state.touch();
            project.setViewState(viewId, state);
        end

        function renderScene(obj, project, mode)
            if nargin < 3
                mode = 'auto';
            end
            geodem.view.LayerRenderer.renderScene(obj, project, mode);
        end

        function renderCompare(obj, project)
            geodem.view.LayerRenderer.renderCompare(obj, project);
        end

        function renderCharts(obj, project)
            geodem.view.LayerRenderer.renderCharts(obj, project);
        end

        function renderProfile(obj, profile)
            geodem.view.LayerRenderer.renderProfile(obj, profile);
        end

        function showTable(~, tbl, titleText)
            fig = uifigure('Name', titleText, 'Position', [180 180 980 430]);
            uitable(fig, 'Data', tbl, 'Position', [10 10 960 410]);
        end

        function openQuickActions(obj)
            if isempty(obj.ActionPopup) || ~isvalid(obj.ActionPopup)
                return;
            end
            obj.ActionPopup.showViewMenu(obj.UIFigure.CurrentPoint);
        end

        function openLayerActions(obj, layerName)
            if isempty(obj.ActionPopup) || ~isvalid(obj.ActionPopup)
                return;
            end
            obj.ActionPopup.showLayerMenu(layerName, obj.UIFigure.CurrentPoint);
        end

        function onWindowMouseDown(obj)
            if isempty(obj.ActionPopup) || ~isvalid(obj.ActionPopup)
                return;
            end
            currentObj = [];
            try
                currentObj = obj.UIFigure.CurrentObject;
            catch
            end
            if strcmpi(char(obj.UIFigure.SelectionType), 'alt')
                if isa(currentObj, 'matlab.ui.container.TabGroup') || isa(currentObj, 'matlab.ui.container.Tab') || ...
                        isa(currentObj, 'matlab.ui.control.UIAxes')
                    obj.ActionPopup.showViewMenu(obj.UIFigure.CurrentPoint);
                else
                    obj.openQuickActions();
                end
                return;
            end
            if obj.ActionPopup.isVisible() && obj.ActionPopup.handleClick(obj.UIFigure.CurrentPoint)
                return;
            end
            if obj.ActionPopup.isVisible() && ~obj.ActionPopup.containsHandle(currentObj)
                obj.ActionPopup.hide();
            end
        end

        function selectViewMode(obj, mode)
            switch mode
                case 'scene'
                    obj.MainTabGroup.SelectedTab = obj.SceneTab;
                case 'compare'
                    obj.MainTabGroup.SelectedTab = obj.CompareTab;
                case 'charts'
                    obj.MainTabGroup.SelectedTab = obj.ChartTab;
                otherwise
                    obj.MainTabGroup.SelectedTab = obj.MapTab;
            end
        end

        function set3DView(obj, mode)
            obj.selectViewMode('scene');
            switch mode
                case 'top'
                    view(obj.SceneAxes, 2);
                otherwise
                    view(obj.SceneAxes, 45, 35);
            end
        end

        function setActiveMapTool(obj, toolName)
            obj.ActiveToolLabel.Text = "地图工具：" + obj.localizedMapToolName(toolName);
            switch string(toolName)
                case "identify"
                    obj.setStats(["识别工具"; "输入：当前地图点击位置"; "输出：X/Y、DEM A、DEM B、ΔZ、等级"]);
                case "measure"
                    obj.setStats(["测距工具"; "输入：连续点击地图点"; "输出：分段距离与总距离"; "再次选择其他工具可结束测距"]);
                case "profile"
                    obj.setStats(["剖面工具"; "输入：点击起点和终点"; "参数：剖面采样点数"; "输出：DEM A、DEM B 和 ΔZ 剖面"]);
                case "pan"
                    obj.setStats(["平移工具"; "使用坐标轴工具栏或鼠标拖动浏览当前视图"]);
            end
            switch string(toolName)
                case "measure"
                    obj.MapAxes.Toolbar.Visible = 'off';
                otherwise
                    obj.MapAxes.Toolbar.Visible = 'on';
            end
        end

        function setBusy(obj, isBusy)
            geodem.view.StatusBarPresenter.setBusy(obj, isBusy);
        end

        function updateProgress(obj, fraction, message)
            if nargin < 3
                message = "";
            end
            geodem.view.StatusBarPresenter.updateProgress(obj, fraction, message);
        end

        function hideProgressDelayed(obj)
            geodem.view.StatusBarPresenter.hideProgressDelayed(obj);
        end

        function updateStatusBar(obj, project, coordinate, stateText)
            if nargin < 2
                project = [];
            end
            if nargin < 3
                coordinate = [];
            end
            if nargin < 4
                stateText = "";
            end
            geodem.view.StatusBarPresenter.update(obj, project, coordinate, stateText);
        end

        function zoomToLayer(obj, project, layerName)
            if strlength(string(layerName)) == 0
                return;
            end
            bounds = geodem.view.LayerRenderer.layerBounds(project, layerName);
            if isempty(bounds)
                return;
            end
            xlim(obj.MapAxes, [bounds.XMin bounds.XMax]);
            ylim(obj.MapAxes, [bounds.YMin bounds.YMax]);
            obj.updateStatusBar(project, [], "就绪");
        end

        function showIdentifyMarker(obj, x, y)
            holdState = ishold(obj.MapAxes);
            hold(obj.MapAxes, 'on');
            delete(findobj(obj.MapAxes, 'Tag', 'IdentifyMarker'));
            plot(obj.MapAxes, x, y, 'kp', 'MarkerFaceColor', [1 0.85 0], 'MarkerSize', 13, 'Tag', 'IdentifyMarker', 'HitTest', 'off');
            if ~holdState, hold(obj.MapAxes, 'off'); end
        end

        function drawMeasurement(obj, points, totalDistance)
            holdState = ishold(obj.MapAxes);
            hold(obj.MapAxes, 'on');
            delete(findobj(obj.MapAxes, 'Tag', 'MeasurementGraphic'));
            plot(obj.MapAxes, points(:,1), points(:,2), 'm-o', 'LineWidth', 1.8, 'MarkerFaceColor', 'm', 'Tag', 'MeasurementGraphic', 'HitTest', 'off');
            text(obj.MapAxes, points(end,1), points(end,2), sprintf(' %.2f m', totalDistance), ...
                'Color', 'm', 'FontWeight', 'bold', 'BackgroundColor', 'w', 'Tag', 'MeasurementGraphic', 'HitTest', 'off');
            if ~holdState, hold(obj.MapAxes, 'off'); end
        end

        function onMapAxesClick(obj)
            cp = obj.MapAxes.CurrentPoint;
            obj.Controller.handleMapClick(cp(1, 1), cp(1, 2));
        end

    end
end
