classdef WorkspaceViewBuilder
    %WORKSPACEVIEWBUILDER Builds and manages central map/scene/chart tabs.

    methods (Static)
        function create(view, parent)
            view.MainTabGroup = uitabgroup(parent);
            view.MapTab = uitab(view.MainTabGroup, 'Title', '二维地图');
            view.SceneTab = uitab(view.MainTabGroup, 'Title', '三维场景');
            view.ChartTab = uitab(view.MainTabGroup, 'Title', '统计图表');
            view.CompareTab = uitab(view.MainTabGroup, 'Title', '多图对比');

            geodem.view.WorkspaceViewBuilder.createMapTab(view);
            geodem.view.WorkspaceViewBuilder.createSceneTab(view);
            geodem.view.WorkspaceViewBuilder.createChartTab(view);
            geodem.view.WorkspaceViewBuilder.createCompareTab(view);
            view.MapTab.UserData = struct('Kind', "map", 'ViewId', "map", 'Axes', view.MapAxes, 'Custom', false);
            view.SceneTab.UserData = struct('Kind', "scene", 'ViewId', "scene", 'Axes', view.SceneAxes, 'Custom', false);
            view.ChartTab.UserData = struct('Kind', "charts", 'ViewId', "charts", 'Axes', [], 'Custom', false);
            view.CompareTab.UserData = struct('Kind', "compare", 'ViewId', "compare", 'Axes', [], 'Custom', false);
            view.MainTabGroup.SelectionChangedFcn = @(~, ~) geodem.view.WorkspaceViewBuilder.onViewTabChanged(view);
        end

        function addCustomViewTab(view, kind)
            view.CustomTabCounter = view.CustomTabCounter + 1;
            kind = string(kind);
            if kind == "scene"
                tabTitle = "三维场景 " + string(view.CustomTabCounter);
            else
                kind = "map";
                tabTitle = "二维地图 " + string(view.CustomTabCounter);
            end
            tab = uitab(view.MainTabGroup, 'Title', char(tabTitle));
            grid = uigridlayout(tab, [2 1]);
            grid.RowHeight = {34, '1x'};
            grid.Padding = [4 4 4 4];
            tools = uigridlayout(grid, [1 6]);
            tools.ColumnWidth = {38, 38, 38, 38, 38, '1x'};
            tools.Padding = [2 1 2 1];
            view.iconButton(tools, '', 'identify', '识别', @() view.Controller.setActiveMapTool('identify'), 'small');
            view.iconButton(tools, '', 'pan', '平移', @() view.Controller.setActiveMapTool('pan'), 'small');
            view.iconButton(tools, '', 'fullExtent', '缩放至图层', @() view.Controller.zoomToLayer(), 'small');
            view.iconButton(tools, '', 'attribute', '属性表', @() view.Controller.openAttributeTable(), 'small');
            view.iconButton(tools, '', 'export', '导出', @() view.Controller.exportResults(), 'small');
            uilabel(tools, 'Text', char(tabTitle), 'FontColor', [0.28 0.36 0.44]);
            ax = uiaxes(grid);
            ax.Layout.Row = 2;
            geodem.compat.setUiCallback(ax, 'ButtonDownFcn', @(~, ~) view.onMapAxesClick());
            ax.XGrid = 'on';
            ax.YGrid = 'on';
            ax.ZGrid = 'on';
            title(ax, char(tabTitle));
            xlabel(ax, 'X / m');
            ylabel(ax, 'Y / m');
            if kind == "scene"
                zlabel(ax, 'Z / m');
            end
            viewId = "custom_" + string(view.CustomTabCounter);
            tab.UserData = struct('Kind', kind, 'ViewId', viewId, 'Axes', ax, 'Custom', true);
            view.MainTabGroup.SelectedTab = tab;
            if ~isempty(view.Controller) && ~isempty(view.Controller.Project) && strlength(string(view.Controller.Project.activeLayer)) > 0
                view.renderLayer(view.Controller.Project, view.Controller.Project.activeLayer);
            end
        end

        function renameCurrentViewTab(view)
            tab = view.MainTabGroup.SelectedTab;
            answer = inputdlg({'标签页名称'}, '重命名标签页', 1, {tab.Title});
            if ~isempty(answer) && strlength(strtrim(string(answer{1}))) > 0
                tab.Title = char(strtrim(string(answer{1})));
            end
        end

        function closeCurrentViewTab(view)
            tab = view.MainTabGroup.SelectedTab;
            data = tab.UserData;
            if isstruct(data) && isfield(data, 'Custom') && data.Custom
                view.MainTabGroup.SelectedTab = view.MapTab;
                delete(tab);
            else
                view.StatusLabel.Text = '系统标签页保留';
            end
        end

        function onViewTabChanged(view)
            if isempty(view.Controller) || isempty(view.Controller.Project)
                return;
            end
            project = view.Controller.Project;
            project.activeViewId = view.currentViewId();
            state = project.getViewState(project.activeViewId);
            if strlength(state.ActiveTool) > 0
                project.mapToolState.activeTool = state.ActiveTool;
                view.ActiveToolLabel.Text = "地图工具：" + view.localizedMapToolName(state.ActiveTool);
            end
            layerName = state.ActiveLayer;
            if strlength(layerName) == 0
                layerName = project.activeLayer;
            end
            if strlength(string(layerName)) > 0
                view.Controller.renderLayer(layerName);
            else
                view.renderProject(project);
            end
        end

        function viewId = currentViewId(view)
            viewId = "map";
            if isempty(view.MainTabGroup) || ~isvalid(view.MainTabGroup) || isempty(view.MainTabGroup.SelectedTab)
                return;
            end
            data = view.MainTabGroup.SelectedTab.UserData;
            if isstruct(data) && isfield(data, 'ViewId')
                viewId = string(data.ViewId);
            end
        end

        function kind = currentViewKind(view)
            [~, kind] = view.activeRenderAxes();
        end

        function createMapTab(view)
            mapGrid = uigridlayout(view.MapTab, [2 1]);
            mapGrid.RowHeight = {38, '1x'};
            mapGrid.Padding = [4 4 4 4];
            tb = uigridlayout(mapGrid, [1 8]);
            tb.ColumnWidth = {38, 38, 38, 38, 38, 38, 38, '1x'};
            tb.Padding = [4 2 4 2];
            view.iconButton(tb, '', 'zoom', '缩放/识别视图', @() view.Controller.setActiveMapTool('identify'), 'small');
            view.iconButton(tb, '', 'pan', '平移视图（可使用坐标轴工具栏拖动）', @() view.Controller.setActiveMapTool('pan'), 'small');
            view.iconButton(tb, '', 'fullExtent', '缩放至图层', @() view.Controller.zoomToLayer(), 'small');
            view.iconButton(tb, '', 'identify', '点击查询 DEM/ΔZ', @() view.Controller.setActiveMapTool('identify'), 'small');
            view.iconButton(tb, '', 'measure', '点击两点或多点测距', @() view.Controller.setActiveMapTool('measure'), 'small');
            view.iconButton(tb, '', 'profile', '点击两点生成剖面', @() view.Controller.activateProfileAnalysis(), 'small');
            view.iconButton(tb, '', 'export', '导出全部成果', @() view.Controller.exportResults(), 'small');
            tip = uilabel(tb, 'Text', '地图工具：识别 / 测距 / 剖面', 'FontColor', [0.28 0.36 0.44]);
            tip.Layout.Column = 8;

            view.MapAxes = uiaxes(mapGrid);
            view.MapAxes.Layout.Row = 2;
            geodem.compat.setUiCallback(view.MapAxes, 'ButtonDownFcn', @(~, ~) view.onMapAxesClick());
            title(view.MapAxes, 'GeoDEM Pro 二维地图');
            xlabel(view.MapAxes, 'X / m');
            ylabel(view.MapAxes, 'Y / m');
            grid(view.MapAxes, 'on');
        end

        function createSceneTab(view)
            sceneGrid = uigridlayout(view.SceneTab, [2 1]);
            sceneGrid.RowHeight = {38, '1x'};
            sceneGrid.Padding = [4 4 4 4];
            tb = uigridlayout(sceneGrid, [1 5]);
            tb.ColumnWidth = {38, 38, 38, '1x', '1x'};
            view.iconButton(tb, '', 'surface3d', '三维透视图', @() view.Controller.set3DView('perspective'), 'small');
            view.iconButton(tb, '', 'map', '俯视图', @() view.Controller.set3DView('top'), 'small');
            view.iconButton(tb, '', 'fullExtent', '缩放至当前图层', @() view.Controller.zoomToLayer(), 'small');
            uilabel(tb, 'Text', '三维场景显示当前激活图层', 'FontColor', [0.28 0.36 0.44]);
            view.SceneAxes = uiaxes(sceneGrid);
            view.SceneAxes.Layout.Row = 2;
            title(view.SceneAxes, '三维场景');
            xlabel(view.SceneAxes, 'X / m');
            ylabel(view.SceneAxes, 'Y / m');
            zlabel(view.SceneAxes, 'Z / m');
            grid(view.SceneAxes, 'on');
        end

        function createCompareTab(view)
            outer = uigridlayout(view.CompareTab, [2 1]);
            outer.RowHeight = {36, '1x'};
            outer.Padding = [4 4 4 4];
            outer.RowSpacing = 4;
            tools = uigridlayout(outer, [1 7]);
            tools.ColumnWidth = {38, 38, 38, 38, 38, 38, '1x'};
            tools.Padding = [4 1 4 1];
            view.iconButton(tools, '', 'map', '单图模式', @() view.Controller.setViewMode('map'), 'small');
            view.iconButton(tools, '', 'compare', '四宫格对比模式', @() view.Controller.setViewMode('compare'), 'small');
            view.iconButton(tools, '', 'diff', '差分专题图', @() view.Controller.showActiveDeformation(), 'small');
            view.iconButton(tools, '', 'surface3d', '三维场景', @() view.Controller.setViewMode('scene'), 'small');
            view.iconButton(tools, '', 'chart', '统计图表', @() view.Controller.setViewMode('charts'), 'small');
            view.iconButton(tools, '', 'export', '导出成果', @() view.Controller.exportResults(), 'small');
            uilabel(tools, 'Text', '多图对比：基准 DEM / 监测 DEM / ΔZ / 等值线', 'FontColor', [0.28 0.36 0.44]);
            compareGrid = uigridlayout(outer, [2 2]);
            compareGrid.Layout.Row = 2;
            compareGrid.Padding = [4 4 4 4];
            compareGrid.RowSpacing = 8;
            compareGrid.ColumnSpacing = 8;
            view.CompareAxes = gobjects(2, 2);
            for r = 1:2
                for c = 1:2
                    view.CompareAxes(r, c) = uiaxes(compareGrid);
                    view.CompareAxes(r, c).Layout.Row = r;
                    view.CompareAxes(r, c).Layout.Column = c;
                end
            end
        end

        function createChartTab(view)
            chartGrid = uigridlayout(view.ChartTab, [1 2]);
            chartGrid.Padding = [8 8 8 8];
            chartGrid.ColumnSpacing = 10;
            view.HistogramAxes = uiaxes(chartGrid);
            view.ClassBarAxes = uiaxes(chartGrid);
            title(view.HistogramAxes, 'ΔZ 直方图');
            title(view.ClassBarAxes, '等级面积');
        end
    end
end
