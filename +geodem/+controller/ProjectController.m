classdef ProjectController < handle
    %PROJECTCONTROLLER Owns project lifecycle and data import UI actions.

    properties
        App
    end

    methods
        function obj = ProjectController(app)
            obj.App = app;
        end

        function newProject(obj)
            app = obj.App;
            app.Project = geodem.model.ProjectState(app.ProjectRoot);
            app.log('已新建工程。');
            app.updateView();
            if strlength(app.SelectedToolId) > 0
                app.selectTool(app.SelectedToolId);
            end
        end

        function openProject(obj)
            app = obj.App;
            [file, path] = uigetfile({'*.gdem;*.mat','GeoDEM Pro Project (*.gdem, *.mat)'; '*.gdem','GeoDEM Project (*.gdem)'; '*.mat','MATLAB Project (*.mat)'}, '打开工程', app.Project.outputDir);
            if isequal(file, 0)
                return;
            end
            app.runSafely(@() geodem.controller.actions.ProjectActions.open(app, fullfile(path, file)));
        end

        function saveProject(obj)
            app = obj.App;
            target = app.Project.projectPath;
            if strlength(string(target)) == 0
                target = obj.chooseProjectSavePath('保存工程');
                if strlength(target) == 0
                    return;
                end
            end
            app.runSafely(@() geodem.controller.actions.ProjectActions.save(app, target));
        end

        function saveProjectAs(obj)
            target = obj.chooseProjectSavePath('另存工程');
            if strlength(target) == 0
                return;
            end
            obj.App.runSafely(@() geodem.controller.actions.ProjectActions.save(obj.App, target));
        end

        function target = chooseProjectSavePath(obj, dialogTitle)
            app = obj.App;
            defaultName = 'GeoDEMPro_project.gdem';
            if strlength(string(app.Project.projectPath)) > 0
                [~, baseName] = fileparts(char(app.Project.projectPath));
                defaultName = [baseName '.gdem'];
            end
            [file, path] = uiputfile({'*.gdem','GeoDEM Project (*.gdem)'; '*.mat','MATLAB Project (*.mat)'}, ...
                dialogTitle, fullfile(app.Project.outputDir, defaultName));
            if isequal(file, 0)
                target = "";
                return;
            end
            target = geodem.controller.actions.ProjectActions.ensureFileExtension(fullfile(path, file), ".gdem");
        end

        function clearWorkspace(obj)
            app = obj.App;
            app.Project.clearAnalysis();
            app.Project.clouds = struct();
            app.Project.layers = geodem.model.ProjectState.emptyLayerTable();
            app.Project.layerDataRefs = struct();
            app.Project.layerStyles = struct();
            app.Project.activeLayer = "";
            app.log('已清空当前工作区分析数据。');
            app.updateView();
            if strlength(app.SelectedToolId) > 0
                app.selectTool(app.SelectedToolId);
            end
        end

        function importCloud(obj, periodKey)
            if nargin < 2
                periodKey = "pointcloud";
            end
            filterSpec = {'*.csv;*.txt;*.las;*.laz','Point Cloud (*.csv, *.txt, *.las, *.laz)'};
            obj.importCloudInternal(periodKey, filterSpec, '导入点云图层', fullfile(obj.App.ProjectRoot, 'testdata'));
        end

        function importLasCloud(obj, periodKey)
            if nargin < 2
                periodKey = "pointcloud";
            end
            filterSpec = {'*.las;*.laz','LAS/LAZ Point Cloud (*.las, *.laz)'};
            obj.importCloudInternal(periodKey, filterSpec, '导入 LAS/LAZ 点云图层', obj.App.ProjectRoot);
        end

        function importDem(obj)
            app = obj.App;
            [file, path] = uigetfile({'*.tif;*.tiff;*.csv;*.txt;*.mat','DEM Raster (*.tif, *.tiff, *.csv, *.txt, *.mat)'}, ...
                '导入 DEM 图层', app.ProjectRoot, 'MultiSelect', 'on');
            if isequal(file, 0)
                return;
            end
            if ischar(file) || isstring(file)
                files = {char(file)};
            else
                files = file;
            end
            app.runSafely(@() geodem.controller.actions.ProjectActions.importDemFiles(app, path, files));
        end

        function showCloudProperties(obj)
            app = obj.App;
            lines = strings(0, 1);
            names = fieldnames(app.Project.clouds);
            for i = 1:numel(names)
                c = app.Project.clouds.(names{i});
                lines(end + 1) = sprintf('%s：%d 点，X %.3f-%.3f，Y %.3f-%.3f，Z %.3f-%.3f，平均高程 %.3f', ...
                    c.period, c.bounds.PointCount, c.bounds.XMin, c.bounds.XMax, c.bounds.YMin, c.bounds.YMax, c.bounds.ZMin, c.bounds.ZMax, c.zStats.Mean); %#ok<AGROW>
            end
            if isempty(lines)
                lines = "尚未导入点云。";
            end
            app.View.setStats(lines);
        end

        function importCloudInternal(obj, periodKey, filterSpec, dialogTitle, initialDir) %#ok<INUSD>
            app = obj.App;
            [file, path] = uigetfile(filterSpec, dialogTitle, initialDir, 'MultiSelect', 'on');
            if isequal(file, 0)
                return;
            end
            if ischar(file) || isstring(file)
                files = {char(file)};
            else
                files = file;
            end
            app.runSafely(@() geodem.controller.actions.ProjectActions.importPointCloudFiles(app, path, files));
        end
    end
end
