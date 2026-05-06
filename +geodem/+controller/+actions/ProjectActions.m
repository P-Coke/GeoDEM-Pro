classdef ProjectActions
    %PROJECTACTIONS Project and data import operations for AppController.

    methods (Static)
        function open(controller, projectPath)
            controller.Project = geodem.service.io.loadProject(projectPath);
            controller.log(['已打开工程：' projectPath]);
            controller.updateView();
            if strlength(controller.SelectedToolId) > 0
                controller.selectTool(controller.SelectedToolId);
            end
        end

        function save(controller, projectPath)
            controller.View.updateProgress(0.25, "保存工程");
            controller.Project.outputDir = fileparts(char(projectPath));
            geodem.service.io.saveProject(controller.Project, projectPath);
            controller.View.updateProgress(0.85, "保存完成");
            controller.log(['已保存工程：' projectPath]);
            controller.updateView();
        end

        function importPointCloudFiles(controller, folderPath, files)
            n = numel(files);
            for i = 1:numel(files)
                base = 0.08 + 0.78 * (i - 1) / max(n, 1);
                span = 0.78 / max(n, 1);
                controller.View.updateProgress(base, "准备点云 " + string(i) + "/" + string(n));
                filePath = fullfile(folderPath, files{i});
                progressFcn = @(fraction, message) controller.View.updateProgress(base + span * double(fraction), string(message) + " " + string(i) + "/" + string(n));
                cloud = geodem.service.io.importPointCloud(filePath, files{i}, progressFcn);
                controller.View.updateProgress(base + span * 0.96, "加入图层 " + string(i) + "/" + string(n));
                layerName = controller.Project.addCloud(cloud, true);
                controller.log(sprintf('成功导入点云图层 "%s"，点数：%d。', layerName, size(cloud.points, 1)));
            end
            geodem.controller.actions.ProjectActions.refreshAfterImport(controller);
        end

        function importDemFiles(controller, folderPath, files)
            n = numel(files);
            for i = 1:numel(files)
                base = 0.08 + 0.78 * (i - 1) / max(n, 1);
                span = 0.78 / max(n, 1);
                controller.View.updateProgress(base, "准备 DEM " + string(i) + "/" + string(n));
                filePath = fullfile(folderPath, files{i});
                controller.View.updateProgress(base + span * 0.35, "读取 DEM " + string(i) + "/" + string(n));
                dem = geodem.service.io.importDemRaster(filePath, files{i});
                controller.View.updateProgress(base + span * 0.82, "加入图层 " + string(i) + "/" + string(n));
                layerName = controller.Project.addDem(dem, true);
                controller.Project.addLayerDataRef(layerName, "dem", geodem.model.ProjectState.layerKey(layerName), "import_dem", struct('filePath', filePath));
                controller.log(sprintf('成功导入 DEM 图层 "%s"，尺寸：%d x %d。', char(layerName), size(dem.Z, 1), size(dem.Z, 2)));
            end
            geodem.controller.actions.ProjectActions.refreshAfterImport(controller);
        end

        function refreshAfterImport(controller)
            controller.View.updateProgress(0.88, "刷新图层");
            controller.updateView();
            if strlength(controller.SelectedToolId) > 0
                controller.selectTool(controller.SelectedToolId);
            end
            if strlength(string(controller.Project.activeLayer)) > 0
                controller.View.updateProgress(0.94, "显示图层");
                geodem.controller.actions.ProjectActions.renderImportedLayer(controller);
            end
        end

        function renderImportedLayer(controller)
            layerName = controller.Project.activeLayer;
            try
                controller.renderLayer(layerName);
            catch ME
                if ~contains(string(ME.message), "uifigure")
                    rethrow(ME);
                end
                controller.log(['当前视图不支持导入后自动预览，已切换到二维地图重试：' ME.message]);
                try
                    controller.View.selectViewMode('map');
                    controller.renderLayer(layerName);
                catch fallbackError
                    controller.log(['二维地图预览也失败：' fallbackError.message]);
                end
            end
        end

        function filePath = ensureFileExtension(filePath, defaultExt)
            filePath = string(filePath);
            [folder, baseName, ext] = fileparts(char(filePath));
            if isempty(ext)
                filePath = string(fullfile(folder, [baseName char(defaultExt)]));
            end
        end
    end
end
